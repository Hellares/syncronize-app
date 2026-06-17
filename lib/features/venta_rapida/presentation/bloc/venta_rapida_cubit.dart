import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/realtime_sync_service.dart';
import '../../domain/combo_prorrateo.dart';
import '../../../../core/utils/resource.dart';
import '../../../cliente/data/cache/cliente_catalogo_service.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cliente_empresa/data/cache/cliente_empresa_catalogo_service.dart';
import '../../../cliente_empresa/domain/entities/cliente_empresa.dart';
import '../../../combo/domain/entities/combo.dart';
import '../../../combo/domain/repositories/combo_repository.dart';
import '../../../descuento/domain/entities/vip_precio.dart';
import '../../../descuento/domain/usecases/obtener_politicas_vigentes_cliente.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../producto/domain/entities/producto_stock.dart';
import '../../../producto/domain/repositories/producto_stock_repository.dart';
import '../../../producto/domain/services/precio_nivel_cache_service.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../../domain/entities/orden_cobrable.dart';
import '../../domain/repositories/venta_rapida_repository.dart';
import '../../domain/usecases/buscar_cliente_por_dni_usecase.dart';
import '../../domain/usecases/buscar_cliente_por_ruc_usecase.dart';
import '../../domain/usecases/cobrar_venta_rapida_usecase.dart';
import '../../domain/usecases/obtener_cliente_generico_usecase.dart';

part 'venta_rapida_state.dart';

/// Margen de un centavo: aceptamos que el monto recibido pueda quedar hasta
/// 1 ¢ por debajo del total y aún así cobrar (pasa cuando MIXTO acumula
/// errores de redondeo a 2 decimales en cada línea).
const double _kPenPaymentTolerance = 0.01;

@lazySingleton
class VentaRapidaCubit extends Cubit<VentaRapidaState> {
  final CobrarVentaRapidaUseCase _cobrarUseCase;
  final ObtenerClienteGenericoUseCase _obtenerClienteGenericoUseCase;
  final BuscarClientePorDniUseCase _buscarClientePorDniUseCase;
  final BuscarClientePorRucUseCase _buscarClientePorRucUseCase;
  final PrecioNivelCacheService _nivelCacheService;
  final ComboRepository _comboRepository;
  final ProductoStockRepository _stockRepository;
  final RealtimeSyncService _realtimeSync;
  final VentaRapidaRepository _repository;
  final ObtenerPoliticasVigentesCliente _obtenerPoliticasVigentesCliente;

  VentaRapidaCubit(
    this._cobrarUseCase,
    this._obtenerClienteGenericoUseCase,
    this._buscarClientePorDniUseCase,
    this._buscarClientePorRucUseCase,
    this._nivelCacheService,
    this._comboRepository,
    this._stockRepository,
    this._realtimeSync,
    this._repository,
    this._obtenerPoliticasVigentesCliente,
  ) : super(const VentaRapidaState()) {
    _suscribirRealtime();
  }

  // ── Precio especial VIP del cliente ──
  /// Resolver de precio VIP del cliente actual (null = sin VIP).
  VipResolver? _vipResolver;
  /// Clave del cliente para el que se cargó el VIP (evita recargas redundantes).
  String? _vipClienteKey;

  /// Detecta cambios de cliente (cualquier path) y recarga el precio VIP.
  @override
  void onChange(Change<VentaRapidaState> change) {
    super.onChange(change);
    final prev = change.currentState;
    final next = change.nextState;
    if (prev.clienteId != next.clienteId ||
        prev.clienteEmpresaId != next.clienteEmpresaId) {
      // Diferir a microtask: el caso "cliente → null" (limpiar DNI) reaplica
      // VIP de forma SÍNCRONA y emitiría de forma reentrante DENTRO de este
      // onChange, antes de que termine el emit externo — que luego pisaría ese
      // strip. El microtask garantiza que el reaplicado corra después.
      final cid = next.clienteId;
      final ceid = next.clienteEmpresaId;
      Future.microtask(() => _onClienteCambiado(cid, ceid));
    }
  }

  Future<void> _onClienteCambiado(
    String? clienteId,
    String? clienteEmpresaId,
  ) async {
    if (isClosed) return;
    final key = clienteId ?? clienteEmpresaId;
    if (key == _vipClienteKey) return;
    _vipClienteKey = key;

    if (clienteId == null && clienteEmpresaId == null) {
      _vipResolver = null;
      _reaplicarVipItems();
      return;
    }

    final result = await _obtenerPoliticasVigentesCliente(
      clienteId: clienteId,
      clienteEmpresaId: clienteEmpresaId,
    );
    if (isClosed) return;
    // El cliente pudo cambiar mientras esperábamos la respuesta.
    if ((clienteId ?? clienteEmpresaId) != _vipClienteKey) return;

    _vipResolver = result is Success<List<Map<String, dynamic>>>
        ? VipResolver.fromVigentes(result.data)
        : null;
    _reaplicarVipItems();
  }

  /// Re-resuelve y reaplica el precio VIP a todas las líneas del carrito.
  /// Combos, componentes de combo y órdenes de servicio quedan exentos
  /// (paridad con el backend).
  void _reaplicarVipItems() {
    if (state.items.isEmpty) return;
    var cambio = false;
    final nuevos = state.items.map((item) {
      final exento = item.origenComboId != null ||
          item.comboId != null ||
          item.esOrdenServicio ||
          item.servicioId != null;
      final intents = exento ? const <VipPrecioIntent>[] : _vipParaNuevoProducto(item.productoId);
      // Sin cambios si las intenciones son iguales a las que ya tenía.
      if (listEquals(intents, item.vipIntents)) return item;
      cambio = true;
      return item
          .copyWith(vipIntents: intents)
          .recalcularPrecioPorNiveles(item.cantidad);
    }).toList();
    if (cambio) emit(state.copyWith(items: nuevos));
  }

  /// Intenciones VIP para un producto (todas las políticas aplicables del
  /// cliente; vacío si no aplica ninguna).
  List<VipPrecioIntent> _vipParaNuevoProducto(String? productoId) =>
      _vipResolver?.intentsParaProducto(productoId) ?? const [];

  /// Token monotónico de búsqueda de cliente. Se usa para descartar
  /// respuestas obsoletas: si el cajero busca DNI A, lo cancela y busca DNI B,
  /// la respuesta tardía de A no debe sobreescribir el resultado de B.
  int _searchSeq = 0;

  // ── Contexto ──

  void setContexto({
    required String empresaId,
    required String sedeId,
    required String vendedorId,
    double impuestoPorcentaje = 18.0,
    String moneda = 'PEN',
  }) {
    emit(state.copyWith(
      empresaId: empresaId,
      sedeId: sedeId,
      vendedorId: vendedorId,
      impuestoPorcentaje: impuestoPorcentaje,
      moneda: moneda,
    ));
  }

  // ── Carrito ──

  /// Agrega una orden de servicio al carrito para cobrarla como línea de
  /// venta: cantidad fija 1, precio = saldo pendiente (el backend valida el
  /// saldo vigente al cobrar y marca la orden ENTREGADO).
  ///
  /// Además pre-carga el cliente de la orden en la venta (persona → DNI,
  /// empresa → RUC). Restricción: todas las órdenes del carrito deben ser
  /// del mismo cliente.
  ///
  /// Devuelve true si se agregó (false → ver `state.error`).
  bool agregarOrdenServicio(OrdenCobrable orden) {
    if (state.items.any((i) => i.ordenServicioId == orden.id)) {
      emit(state.copyWith(
        error: 'La orden ${orden.codigo} ya está en el carrito',
      ));
      return false;
    }
    // saldo == 0 (100% adelantada) SÍ se puede cobrar: no se paga nada hoy
    // pero la boleta se emite por el total. Solo se bloquea el saldo
    // negativo (adelanto+descuento > costo = datos inconsistentes).
    if (orden.saldoPendiente < 0) {
      emit(state.copyWith(
        error:
            'La orden ${orden.codigo} tiene montos inconsistentes (adelanto + descuento superan el costo). Corrígela antes de cobrar',
      ));
      return false;
    }
    if (orden.costoTotal - orden.descuento <= 0) {
      emit(state.copyWith(
        error: 'La orden ${orden.codigo} no tiene costo definido',
      ));
      return false;
    }

    // Todas las órdenes del carrito deben ser del mismo cliente (la venta
    // tiene UN cliente y el comprobante sale a su nombre).
    final otraOrden =
        state.items.where((i) => i.esOrdenServicio).isNotEmpty;
    if (otraOrden) {
      final mismoCliente = orden.cliente?.clienteId == state.clienteId &&
          orden.clienteEmpresa?.clienteEmpresaId == state.clienteEmpresaId;
      if (!mismoCliente) {
        emit(state.copyWith(
          error:
              'La orden ${orden.codigo} es de otro cliente. Cobrala en una venta aparte',
        ));
        return false;
      }
    }

    final equipo = orden.equipoDescripcion;
    final detalle = orden.servicioNombre ?? orden.tipoServicio;
    // Precio de línea = COSTO NETO del servicio (costo − descuento, SIN
    // restar adelanto): el comprobante sale por el TOTAL del servicio y
    // el adelanto se aplica como pago (HOY solo se cobra el saldo).
    final costoNeto =
        ((orden.costoTotal - orden.descuento) * 100).roundToDouble() / 100;
    final item = VentaDetalleInput(
      ordenServicioId: orden.id,
      ordenCodigo: orden.codigo,
      ordenAdelanto: orden.adelanto,
      // Separador ASCII: el guión largo "—" no existe en los code pages de
      // las impresoras térmicas (CP437/CP850) y rompe la impresión.
      descripcion: '${orden.codigo} - ${equipo.isNotEmpty ? equipo : detalle}',
      cantidad: 1,
      // El costo de la orden es precio final al cliente → IGV incluido.
      // El backend exige que coincida con el costo neto vigente.
      precioUnitario: costoNeto,
      precioIncluyeIgv: true,
      porcentajeIGV: state.impuestoPorcentaje,
      tipoAfectacion: '10',
    );

    // Pre-carga del cliente de la orden. La orden manda: el comprobante
    // debe salir a nombre de quien dejó el equipo.
    var nuevo = state.copyWith(
      items: [...state.items, item],
      clearError: true,
    );
    if (orden.clienteEmpresa != null) {
      nuevo = nuevo.copyWith(
        clienteGenerico: false,
        clienteId: null,
        clienteEmpresaId: orden.clienteEmpresa!.clienteEmpresaId,
        tipoDocCliente: 'RUC',
        numeroDocCliente: orden.clienteEmpresa!.ruc ?? '',
        nombreClienteResuelto: orden.clienteEmpresa!.razonSocial,
      );
    } else if (orden.cliente != null) {
      nuevo = nuevo.copyWith(
        clienteGenerico: false,
        clienteId: orden.cliente!.clienteId,
        clienteEmpresaId: null,
        tipoDocCliente: 'DNI',
        numeroDocCliente: orden.cliente!.numeroDocumento ?? '',
        nombreClienteResuelto: orden.cliente!.nombre,
      );
    }
    emit(nuevo);
    return true;
  }

  void agregarProducto(ProductoListItem producto) {
    // Combos se manejan por separado: se expande la lista de componentes
    // como items individuales con `productoId` (no `comboId`). El backend
    // procesa cada componente como una venta normal — sin lógica especial
    // de combo. El descuento del combo se prorratea entre los componentes.
    if (producto.esCombo) {
      _agregarCombo(producto);
      return;
    }

    final sedeId = state.sedeId ?? '';
    final precio = producto.precioEfectivoEnSede(sedeId) ??
        producto.precioEnSede(sedeId) ??
        0.0;
    final igvPorc = producto.impuestoPorcentaje ?? state.impuestoPorcentaje;
    final tipoAfect = _mapTipoAfectacion(producto.tipoAfectacionIgv);
    final icbperUnit = producto.aplicaIcbper ? 0.20 : 0.0;
    final stockDisp = producto.stockEnSede(sedeId);

    // Si ya está en el carrito, sumar 1 y recalcular precio según niveles.
    // (Solo busca items que NO vengan de combo; los del combo se manipulan en grupo).
    final idx = state.items.indexWhere(
      (i) => i.productoId == producto.id && i.origenComboId == null,
    );
    if (idx >= 0) {
      final actual = state.items[idx];
      final nuevaCantidad = actual.cantidad + 1;
      final icbperPerUnit =
          actual.cantidad > 0 ? actual.icbper / actual.cantidad : icbperUnit;
      final nueva = actual
          .recalcularPrecioPorNiveles(nuevaCantidad)
          .copyWith(icbper: icbperPerUnit * nuevaCantidad);
      final lista = [...state.items];
      lista[idx] = nueva;
      emit(state.copyWith(items: lista, clearError: true));
      return;
    }

    // Item nuevo: precio base inicialmente; los niveles se cargan async.
    final nivelesEnCache = _nivelCacheService.peek(producto.id);
    final item = VentaDetalleInput(
      productoId: producto.id,
      descripcion: producto.nombre,
      cantidad: 1,
      precioUnitario: precio,
      precioBase: precio,
      porcentajeIGV: igvPorc,
      precioIncluyeIgv: producto.precioIncluyeIgvEnSede(sedeId),
      tipoAfectacion: tipoAfect,
      icbper: icbperUnit,
      stockDisponible: stockDisp,
      niveles: nivelesEnCache ?? const [],
      // Snapshot de costo + estado liquidación para preview de margen y
      // guard de venta bajo costo en el cobro.
      precioCostoSnapshot: producto.precioCostoEnSede(sedeId),
      enLiquidacion: producto.enLiquidacionEnSede(sedeId),
      // Precio especial VIP si el cliente actual lo tiene.
      vipIntents: _vipParaNuevoProducto(producto.id),
    );
    final itemConNivel = nivelesEnCache != null
        ? item.recalcularPrecioPorNiveles(1)
        : item;
    emit(state.copyWith(items: [...state.items, itemConNivel], clearError: true));

    // Si todavía no tenemos los niveles cacheados, los pedimos al backend.
    if (nivelesEnCache == null) {
      _cargarNivelesYActualizar(producto.id);
    }
  }

  void agregarVariante(ProductoListItem producto, ProductoVariante variante) {
    final sedeId = state.sedeId ?? '';
    final precio = variante.precioEfectivoEnSede(sedeId) ??
        variante.precioEnSede(sedeId) ??
        producto.precioEfectivoEnSede(sedeId) ??
        0.0;
    final igvPorc = producto.impuestoPorcentaje ?? state.impuestoPorcentaje;
    final tipoAfect = _mapTipoAfectacion(producto.tipoAfectacionIgv);
    final icbperUnit = producto.aplicaIcbper ? 0.20 : 0.0;
    final stockDisp = variante.stockEnSede(sedeId);

    final idx = state.items.indexWhere(
      (i) =>
          i.productoId == producto.id &&
          i.varianteId == variante.id &&
          i.origenComboId == null,
    );
    if (idx >= 0) {
      final actual = state.items[idx];
      final nuevaCantidad = actual.cantidad + 1;
      final icbperPerUnit =
          actual.cantidad > 0 ? actual.icbper / actual.cantidad : icbperUnit;
      final nueva = actual
          .recalcularPrecioPorNiveles(nuevaCantidad)
          .copyWith(icbper: icbperPerUnit * nuevaCantidad);
      final lista = [...state.items];
      lista[idx] = nueva;
      emit(state.copyWith(items: lista, clearError: true));
      return;
    }

    final descripcion = '${producto.nombre} - ${variante.nombre}';
    final nivelesEnCache = _nivelCacheService.peekVariante(variante.id);
    final item = VentaDetalleInput(
      productoId: producto.id,
      varianteId: variante.id,
      descripcion: descripcion,
      cantidad: 1,
      precioUnitario: precio,
      precioBase: precio,
      porcentajeIGV: igvPorc,
      precioIncluyeIgv:
          variante.precioIncluyeIgvEnSede(sedeId),
      tipoAfectacion: tipoAfect,
      icbper: icbperUnit,
      stockDisponible: stockDisp,
      niveles: nivelesEnCache ?? const [],
      precioCostoSnapshot: variante.precioCostoEnSede(sedeId),
      enLiquidacion: variante.enLiquidacionEnSede(sedeId),
      vipIntents: _vipParaNuevoProducto(producto.id),
    );
    final itemConNivel = nivelesEnCache != null
        ? item.recalcularPrecioPorNiveles(1)
        : item;
    emit(state.copyWith(items: [...state.items, itemConNivel], clearError: true));

    if (nivelesEnCache == null) {
      _cargarNivelesVarianteYActualizar(variante.id);
    }
  }

  Future<void> _cargarNivelesVarianteYActualizar(String varianteId) async {
    final niveles = await _nivelCacheService.getNivelesVariante(varianteId);
    if (isClosed) return;
    final items = state.items;
    final idx = items.indexWhere(
      (i) => i.varianteId == varianteId && i.origenComboId == null,
    );
    if (idx < 0) return;
    final actualizado = items[idx]
        .copyWith(niveles: niveles)
        .recalcularPrecioPorNiveles(items[idx].cantidad);
    final lista = [...items];
    lista[idx] = actualizado;
    emit(state.copyWith(items: lista));
  }

  /// Expande un combo en N items de productos individuales con precio
  /// prorrateado. El backend ve items normales (con `productoId`) y
  /// descuenta stock de cada uno por separado — sin saber que vienen de
  /// un combo. El cliente conserva `origenComboId` para agrupar visualmente
  /// y para futura edición/eliminación en grupo.
  ///
  /// **Prorrateo**: cada componente recibe parte del precio efectivo del
  /// combo proporcional a su precio regular. El último componente compensa
  /// el redondeo de centavos para que la suma sea exacta.
  ///
  /// **Guard de oferta**: si algún componente tiene `ofertaActiva`, el combo
  /// se deja como `comboPendienteOferta` en el state y la UI debe mostrar
  /// un dialog. La expansión ocurre solo cuando el cajero confirma con
  /// `confirmarComboPendiente()`. La razón es que el combo ignora ofertas
  /// individuales — el cajero debe decidir si conviene venderlo o no.
  Future<void> _agregarCombo(ProductoListItem producto) async {
    final sedeId = state.sedeId;
    final empresaId = state.empresaId;
    if (sedeId == null || empresaId == null) {
      emit(state.copyWith(error: 'Falta contexto de sede/empresa'));
      return;
    }

    final result = await _comboRepository.getComboCompleto(
      comboId: producto.id,
      empresaId: empresaId,
      sedeId: sedeId,
    );
    if (isClosed) return;

    if (result is! Success<Combo>) {
      final msg = result is Error<Combo>
          ? result.message
          : 'No se pudo cargar el combo';
      emit(state.copyWith(error: msg));
      return;
    }

    final combo = result.data;
    if (combo.componentes.isEmpty) {
      emit(state.copyWith(error: 'El combo no tiene componentes'));
      return;
    }

    // Si hay componentes en oferta activa, pedir confirmación antes de expandir.
    final hayOfertaActiva = combo.componentes
        .any((c) => c.componenteInfo?.ofertaActiva ?? false);
    if (hayOfertaActiva) {
      emit(state.copyWith(comboPendienteOferta: combo, clearError: true));
      return;
    }

    _expandirYAgregarCombo(combo);
  }

  /// Confirmación del cajero al dialog: procede a expandir el combo en items
  /// individuales aunque tenga componentes en oferta.
  void confirmarComboPendiente() {
    final combo = state.comboPendienteOferta;
    if (combo == null) return;
    emit(state.copyWith(clearComboPendienteOferta: true));
    _expandirYAgregarCombo(combo);
  }

  /// Cancelación del cajero al dialog: descarta el combo, no se agrega nada.
  void cancelarComboPendiente() {
    emit(state.copyWith(clearComboPendienteOferta: true));
  }

  /// Lógica pura de expansión. Se llama desde `_agregarCombo` (sin oferta)
  /// o desde `confirmarComboPendiente` (con oferta confirmada).
  ///
  /// **Estrategia de precio**: cada componente se manda al backend con su
  /// `precioUnitario` REAL (precio regular del componente) y un `descuento`
  /// prorrateado del descuento total del combo. Razones:
  /// 1. Transparencia: el cajero/cliente ve el precio real de cada producto
  ///    y cuánto se ahorra con el combo.
  /// 2. Trazabilidad: el campo `descuento` del VentaDetalle persiste,
  ///    permitiendo reportes "¿cuánto descuento aplicamos vía combos?".
  /// 3. Coherencia: la BD guarda precios reales — los reportes "cuánto se
  ///    vendió de X producto" reflejan el precio normal, no el prorrateado.
  ///
  /// El último componente compensa centavos de redondeo para que la suma
  /// `Σ (precioUnitario·cantidad − descuento)` sea exactamente `precioFinal`.
  void _expandirYAgregarCombo(Combo combo) {
    final igvPorc = state.impuestoPorcentaje;
    final nuevos = combo.componentes.map((c) {
      // Precio EFECTIVO del backend (base/oferta/liquidación, sin niveles),
      // así coincide con lo que el backend valida al cobrar (no 409).
      final precioEfectivo =
          c.componenteInfo?.precioVenta ?? c.precioUnitarioRegular;
      // Base real (sin oferta/liquidación) para tachar en la UI cuando el
      // efectivo es menor (liquidación/oferta).
      final precioBaseReal = c.precioUnitarioRegular;
      final enLiq = c.componenteInfo?.enLiquidacion ?? false;
      return VentaDetalleInput(
        productoId: c.componenteProductoId,
        varianteId: c.componenteVarianteId,
        descripcion: c.nombre,
        cantidad: c.cantidad.toDouble(),
        precioUnitario: precioEfectivo,
        descuento: 0,
        descuentoManual: 0,
        precioBase: precioBaseReal,
        porcentajeIGV: igvPorc,
        precioIncluyeIgv: true,
        tipoAfectacion: '10',
        icbper: 0,
        stockDisponible: c.stockDisponible,
        origenComboId: combo.id,
        origenComboNombre: combo.nombre,
        // Liquidación gana sola: no se le apila el descuento del combo.
        enLiquidacion: enLiq,
        // Contexto de pricing para re-precio al editar componentes.
        comboTipoPrecio: combo.tipoPrecioCombo.name,
        comboDescuentoPct: combo.descuentoPorcentaje,
        comboPrecioObjetivo: combo.precioFinal,
        comboModificado: false,
      );
    }).toList();

    emit(state.copyWith(
      items: [...state.items, ...nuevos],
      clearError: true,
    ));
    // Prorratea el descuento del combo entre las líneas según su regla.
    _recalcularCombo(combo.id);
  }

  /// Re-prorratea el descuento del combo entre sus líneas según la regla de
  /// pricing, preservando y apilando el descuento manual de cada línea.
  ///
  /// Objetivo de precio del combo:
  /// - `calculado`: suma de componentes (sin descuento).
  /// - `calculadoConDescuento`: suma × (1 − %).
  /// - `fijo`: [objetivoFijoOverride] si viene (al editar un componente se
  ///   ajusta por la diferencia de precio), si no el `comboPrecioObjetivo`
  ///   guardado.
  ///
  /// `descuento` de cada línea queda en `prorrateoCombo + descuentoManual`.
  /// El último componente compensa el redondeo para que la suma cuadre.
  void _recalcularCombo(
    String origenComboId, {
    double? objetivoFijoOverride,
    bool? marcarModificado,
  }) {
    final lineas =
        state.items.where((i) => i.origenComboId == origenComboId).toList();
    if (lineas.isEmpty) return;

    final tipo = lineas.first.comboTipoPrecio;
    final pct = lineas.first.comboDescuentoPct ?? 0;
    final modificado = marcarModificado ?? lineas.first.comboModificado;

    // Objetivo de precio del combo (solo relevante para FIJO; los demás los
    // deriva el helper desde las líneas). Se guarda en cada línea.
    final regularTotal =
        lineas.fold<double>(0, (s, l) => s + l.precioUnitario * l.cantidad);
    final objetivoFijo = tipo == 'fijo'
        ? (objetivoFijoOverride ?? lineas.first.comboPrecioObjetivo ?? regularTotal)
        : null;

    // Prorrateo puro (excluye liquidación, reparte solo en las no-liq).
    final descuentosCombo = prorratearDescuentoCombo(
      lineas: lineas
          .map((l) => (
                regular: l.precioUnitario * l.cantidad,
                enLiquidacion: l.enLiquidacion,
              ))
          .toList(),
      tipo: tipo ?? 'calculado',
      descuentoPct: pct,
      objetivoFijo: objetivoFijo,
    );

    final recomputadas = <VentaDetalleInput>[];
    for (var i = 0; i < lineas.length; i++) {
      final l = lineas[i];
      recomputadas.add(l.copyWith(
        descuento: descuentosCombo[i] + l.descuentoManual,
        comboPrecioObjetivo: objetivoFijo ?? l.comboPrecioObjetivo,
        comboModificado: modificado,
      ));
    }

    var idx = 0;
    final items = state.items.map((it) {
      if (it.origenComboId == origenComboId) {
        return recomputadas[idx++];
      }
      return it;
    }).toList();
    emit(state.copyWith(items: items, clearError: true));
  }

  /// Quita el componente en [index] (debe ser línea de combo) y re-precia
  /// el grupo. En FIJO baja el objetivo por el precio del componente
  /// quitado (la diferencia se descuenta del total). Marca "Modificado".
  void quitarComponenteCombo(int index) {
    if (index < 0 || index >= state.items.length) return;
    final linea = state.items[index];
    final comboId = linea.origenComboId;
    if (comboId == null) return;

    final esFijo = linea.comboTipoPrecio == 'fijo';
    final nuevoObjetivoFijo = esFijo
        ? ((linea.comboPrecioObjetivo ?? 0) -
            linea.precioUnitario * linea.cantidad)
        : null;

    final lista = [...state.items]..removeAt(index);
    emit(state.copyWith(items: lista, clearError: true));

    if (lista.any((i) => i.origenComboId == comboId)) {
      _recalcularCombo(comboId,
          objetivoFijoOverride: nuevoObjetivoFijo, marcarModificado: true);
    }
  }

  /// Agrega un producto/variante como componente nuevo de un combo
  /// existente (ej. sumar un accesorio al kit). En FIJO sube el objetivo
  /// por el precio del nuevo componente. Marca "Modificado".
  void agregarComponenteACombo(
    String origenComboId,
    ProductoListItem producto, {
    ProductoVariante? variante,
    int cantidad = 1,
  }) {
    final grupo =
        state.items.where((i) => i.origenComboId == origenComboId).toList();
    if (grupo.isEmpty) return;
    final ctx = grupo.first;
    final nueva = _construirLineaComponente(
      origenComboId: origenComboId,
      ctx: ctx,
      producto: producto,
      variante: variante,
      cantidad: cantidad.toDouble(),
    );

    final lista = [...state.items];
    final ultimoIdx =
        lista.lastIndexWhere((i) => i.origenComboId == origenComboId);
    lista.insert(ultimoIdx + 1, nueva);
    emit(state.copyWith(items: lista, clearError: true));

    final esFijo = ctx.comboTipoPrecio == 'fijo';
    final nuevoObjetivoFijo = esFijo
        ? ((ctx.comboPrecioObjetivo ?? 0) +
            nueva.precioUnitario * nueva.cantidad)
        : null;
    _recalcularCombo(origenComboId,
        objetivoFijoOverride: nuevoObjetivoFijo, marcarModificado: true);
  }

  /// Sustituye el componente en [index] por otro producto/variante (ej.
  /// upgrade de un componente del kit), conservando la cantidad. En FIJO
  /// ajusta el objetivo por la diferencia de precio. Marca "Modificado".
  void sustituirComponenteCombo(
    int index,
    ProductoListItem producto, {
    ProductoVariante? variante,
  }) {
    if (index < 0 || index >= state.items.length) return;
    final vieja = state.items[index];
    final comboId = vieja.origenComboId;
    if (comboId == null) return;

    final nueva = _construirLineaComponente(
      origenComboId: comboId,
      ctx: vieja,
      producto: producto,
      variante: variante,
      cantidad: vieja.cantidad,
    );

    final lista = [...state.items];
    lista[index] = nueva;
    emit(state.copyWith(items: lista, clearError: true));

    final esFijo = vieja.comboTipoPrecio == 'fijo';
    final delta = nueva.precioUnitario * nueva.cantidad -
        vieja.precioUnitario * vieja.cantidad;
    final nuevoObjetivoFijo =
        esFijo ? ((vieja.comboPrecioObjetivo ?? 0) + delta) : null;
    _recalcularCombo(comboId,
        objetivoFijoOverride: nuevoObjetivoFijo, marcarModificado: true);
  }

  /// Construye una línea-componente de combo a partir de un producto/
  /// variante del catálogo, precio efectivo de sede (base/oferta/liq) y el
  /// contexto de pricing del combo [ctx]. El descuento del combo lo
  /// recalcula `_recalcularCombo` después.
  VentaDetalleInput _construirLineaComponente({
    required String origenComboId,
    required VentaDetalleInput ctx,
    required ProductoListItem producto,
    ProductoVariante? variante,
    required double cantidad,
  }) {
    final sedeId = state.sedeId ?? '';
    final precio = variante?.precioEfectivoEnSede(sedeId) ??
        variante?.precioEnSede(sedeId) ??
        producto.precioEfectivoEnSede(sedeId) ??
        producto.precioEnSede(sedeId) ??
        0.0;
    // Base real (sin oferta/liquidación) para tachar en la UI.
    final precioBaseReal = variante?.precioEnSede(sedeId) ??
        producto.precioEnSede(sedeId) ??
        precio;
    final igvPorc = producto.impuestoPorcentaje ?? state.impuestoPorcentaje;
    return VentaDetalleInput(
      productoId: producto.id,
      varianteId: variante?.id,
      descripcion: variante != null
          ? '${producto.nombre} - ${variante.nombre}'
          : producto.nombre,
      cantidad: cantidad,
      precioUnitario: precio,
      precioBase: precioBaseReal,
      descuento: 0,
      descuentoManual: 0,
      porcentajeIGV: igvPorc,
      precioIncluyeIgv: producto.precioIncluyeIgvEnSede(sedeId),
      tipoAfectacion: _mapTipoAfectacion(producto.tipoAfectacionIgv),
      icbper: producto.aplicaIcbper ? 0.20 : 0.0,
      stockDisponible:
          variante?.stockEnSede(sedeId) ?? producto.stockEnSede(sedeId),
      origenComboId: origenComboId,
      origenComboNombre: ctx.origenComboNombre,
      comboTipoPrecio: ctx.comboTipoPrecio,
      comboDescuentoPct: ctx.comboDescuentoPct,
      comboPrecioObjetivo: ctx.comboPrecioObjetivo,
      comboModificado: true,
      precioCostoSnapshot: producto.precioCostoEnSede(sedeId),
      enLiquidacion: variante?.enLiquidacionEnSede(sedeId) ??
          producto.enLiquidacionEnSede(sedeId),
    );
  }

  /// Devuelve los niveles de precio del producto. Delegada al
  /// `PrecioNivelCacheService` compartido con el resto de la app.
  Future<List<PrecioNivel>> getNivelesProducto(String productoId) =>
      _nivelCacheService.getNiveles(productoId);

  /// Carga niveles del producto desde backend (vía cache compartido) y
  /// actualiza el item del carrito recalculando precio. Si la respuesta
  /// llega después de cambios al carrito, busca por productoId (no por
  /// índice) para no afectar items movidos.
  Future<void> _cargarNivelesYActualizar(String productoId) async {
    final niveles = await _nivelCacheService.getNiveles(productoId);
    if (isClosed) return;

    // Reaplicar a TODOS los items del carrito que coincidan con este productoId
    // (puede haber sido recreado / sumado / decrementado mientras esperábamos).
    final items = state.items;
    final idx = items.indexWhere(
      (i) => i.productoId == productoId && i.varianteId == null,
    );
    if (idx < 0) return;
    final actualizado = items[idx]
        .copyWith(niveles: niveles)
        .recalcularPrecioPorNiveles(items[idx].cantidad);
    final lista = [...items];
    lista[idx] = actualizado;
    emit(state.copyWith(items: lista));
  }

  String _mapTipoAfectacion(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'EXONERADO':
        return '20';
      case 'INAFECTO':
        return '30';
      case 'GRAVADO':
      default:
        return '10';
    }
  }

  void actualizarCantidad(int index, double cantidad) {
    if (index < 0 || index >= state.items.length) return;
    // Si el usuario está editando y borra el valor (queda 0/vacío), NO eliminamos
    // el item — solo ignoramos hasta que escriba un número válido.
    if (cantidad <= 0) return;
    final actual = state.items[index];
    // Líneas de orden de servicio: cantidad fija 1 (cobran el saldo de UNA
    // orden — no tiene sentido "2 saldos").
    if (actual.esOrdenServicio) return;
    // Cap al stock disponible para no permitir vender más de lo que hay
    // (el backend lo rechazaría al cobrar; mejor frenar acá).
    final double stockMax = actual.stockDisponible?.toDouble() ?? double.infinity;
    final double cantidadFinal = cantidad > stockMax ? stockMax : cantidad;
    // ICBPER es per-unit: lo derivamos del valor previo y reescalamos a la
    // nueva cantidad (consistente con `decrementarProducto`).
    final icbperPerUnit =
        actual.cantidad > 0 ? actual.icbper / actual.cantidad : 0.0;

    // Línea de combo: cambia la cantidad del componente y re-precia el
    // grupo. No aplica niveles — el combo usa precio regular + prorrateo.
    // En FIJO ajusta el objetivo por la diferencia de cantidad.
    if (actual.origenComboId != null) {
      final cantidadAnterior = actual.cantidad;
      final lista = [...state.items];
      lista[index] = actual.copyWith(
        cantidad: cantidadFinal,
        icbper: icbperPerUnit * cantidadFinal,
      );
      emit(state.copyWith(items: lista, clearError: true));
      final esFijo = actual.comboTipoPrecio == 'fijo';
      final nuevoObjetivoFijo = esFijo
          ? ((actual.comboPrecioObjetivo ?? 0) +
              actual.precioUnitario * (cantidadFinal - cantidadAnterior))
          : null;
      _recalcularCombo(actual.origenComboId!,
          objetivoFijoOverride: nuevoObjetivoFijo, marcarModificado: true);
      return;
    }

    final nueva = actual
        .recalcularPrecioPorNiveles(cantidadFinal)
        .copyWith(icbper: icbperPerUnit * cantidadFinal);
    final lista = [...state.items];
    lista[index] = nueva;
    emit(state.copyWith(items: lista, clearError: true));
  }

  /// Setea el descuento MANUAL de una línea (por ítem / global) preservando
  /// el prorrateo del combo, y lo apila: `descuento = prorrateoCombo +
  /// manual`. En líneas sueltas el prorrateo es 0, así que `descuento ==
  /// manual` (comportamiento de siempre). El manual se capea para que el
  /// total de descuento no supere el bruto de la línea.
  VentaDetalleInput _conDescuentoManual(VentaDetalleInput l, double manual) {
    final bruto = l.cantidad * l.precioUnitario;
    final prorrateoCombo =
        (l.descuento - l.descuentoManual).clamp(0, double.infinity).toDouble();
    final topeManual = (bruto - prorrateoCombo).clamp(0, double.infinity).toDouble();
    final manualFinal = manual.clamp(0, topeManual).toDouble();
    return l.copyWith(
      descuentoManual: manualFinal,
      descuento: prorrateoCombo + manualFinal,
    );
  }

  void actualizarDescuento(int index, double porcentaje) {
    if (index < 0 || index >= state.items.length) return;
    final actual = state.items[index];
    // Líneas de orden: el descuento comercial vive en la orden de servicio
    // (el backend rechaza descuento de línea sobre ordenServicioId).
    if (actual.esOrdenServicio) {
      emit(state.copyWith(
        error: 'El descuento de una orden de servicio se aplica en la orden, no en la venta',
      ));
      return;
    }
    final monto = (actual.cantidad * actual.precioUnitario) * (porcentaje / 100);
    final lista = [...state.items];
    lista[index] = _conDescuentoManual(actual, monto);
    emit(state.copyWith(items: lista, clearError: true));
  }

  void actualizarDescuentoMonto(int index, double monto) {
    if (index < 0 || index >= state.items.length) return;
    if (state.items[index].esOrdenServicio) {
      emit(state.copyWith(
        error: 'El descuento de una orden de servicio se aplica en la orden, no en la venta',
      ));
      return;
    }
    final lista = [...state.items];
    lista[index] = _conDescuentoManual(state.items[index], monto);
    emit(state.copyWith(items: lista, clearError: true));
  }

  /// Aplica un descuento global por porcentaje a TODAS las líneas, incluidas
  /// las de combo (se apila sobre el ahorro prorrateado del combo).
  void aplicarDescuentoGlobal(double porcentaje) {
    if (porcentaje <= 0 || porcentaje > 100) return;
    final lista = state.items.map((item) {
      // Las líneas de orden de servicio se eximen del descuento global
      // (su precio ES el saldo de la orden — el backend lo valida exacto).
      if (item.esOrdenServicio) return item;
      final manual = (item.cantidad * item.precioUnitario) * (porcentaje / 100);
      return _conDescuentoManual(item, manual);
    }).toList();
    emit(state.copyWith(items: lista, clearError: true));
  }

  /// Limpia los descuentos MANUALES (por ítem y global). El ahorro
  /// intrínseco del combo (prorrateo) se conserva.
  void limpiarDescuentos() {
    final lista = state.items.map((item) {
      if (item.descuentoManual == 0) return item;
      return _conDescuentoManual(item, 0);
    }).toList();
    emit(state.copyWith(items: lista, clearError: true));
  }

  void eliminarItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final lista = [...state.items]..removeAt(index);
    emit(state.copyWith(items: lista, clearError: true));
  }

  /// Decrementa en 1 la cantidad del producto suelto en el carrito.
  /// Si la cantidad llega a 0, elimina el item completo.
  /// Si el producto no está (o solo está como parte de un combo), no hace nada.
  ///
  /// Items de combo (con `origenComboId != null`) no se decrementan acá —
  /// se manipulan en grupo desde la UI del carrito.
  void decrementarProducto(String productoId) {
    final idx = state.items.indexWhere(
      (i) =>
          i.productoId == productoId &&
          i.varianteId == null &&
          i.origenComboId == null,
    );
    if (idx < 0) return;
    _decrementarEnIndice(idx);
  }

  void decrementarVariante(String productoId, String varianteId) {
    final idx = state.items.indexWhere(
      (i) =>
          i.productoId == productoId &&
          i.varianteId == varianteId &&
          i.origenComboId == null,
    );
    if (idx < 0) return;
    _decrementarEnIndice(idx);
  }

  void _decrementarEnIndice(int idx) {
    final actual = state.items[idx];
    if (actual.cantidad <= 1) {
      eliminarItem(idx);
      return;
    }
    final nuevaCantidad = actual.cantidad - 1;
    final icbperPerUnit =
        actual.cantidad > 0 ? actual.icbper / actual.cantidad : 0.0;
    final nueva = actual
        .recalcularPrecioPorNiveles(nuevaCantidad)
        .copyWith(icbper: icbperPerUnit * nuevaCantidad);
    final lista = [...state.items];
    lista[idx] = nueva;
    emit(state.copyWith(items: lista, clearError: true));
  }

  /// Elimina TODOS los items que pertenecen a un combo dado.
  /// Útil para "quitar este combo del carrito" desde la UI.
  void eliminarCombo(String origenComboId) {
    final lista = state.items
        .where((i) => i.origenComboId != origenComboId)
        .toList();
    emit(state.copyWith(items: lista, clearError: true));
  }

  void vaciarCarrito() {
    // Reset del contexto VIP: nueva venta arranca sin precio especial hasta
    // que se vuelva a seleccionar un cliente VIP.
    _vipResolver = null;
    _vipClienteKey = null;
    emit(state.copyWith(
      items: [],
      pagos: [],
      condicionPago: 'CONTADO',
      numeroCuotas: 1,
      plazoDias: 30,
      tipoComprobante: 'TICKET',
      clienteGenerico: false,
      // `clienteId: null` NO limpia (copyWith usa `?? this`): hay que usar los
      // flags clear*, si no el cliente queda pegado y la siguiente venta hereda
      // su precio VIP.
      clearClienteId: true,
      clearClienteEmpresaId: true,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '',
      nombreClienteResuelto: '',
      buscandoCliente: false,
      clearError: true,
      clearVentaCompletada: true,
    ));
  }

  // ── Comprobante / Cliente ──

  void setTipoComprobante(String tipo) {
    // El tipo de documento se DERIVA del comprobante (la UI ya no tiene
    // selector dedicado): FACTURA → RUC (SUNAT solo factura contra RUC);
    // al volver a TICKET/BOLETA desde FACTURA → DNI. En ambos saltos se
    // limpia el cliente resuelto (apunta a una entidad distinta).
    if (tipo == 'FACTURA' && state.tipoDocCliente != 'RUC') {
      emit(state.copyWith(
        tipoComprobante: tipo,
        tipoDocCliente: 'RUC',
        clienteGenerico: false,
        clearClienteId: true,
        clearClienteEmpresaId: true,
        numeroDocCliente: '',
        nombreClienteResuelto: '',
      ));
      return;
    }
    if (tipo != 'FACTURA' &&
        state.tipoComprobante == 'FACTURA' &&
        state.tipoDocCliente == 'RUC') {
      emit(state.copyWith(
        tipoComprobante: tipo,
        tipoDocCliente: 'DNI',
        clienteGenerico: false,
        clearClienteId: true,
        clearClienteEmpresaId: true,
        numeroDocCliente: '',
        nombreClienteResuelto: '',
      ));
      return;
    }
    emit(state.copyWith(tipoComprobante: tipo));
  }

  void setCondicionPago(String condicion) {
    emit(state.copyWith(
      condicionPago: condicion,
      pagos: [],
    ));
  }

  void setNumeroCuotas(int cuotas) {
    if (cuotas < 1) return;
    emit(state.copyWith(
      numeroCuotas: cuotas,
      plazoDias: cuotas * 30,
    ));
  }

  void setPlazoDias(int dias) {
    if (dias < 1) return;
    emit(state.copyWith(plazoDias: dias));
  }

  void setClienteGenerico() {
    emit(state.copyWith(
      clienteGenerico: true,
      clienteId: null,
      clienteEmpresaId: null,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '00000000',
      nombreClienteResuelto: '',
    ));
  }

  void setTipoDocCliente(String tipo) {
    // Cambiar el tipo de documento invalida cualquier cliente resuelto previo
    // (DNI → RUC y viceversa apuntan a entidades distintas).
    emit(state.copyWith(
      tipoDocCliente: tipo,
      clienteGenerico: false,
      clearClienteId: true,
      clearClienteEmpresaId: true,
      nombreClienteResuelto: '',
    ));
  }

  void setNumeroDocCliente(String numero) {
    // Si el cajero edita el doc, invalidamos cualquier cliente resuelto
    // previo (cambió el doc → debe re-resolverse).
    final invalidar = numero.trim() != state.numeroDocCliente.trim();
    emit(state.copyWith(
      numeroDocCliente: numero,
      clienteGenerico: false,
      clearClienteId: invalidar,
      clearClienteEmpresaId: invalidar,
      nombreClienteResuelto: invalidar ? '' : state.nombreClienteResuelto,
    ));
  }

  /// Busca un cliente por DNI vía RENIEC y lo registra/reutiliza en backend.
  /// Pre-llena `clienteId` y `nombreClienteResuelto` para que `cobrar()` los use
  /// (sin pasar por la lógica de "genérico").
  Future<void> buscarClientePorDni(String dni) async {
    if (state.buscandoCliente) return; // guard de re-entrada
    final dniLimpio = dni.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(dniLimpio)) {
      emit(state.copyWith(error: 'El DNI debe tener 8 dígitos'));
      return;
    }
    if (dniLimpio == '00000000') {
      emit(state.copyWith(error: 'Para cliente sin documento usá "Genérico"'));
      return;
    }

    // Local-first: si el cliente ya está en el catálogo de la empresa,
    // resolución instantánea sin red (y funciona offline). El backend
    // (BD interna → RENIEC) queda solo para documentos desconocidos.
    final empresaIdDni = state.empresaId;
    if (empresaIdDni != null && empresaIdDni.isNotEmpty) {
      Cliente? local;
      for (final c
          in await ClienteCatalogoService.instance.hydrate(empresaIdDni)) {
        if (c.dni == dniLimpio) {
          local = c;
          break;
        }
      }
      if (local != null) {
        if (isClosed) return;
        emit(state.copyWith(
          buscandoCliente: false,
          clienteGenerico: false,
          clienteId: local.id,
          clearClienteEmpresaId: true,
          tipoDocCliente: 'DNI',
          numeroDocCliente: dniLimpio,
          nombreClienteResuelto: local.nombreCompleto,
          clearError: true,
          clearDocSinResultado: true,
        ));
        return;
      }
    }

    final mySeq = ++_searchSeq;
    emit(state.copyWith(buscandoCliente: true, clearError: true));
    final result = await _buscarClientePorDniUseCase(dniLimpio);
    if (isClosed) return;
    if (mySeq != _searchSeq) return; // llegó otra búsqueda más nueva

    if (result is Success<ClienteResueltoDni>) {
      final c = result.data;
      emit(state.copyWith(
        buscandoCliente: false,
        clienteGenerico: false,
        clienteId: c.clienteEmpresaId,
        clearClienteEmpresaId: true,
        tipoDocCliente: 'DNI',
        numeroDocCliente: c.dni,
        nombreClienteResuelto: c.nombreCompleto,
        clearDocSinResultado: true,
      ));
    } else if (result is Error<ClienteResueltoDni>) {
      // No existe ni local ni en el sistema/RENIEC → la UI abre el sheet
      // de registro pre-llenado (sin snackbar de error: el sheet ES el
      // siguiente paso del flujo).
      emit(state.copyWith(
        buscandoCliente: false,
        nombreClienteResuelto: '',
        clearClienteId: true,
        docSinResultado: dniLimpio,
      ));
    }
  }

  /// Busca un cliente empresa (B2B) por RUC vía SUNAT.
  /// Pre-llena `clienteEmpresaId` y `nombreClienteResuelto` (= razón social).
  Future<void> buscarClientePorRuc(String ruc) async {
    if (state.buscandoCliente) return; // guard de re-entrada
    final rucLimpio = ruc.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(rucLimpio)) {
      emit(state.copyWith(error: 'El RUC debe tener 11 dígitos'));
      return;
    }

    // Local-first contra el catálogo B2B (paridad con el flujo DNI).
    final empresaIdRuc = state.empresaId;
    if (empresaIdRuc != null && empresaIdRuc.isNotEmpty) {
      ClienteEmpresa? local;
      for (final c in await ClienteEmpresaCatalogoService.instance
          .hydrate(empresaIdRuc)) {
        if (c.numeroDocumento == rucLimpio) {
          local = c;
          break;
        }
      }
      if (local != null) {
        if (isClosed) return;
        emit(state.copyWith(
          buscandoCliente: false,
          clienteGenerico: false,
          clearClienteId: true,
          clienteEmpresaId: local.id,
          tipoDocCliente: 'RUC',
          numeroDocCliente: rucLimpio,
          nombreClienteResuelto: local.razonSocial,
          clearError: true,
          clearDocSinResultado: true,
        ));
        return;
      }
    }

    final mySeq = ++_searchSeq;
    emit(state.copyWith(buscandoCliente: true, clearError: true));
    final result = await _buscarClientePorRucUseCase(rucLimpio);
    if (isClosed) return;
    if (mySeq != _searchSeq) return; // llegó otra búsqueda más nueva

    if (result is Success<ClienteResueltoRuc>) {
      final c = result.data;
      emit(state.copyWith(
        buscandoCliente: false,
        clienteGenerico: false,
        clearClienteId: true,
        clienteEmpresaId: c.clienteEmpresaId,
        tipoDocCliente: 'RUC',
        numeroDocCliente: c.ruc,
        nombreClienteResuelto: c.razonSocial,
        clearDocSinResultado: true,
      ));
    } else if (result is Error<ClienteResueltoRuc>) {
      // No existe → sheet de registro pre-llenado (ver flujo DNI).
      emit(state.copyWith(
        buscandoCliente: false,
        nombreClienteResuelto: '',
        clearClienteEmpresaId: true,
        docSinResultado: rucLimpio,
      ));
    }
  }

  /// La UI consumió `docSinResultado` (abrió el sheet de registro).
  void limpiarDocSinResultado() {
    emit(state.copyWith(clearDocSinResultado: true));
  }

  /// Setea el cliente elegido desde el ClienteUnificadoSelector (búsqueda
  /// por NOMBRE cuando el cajero no tiene el documento a la mano). Misma
  /// semántica que buscarClientePorDni/Ruc: persona llena clienteId,
  /// empresa llena clienteEmpresaId.
  void setClienteDesdeSelector({
    String? clienteId,
    String? clienteEmpresaId,
    required String nombre,
    required String tipoDoc,
    String? numeroDoc,
  }) {
    emit(state.copyWith(
      clienteGenerico: false,
      clienteId: clienteId,
      clearClienteId: clienteId == null,
      clienteEmpresaId: clienteEmpresaId,
      clearClienteEmpresaId: clienteEmpresaId == null,
      tipoDocCliente: tipoDoc,
      numeroDocCliente: numeroDoc ?? '',
      nombreClienteResuelto: nombre,
      clearError: true,
      clearDocSinResultado: true,
    ));
  }

  // ── Pagos ──

  void agregarPago({required String metodo, required double monto, String? banco, String? referencia}) {
    if (monto <= 0) return;
    final pagos = [
      ...state.pagos,
      {
        'metodo': metodo,
        'monto': monto,
        if (banco != null) 'banco': banco,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
      },
    ];
    emit(state.copyWith(pagos: pagos));
  }

  void eliminarPago(int index) {
    if (index < 0 || index >= state.pagos.length) return;
    final pagos = [...state.pagos]..removeAt(index);
    emit(state.copyWith(pagos: pagos));
  }

  // ── Validación de pago con api-yape (Yape/Plin) ──

  /// Crea la venta como PENDIENTE (sin registrar el pago) y genera el monto
  /// único a pagar con api-yape. Devuelve {ventaId, habilitado, payAmount} o
  /// null si falló crear la venta. NO marca la venta pagada: eso lo hace el
  /// webhook (automático) o la confirmación manual.
  Future<Map<String, dynamic>?> iniciarCobroYape() async {
    if (state.procesando) return null;
    if (state.items.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un producto'));
      return null;
    }
    emit(state.copyWith(procesando: true, clearError: true));

    // Resolver cliente (mismo criterio que cobrar()).
    final docTipeado = state.numeroDocCliente.trim();
    final tieneClienteRucResuelto = state.clienteEmpresaId != null &&
        state.nombreClienteResuelto.isNotEmpty &&
        docTipeado.isNotEmpty;
    final tieneClienteDniResuelto = !tieneClienteRucResuelto &&
        state.clienteId != null &&
        state.nombreClienteResuelto.isNotEmpty &&
        docTipeado != '00000000' &&
        docTipeado.isNotEmpty;
    final esGenerico = !tieneClienteRucResuelto &&
        !tieneClienteDniResuelto &&
        (state.clienteGenerico || docTipeado.isEmpty || docTipeado == '00000000');

    String? clienteId = tieneClienteDniResuelto ? state.clienteId : null;
    final String? clienteEmpresaId =
        tieneClienteRucResuelto ? state.clienteEmpresaId : null;
    if (esGenerico) {
      final r = await _obtenerClienteGenericoUseCase();
      if (r is Success<String>) clienteId = r.data;
    }
    final docCliente = esGenerico ? '00000000' : docTipeado;
    final nombreCliente = esGenerico
        ? 'CLIENTES VARIOS'
        : ((tieneClienteRucResuelto || tieneClienteDniResuelto)
            ? state.nombreClienteResuelto
            : docTipeado);

    // Payload SIN bloque de pagos → montoRecibido 0 → venta CONFIRMADA pendiente.
    final data = <String, dynamic>{
      'canalVenta': 'POS',
      'sedeId': state.sedeId,
      'vendedorId': state.vendedorId,
      if (clienteId != null) 'clienteId': clienteId,
      if (clienteEmpresaId != null) 'clienteEmpresaId': clienteEmpresaId,
      'nombreCliente': nombreCliente,
      if (docCliente.isNotEmpty) 'documentoCliente': docCliente,
      'moneda': state.moneda,
      'tipoComprobante': state.tipoComprobante,
      'esCredito': false,
      'detalles': state.items.map((item) => item.toMap()).toList(),
    };

    final result = await _repository.cobrar(data: data);
    if (isClosed) return null;
    if (result is! Success<Venta>) {
      emit(state.copyWith(
        procesando: false,
        error: result is Error<Venta>
            ? result.message
            : 'No se pudo crear la venta',
      ));
      return null;
    }
    final ventaId = result.data.id;

    // Generar el monto único en api-yape.
    final cobro = await _repository.cobroYape(ventaId);
    if (isClosed) return null;
    emit(state.copyWith(procesando: false));
    if (cobro is Success<Map<String, dynamic>>) {
      final payAmount = cobro.data['payAmount'];
      return {
        'ventaId': ventaId,
        'habilitado': cobro.data['habilitado'] == true,
        'payAmount': payAmount is num ? payAmount.toDouble() : null,
        'qrYapeUrl': cobro.data['qrYapeUrl'] as String?,
        'qrPlinUrl': cobro.data['qrPlinUrl'] as String?,
      };
    }
    // api-yape no disponible → la venta existe (pendiente): fallback manual.
    return {'ventaId': ventaId, 'habilitado': false, 'payAmount': null};
  }

  /// Registra el pago manualmente (fallback con el screenshot del Yape) y
  /// marca la venta pagada. Devuelve true si quedó registrado.
  Future<bool> confirmarPagoManualYape({
    required String ventaId,
    required double monto,
    required String metodo, // YAPE | PLIN
    String? referencia,
  }) async {
    final result = await _repository.registrarPago(ventaId, {
      'metodoPago': metodo,
      'monto': monto,
      if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
    });
    return result is Success<Venta>;
  }

  /// Acceso al servicio de realtime para que la hoja de espera Yape escuche
  /// el evento VENTA_PAGADA de esta venta.
  RealtimeSyncService get realtimeSync => _realtimeSync;

  /// Marca la venta como completada (dispara el flujo post-venta existente:
  /// impresión de ticket, limpiar carrito, etc.). Se usa tras confirmarse el
  /// pago Yape (automático por webhook o manual).
  void marcarVentaCompletada(String ventaId) {
    if (isClosed) return;
    emit(state.copyWith(ventaCompletadaId: ventaId));
  }

  // ── Cobrar ──

  Future<void> cobrar({
    bool aceptaRiesgoBancarizacion = false,
    String? ventaBajoCostoAutorizadaPorId,
  }) async {
    // Guard de re-entrada: evita doble-cobro si el cajero da doble-tap
    // antes de que el botón se deshabilite por rebuild.
    if (state.procesando) return;
    if (state.items.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un producto'));
      return;
    }
    // Sin pagos solo es válido cuando no hay nada que cobrar HOY (orden
    // 100% cubierta por adelantos: la boleta sale por el total igual).
    if (!state.esCredito &&
        state.pagos.isEmpty &&
        state.totalACobrar > _kPenPaymentTolerance) {
      emit(state.copyWith(error: 'Agrega al menos un pago'));
      return;
    }
    // Validar contra lo que se cobra HOY (total − adelantos aplicados de
    // órdenes de servicio): el comprobante sale por el total, pero el
    // adelanto ya se pagó antes.
    if (!state.esCredito &&
        state.totalPagado + _kPenPaymentTolerance < state.totalACobrar) {
      emit(state.copyWith(error: 'Monto recibido insuficiente'));
      return;
    }

    emit(state.copyWith(procesando: true, clearError: true));

    // 3 modos posibles para resolver el cliente vinculado a la venta:
    //   (a) Cliente jurídico resuelto por RUC → clienteEmpresaId (B2B).
    //   (b) Cliente persona resuelto por DNI → clienteId (EmpresaPersona).
    //   (c) Genérico (flag, doc vacío o '00000000') → clienteId genérico.
    final docTipeado = state.numeroDocCliente.trim();
    final tieneClienteRucResuelto = state.clienteEmpresaId != null &&
        state.nombreClienteResuelto.isNotEmpty &&
        docTipeado.isNotEmpty;
    final tieneClienteDniResuelto = !tieneClienteRucResuelto &&
        state.clienteId != null &&
        state.nombreClienteResuelto.isNotEmpty &&
        docTipeado != '00000000' &&
        docTipeado.isNotEmpty;
    final esGenerico = !tieneClienteRucResuelto &&
        !tieneClienteDniResuelto &&
        (state.clienteGenerico || docTipeado.isEmpty || docTipeado == '00000000');

    if (state.esCredito && esGenerico) {
      emit(state.copyWith(
        procesando: false,
        error: 'Credito requiere un cliente identificado (DNI o RUC)',
      ));
      return;
    }

    String? clienteId = tieneClienteDniResuelto ? state.clienteId : null;
    String? clienteEmpresaId = tieneClienteRucResuelto ? state.clienteEmpresaId : null;
    if (esGenerico) {
      final result = await _obtenerClienteGenericoUseCase();
      if (result is Success<String>) {
        clienteId = result.data;
      }
      // Si falla resolver el genérico, seguimos sin clienteId (el backend
      // permite venta sin cliente vinculado para tickets).
    }

    final docCliente = esGenerico ? '00000000' : docTipeado;
    final nombreCliente = esGenerico
        ? 'CLIENTES VARIOS'
        : ((tieneClienteRucResuelto || tieneClienteDniResuelto)
            ? state.nombreClienteResuelto
            : docTipeado);

    final data = <String, dynamic>{
      'canalVenta': 'POS',
      'sedeId': state.sedeId,
      'vendedorId': state.vendedorId,
      if (clienteId != null) 'clienteId': clienteId,
      if (clienteEmpresaId != null) 'clienteEmpresaId': clienteEmpresaId,
      'nombreCliente': nombreCliente,
      if (docCliente.isNotEmpty) 'documentoCliente': docCliente,
      'moneda': state.moneda,
      'tipoComprobante': state.tipoComprobante,
      'esCredito': state.esCredito,
      if (state.esCredito) ...{
        'plazoCredito': state.plazoDias,
        'numeroCuotas': state.numeroCuotas,
      },
      if (aceptaRiesgoBancarizacion) 'aceptaRiesgoBancarizacion': true,
      if (ventaBajoCostoAutorizadaPorId != null)
        'ventaBajoCostoAutorizadaPorId': ventaBajoCostoAutorizadaPorId,
      if (state.pagos.isNotEmpty) ...{
        'metodoPago': state.pagos.first['metodo'],
        'montoRecibido': state.totalPagado,
        'pagos': state.pagos.map((p) => {
              'metodoPago': p['metodo'],
              'monto': p['monto'],
              if (p['banco'] != null) 'banco': p['banco'],
              if (p['referencia'] != null) 'referencia': p['referencia'],
            }).toList(),
      },
      'detalles': state.items.map((item) => item.toMap()).toList(),
      // No enviamos `observaciones` para que el ticket no muestre el texto
      // "Venta rápida". La trazabilidad de origen se mantiene a través de
      // `canalVenta` (POS) y otros campos.
    };

    final result = await _cobrarUseCase(data: data);
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(state.copyWith(
        procesando: false,
        ventaCompletadaId: result.data.id,
      ));
    } else if (result is Error<Venta>) {
      // Errores estructurados del backend que abren un dialog específico:
      //  - PRECIO_DESACTUALIZADO: admin cambió precio/nivel mientras se
      //    armaba el carrito → ofrecer aplicar precios nuevos.
      //  - STOCK_INSUFICIENTE: otro cajero vendió ese stock antes → ofrecer
      //    ajustar la cantidad al disponible (o cancelar).
      if (result.errorCode == 'PRECIO_DESACTUALIZADO') {
        final divergencias = (result.details?['divergencias'] as List?)
                ?.whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList() ??
            <Map<String, dynamic>>[];
        emit(state.copyWith(
          procesando: false,
          preciosDesactualizados: divergencias,
        ));
        return;
      }
      if (result.errorCode == 'STOCK_INSUFICIENTE') {
        final divergencias = (result.details?['divergencias'] as List?)
                ?.whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList() ??
            <Map<String, dynamic>>[];
        emit(state.copyWith(
          procesando: false,
          stockInsuficiente: divergencias,
        ));
        return;
      }
      // 409 de órdenes de servicio: quitar las líneas afectadas del carrito
      // (sin esto el cajero reintentaría en bucle contra el mismo error).
      //  - ORDEN_YA_COBRADA: otra venta ganó la carrera — la orden ya no es
      //    cobrable, fuera del carrito.
      //  - SALDO_ORDEN_DESACTUALIZADO: costo/adelanto cambiaron — se quita
      //    para que al re-agregarla cargue los montos vigentes (parchear
      //    solo el precio dejaría un adelanto stale en la línea).
      if (result.errorCode == 'ORDEN_YA_COBRADA' ||
          result.errorCode == 'SALDO_ORDEN_DESACTUALIZADO') {
        final idsAfectados = <String>{
          ...((result.details?['ordenes'] as List?) ?? [])
              .whereType<Map>()
              .map((m) => m['ordenServicioId'] as String?)
              .whereType<String>(),
          ...((result.details?['divergencias'] as List?) ?? [])
              .whereType<Map>()
              .map((m) => m['ordenServicioId'] as String?)
              .whereType<String>(),
        };
        // Fallback sin ids estructurados: quitar todas las líneas de orden.
        final lista = state.items
            .where((i) => !(i.esOrdenServicio &&
                (idsAfectados.isEmpty ||
                    idsAfectados.contains(i.ordenServicioId))))
            .toList();
        final esYaCobrada = result.errorCode == 'ORDEN_YA_COBRADA';
        emit(state.copyWith(
          procesando: false,
          items: lista,
          error: esYaCobrada
              ? '${result.message} La línea se quitó del carrito.'
              : 'Los montos de la orden cambiaron y la línea se quitó del carrito. Vuelve a agregarla para cobrar con los valores vigentes.',
        ));
        return;
      }
      emit(state.copyWith(
        procesando: false,
        error: result.message,
      ));
    }
  }

  /// Sincroniza el carrito con los precios actuales del backend después de
  /// que un cobro fue rechazado por `PRECIO_DESACTUALIZADO`. Además del
  /// precio base, **refresca los niveles cacheados** de cada producto
  /// afectado: si el admin modificó/eliminó/agregó un nivel "Por Mayor",
  /// el cliente debe volver a fetchear los niveles para no aplicar uno
  /// obsoleto en el próximo cobro (sería un bucle: re-cobro → 409 → ...).
  Future<void> aplicarPreciosNuevosDeBackend() async {
    final divergencias = state.preciosDesactualizados;
    if (divergencias == null || divergencias.isEmpty) {
      emit(state.copyWith(clearPreciosDesactualizados: true));
      return;
    }

    // 1. Indexar por (productoId|comboId, varianteId) para buscar rápido.
    String keyFor(String? prodId, String? varId, String? comboId) =>
        '${prodId ?? comboId ?? ''}::${varId ?? ''}';
    final mapaPrecios = <String, double>{};
    for (final d in divergencias) {
      final k = keyFor(d['productoId'] as String?, d['varianteId'] as String?,
          d['comboId'] as String?);
      final p = d['precioServer'];
      if (p is num) mapaPrecios[k] = p.toDouble();
    }

    // 2. Invalidar y re-fetch los niveles de cada producto afectado.
    //    La invalidación borra el cache local; el `getNiveles` siguiente
    //    dispara fetch al backend con la configuración actual.
    final productosAfectados = divergencias
        .map((d) => d['productoId'] as String?)
        .whereType<String>()
        .toSet();
    for (final pid in productosAfectados) {
      _nivelCacheService.invalidate(pid);
    }
    final fetched = await Future.wait(
      productosAfectados.map(
        (pid) =>
            _nivelCacheService.getNiveles(pid).then((n) => MapEntry(pid, n)),
      ),
    );
    final nivelesPorProducto = Map<String, List<PrecioNivel>>.fromEntries(
      fetched,
    );

    // 2b. Refrescar el estado de liquidación (y costo) de los items afectados.
    //     Si el admin activó liquidación mientras tanto, hay que actualizar el
    //     flag para que `recalcularPrecioPorNiveles` ignore los niveles (la
    //     liquidación gana). Sin esto, un nivel % podría bajar el precio por
    //     debajo del remate.
    final sedeId = state.sedeId;
    final liquidacionPorKey = <String, bool>{};
    final costoPorKey = <String, double?>{};
    if (sedeId != null) {
      final stockEntries = await Future.wait(
        state.items
            .where((i) =>
                mapaPrecios.containsKey(keyFor(i.productoId, i.varianteId, null)))
            .map((i) async {
          final pid = i.productoId;
          if (pid == null) return null;
          final result = i.varianteId != null
              ? await _stockRepository.getStockVarianteEnSede(
                  varianteId: i.varianteId!, sedeId: sedeId)
              : await _stockRepository.getStockProductoEnSede(
                  productoId: pid, sedeId: sedeId);
          if (result is Success<ProductoStock>) {
            return MapEntry(keyFor(i.productoId, i.varianteId, null), result.data);
          }
          return null;
        }),
      );
      for (final entry in stockEntries) {
        if (entry == null) continue;
        liquidacionPorKey[entry.key] = entry.value.isLiquidacionActiva;
        costoPorKey[entry.key] = entry.value.precioCosto;
      }
    }

    // 3. Aplicar nuevo precio base + nuevos niveles + liquidación a cada item.
    //    Después recalcular `precioUnitario` con la cantidad actual.
    final nuevos = state.items.map((item) {
      final k = keyFor(item.productoId, item.varianteId, null);
      final precioNuevo = mapaPrecios[k];
      if (precioNuevo == null) return item;
      final nivelesNuevos = item.productoId != null
          ? (nivelesPorProducto[item.productoId!] ?? item.niveles)
          : item.niveles;
      return item
          .copyWith(
            precioBase: precioNuevo,
            precioUnitario: precioNuevo,
            niveles: nivelesNuevos,
            enLiquidacion: liquidacionPorKey[k] ?? item.enLiquidacion,
            precioCostoSnapshot: costoPorKey[k] ?? item.precioCostoSnapshot,
          )
          .recalcularPrecioPorNiveles(item.cantidad);
    }).toList();

    emit(state.copyWith(
      items: nuevos,
      clearPreciosDesactualizados: true,
    ));
  }

  /// El cajero cancela el cobro tras ver el dialog de precios desactualizados.
  /// Solo limpia el flag, mantiene los items con su precio cliente original.
  void descartarAvisoPreciosDesactualizados() {
    emit(state.copyWith(clearPreciosDesactualizados: true));
  }

  /// Ajusta las cantidades del carrito al stock disponible que el backend
  /// reportó en el 409 STOCK_INSUFICIENTE. Para cada divergencia:
  ///  - Si `stockDisponible == 0` → quita el item del carrito.
  ///  - Si > 0 → reemplaza la cantidad por el disponible y recalcula
  ///    precio según niveles (porque la nueva cantidad puede caer fuera
  ///    de un nivel "Por Mayor").
  /// También refresca el cache de niveles del producto por si el admin
  /// también tocó algún nivel mientras tanto.
  Future<void> ajustarCarritoAStockDisponible() async {
    final divergencias = state.stockInsuficiente;
    if (divergencias == null || divergencias.isEmpty) {
      emit(state.copyWith(clearStockInsuficiente: true));
      return;
    }

    String keyFor(String? prodId, String? varId, String? comboId) =>
        '${prodId ?? comboId ?? ''}::${varId ?? ''}';

    final mapaDisponibles = <String, int>{};
    for (final d in divergencias) {
      final k = keyFor(d['productoId'] as String?, d['varianteId'] as String?,
          d['comboId'] as String?);
      final s = d['stockDisponible'];
      if (s is num) mapaDisponibles[k] = s.toInt();
    }

    // Re-fetch niveles de los productos afectados (defensive — el admin
    // pudo haber cambiado niveles también; el recalculo del precio
    // necesita la config actual).
    final productosAfectados = divergencias
        .map((d) => d['productoId'] as String?)
        .whereType<String>()
        .toSet();
    for (final pid in productosAfectados) {
      _nivelCacheService.invalidate(pid);
    }
    final fetched = await Future.wait(
      productosAfectados.map(
        (pid) =>
            _nivelCacheService.getNiveles(pid).then((n) => MapEntry(pid, n)),
      ),
    );
    final nivelesPorProducto = Map<String, List<PrecioNivel>>.fromEntries(
      fetched,
    );

    // Refrescar estado de liquidación (y costo) de los afectados, por si el
    // admin activó liquidación mientras tanto — la liquidación gana sobre
    // los niveles al recalcular con la nueva cantidad.
    final sedeId = state.sedeId;
    final liquidacionPorKey = <String, bool>{};
    final costoPorKey = <String, double?>{};
    if (sedeId != null) {
      final stockEntries = await Future.wait(
        state.items
            .where((i) =>
                mapaDisponibles.containsKey(keyFor(i.productoId, i.varianteId, null)))
            .map((i) async {
          final pid = i.productoId;
          if (pid == null) return null;
          final result = i.varianteId != null
              ? await _stockRepository.getStockVarianteEnSede(
                  varianteId: i.varianteId!, sedeId: sedeId)
              : await _stockRepository.getStockProductoEnSede(
                  productoId: pid, sedeId: sedeId);
          if (result is Success<ProductoStock>) {
            return MapEntry(keyFor(i.productoId, i.varianteId, null), result.data);
          }
          return null;
        }),
      );
      for (final entry in stockEntries) {
        if (entry == null) continue;
        liquidacionPorKey[entry.key] = entry.value.isLiquidacionActiva;
        costoPorKey[entry.key] = entry.value.precioCosto;
      }
    }

    // Ajustar cada item: quitar si stockDisponible=0, sino recalcular
    // con nueva cantidad y niveles frescos.
    final nuevos = <VentaDetalleInput>[];
    for (final item in state.items) {
      final k = keyFor(item.productoId, item.varianteId, null);
      final disponible = mapaDisponibles[k];
      if (disponible == null) {
        nuevos.add(item);
        continue;
      }
      if (disponible <= 0) {
        // Cero stock → quitar del carrito.
        continue;
      }
      final nivelesNuevos = item.productoId != null
          ? (nivelesPorProducto[item.productoId!] ?? item.niveles)
          : item.niveles;
      nuevos.add(
        item
            .copyWith(
              cantidad: disponible.toDouble(),
              niveles: nivelesNuevos,
              stockDisponible: disponible,
              enLiquidacion: liquidacionPorKey[k] ?? item.enLiquidacion,
              precioCostoSnapshot: costoPorKey[k] ?? item.precioCostoSnapshot,
            )
            .recalcularPrecioPorNiveles(disponible.toDouble()),
      );
    }

    emit(state.copyWith(
      items: nuevos,
      clearStockInsuficiente: true,
    ));
  }

  /// El cajero cancela el cobro tras ver el dialog de stock insuficiente.
  /// Mantiene el carrito como está — el cajero quizás quiere comunicar al
  /// cliente que esos productos no están y resolver manualmente.
  void descartarAvisoStockInsuficiente() {
    emit(state.copyWith(clearStockInsuficiente: true));
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  // ── Sync realtime del carrito (capa 1: FCM data-only) ──
  //
  // Cuando el backend emite FCM (`PRECIO_CAMBIADO` / `NIVELES_CAMBIADOS` /
  // `STOCK_CAMBIADO`), el [RealtimeSyncService] emite un evento en su stream
  // y la grilla de productos ya se refresca. Acá también sincronizamos los
  // items del carrito: re-fetch precio + niveles + stock por sede.
  //
  // Sin esto, los items del carrito mantenían el `precioUnitario` viejo
  // hasta el cobro: el server-side rechazaba con 409 y la capa 3 (dialog)
  // resolvía. Esa cadena sigue cubriendo el caso si FCM falla; este sync
  // simplemente mejora la UX: el cajero ve el precio nuevo en el carrito
  // antes de tocar "Cobrar".

  StreamSubscription<RealtimeEvent>? _realtimeSub;
  Timer? _realtimeDebounce;
  final Set<String> _pendingProductoIds = {};
  bool _pendingSyncAll = false;
  int _syncSeq = 0;

  void _suscribirRealtime() {
    _realtimeSub = _realtimeSync.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    // Mientras se procesa un cobro NO tocamos el carrito — el payload ya
    // viaja al servidor. Si el precio difiere, capa 2 lo rechaza con 409 y
    // capa 3 dispara el dialog amigable. Mutar el state mid-cobro causaría
    // inconsistencia entre lo enviado y lo mostrado.
    if (state.procesando) return;

    final evtEmpresaId = _empresaIdFromEvent(event);
    final evtSedeId = _sedeIdFromEvent(event);
    final evtProductoId = _productoIdFromEvent(event);

    // Filtrado defensivo:
    //  - Si el evento trae empresaId y NO matchea la del carrito → ignorar
    //    (otro tenant suscrito al mismo topic no debería pasar, pero por
    //    si acaso).
    //  - Si trae sedeId y no matchea la sede del carrito → ignorar (cambio
    //    de precio en otra sede no afecta).
    if (state.empresaId != null &&
        evtEmpresaId != null &&
        state.empresaId != evtEmpresaId) {
      return;
    }
    if (state.sedeId != null &&
        evtSedeId != null &&
        state.sedeId != evtSedeId) {
      return;
    }

    // Acumular productoIds afectados y debouncear: si caen N eventos en
    // ráfaga (admin haciendo varios cambios) se procesan en una sola pasada.
    if (evtProductoId == null) {
      _pendingSyncAll = true;
    } else {
      _pendingProductoIds.add(evtProductoId);
    }
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 500), _flushSync);
  }

  String? _empresaIdFromEvent(RealtimeEvent e) {
    if (e is RealtimePrecioCambiado) return e.empresaId;
    if (e is RealtimeStockCambiado) return e.empresaId;
    if (e is RealtimeNivelesCambiados) return e.empresaId;
    // PRODUCTO_ACTUALIZADO cubre cambios estructurales (variantes, combo,
    // isActive, etc). Si el producto está en el carrito, el flush hará
    // refetch de precio/stock/niveles igual que con PRECIO_CAMBIADO.
    if (e is RealtimeProductoActualizado) return e.empresaId;
    return null;
  }

  String? _sedeIdFromEvent(RealtimeEvent e) {
    if (e is RealtimePrecioCambiado) return e.sedeId;
    if (e is RealtimeStockCambiado) return e.sedeId;
    // niveles y PRODUCTO_ACTUALIZADO no son por sede — el refetch del
    // producto trae precio/stock de la sede actual de igual modo.
    return null;
  }

  String? _productoIdFromEvent(RealtimeEvent e) {
    if (e is RealtimePrecioCambiado) return e.productoId;
    if (e is RealtimeStockCambiado) return e.productoId;
    if (e is RealtimeNivelesCambiados) return e.productoId;
    if (e is RealtimeProductoActualizado) return e.productoId;
    return null;
  }

  Future<void> _flushSync() async {
    final productoIds = _pendingProductoIds.toSet();
    final syncAll = _pendingSyncAll;
    _pendingProductoIds.clear();
    _pendingSyncAll = false;
    if (productoIds.isEmpty && !syncAll) return;
    await _sincronizarItemsCarrito(productoIds, syncAll);
  }

  /// Identifica los items del carrito afectados por el cambio FCM, re-fetch
  /// niveles + precio + stock por sede y reaplica con `recalcularPrecioPorNiveles`.
  ///
  /// Items combo (`origenComboId != null`) NO se tocan: el precio del combo
  /// se prorratea al armar el combo y no debe re-cotizarse cada vez que el
  /// admin tocó un precio individual. El backend ya valida el combo entero
  /// al cobrar.
  Future<void> _sincronizarItemsCarrito(
    Set<String> productoIds,
    bool syncAll,
  ) async {
    final items = state.items;
    if (items.isEmpty) return;

    final mySeq = ++_syncSeq;

    // Items afectados: filtramos por productoId (excluyendo combos).
    final afectados = <int>[];
    final productosAfectados = <String>{};
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final pid = item.productoId;
      if (pid == null) continue;
      if (item.origenComboId != null) continue;
      if (syncAll || productoIds.contains(pid)) {
        afectados.add(i);
        productosAfectados.add(pid);
      }
    }
    if (afectados.isEmpty) return;

    // 1. Invalidar y refetch niveles (el RealtimeSyncService ya invalidó
    //    para el productoId del evento, pero acá cubrimos también el caso
    //    syncAll y somos idempotentes).
    for (final pid in productosAfectados) {
      _nivelCacheService.invalidate(pid);
    }
    final nivelesEntries = await Future.wait(
      productosAfectados.map(
        (pid) => _nivelCacheService
            .getNiveles(pid)
            .then((n) => MapEntry(pid, n)),
      ),
    );
    if (isClosed || mySeq != _syncSeq) return;
    final nivelesPorProducto = Map<String, List<PrecioNivel>>.fromEntries(
      nivelesEntries,
    );

    // 2. Refetch precio + stock por sede para cada item afectado.
    final sedeId = state.sedeId;
    final preciosNuevos = <int, double>{};
    final stockNuevo = <int, int>{};
    // Snapshot de liquidacion + costo: si el admin activo/desactivo la
    // liquidacion mientras el item ya estaba en el carrito, sin esto el
    // guard cliente seguiria viendo el estado viejo y pediria autorizacion
    // gerencial cuando ya no hace falta.
    final liquidacionNueva = <int, bool>{};
    final costoNuevo = <int, double?>{};
    if (sedeId != null) {
      final stockEntries = await Future.wait(
        afectados.map((idx) async {
          final item = items[idx];
          final pid = item.productoId;
          if (pid == null) return null;
          final result = item.varianteId != null
              ? await _stockRepository.getStockVarianteEnSede(
                  varianteId: item.varianteId!,
                  sedeId: sedeId,
                )
              : await _stockRepository.getStockProductoEnSede(
                  productoId: pid,
                  sedeId: sedeId,
                );
          if (result is Success<ProductoStock>) {
            return MapEntry(idx, result.data);
          }
          return null;
        }),
      );
      if (isClosed || mySeq != _syncSeq) return;
      for (final entry in stockEntries) {
        if (entry == null) continue;
        final s = entry.value;
        final precioEf = s.precioEfectivo;
        if (precioEf != null) preciosNuevos[entry.key] = precioEf;
        stockNuevo[entry.key] = s.stockActual;
        liquidacionNueva[entry.key] = s.isLiquidacionActiva;
        costoNuevo[entry.key] = s.precioCosto;
      }
    }

    // 3. Aplicar nuevo precio base + niveles + stock disponible a cada item.
    //    `recalcularPrecioPorNiveles` deja `precioUnitario` final ya con el
    //    nivel correcto para la cantidad actual.
    final nuevos = [...state.items];
    var huboCambios = false;
    for (final idx in afectados) {
      // Defender contra el caso `items` cambió de tamaño entre el snapshot
      // y ahora (eliminarItem/agregarProducto en paralelo).
      if (idx >= nuevos.length) continue;
      final item = nuevos[idx];
      final pid = item.productoId;
      if (pid == null) continue;
      final nivelesNuevos = nivelesPorProducto[pid] ?? item.niveles;
      final precioNuevo =
          preciosNuevos[idx] ?? item.precioBase ?? item.precioUnitario;
      final stockNvo = stockNuevo[idx] ?? item.stockDisponible;
      final actualizado = item
          .copyWith(
            precioBase: precioNuevo,
            precioUnitario: precioNuevo,
            niveles: nivelesNuevos,
            stockDisponible: stockNvo,
            enLiquidacion: liquidacionNueva[idx] ?? item.enLiquidacion,
            precioCostoSnapshot: costoNuevo[idx] ?? item.precioCostoSnapshot,
          )
          .recalcularPrecioPorNiveles(item.cantidad);
      nuevos[idx] = actualizado;
      huboCambios = true;
    }
    if (!huboCambios) return;
    debugPrint(
        '[VentaRapida] Carrito sincronizado por FCM: ${afectados.length} item(s)');
    emit(state.copyWith(items: nuevos));
  }

  @override
  Future<void> close() {
    _realtimeDebounce?.cancel();
    _realtimeSub?.cancel();
    return super.close();
  }

  void resetCompletada() {
    // Igual que vaciarCarrito: la próxima venta arranca limpia, sin VIP.
    _vipResolver = null;
    _vipClienteKey = null;
    emit(state.copyWith(
      items: [],
      pagos: [],
      condicionPago: 'CONTADO',
      numeroCuotas: 1,
      plazoDias: 30,
      tipoComprobante: 'TICKET',
      clienteGenerico: false,
      // Ver nota en vaciarCarrito: usar flags clear* para limpiar de verdad.
      clearClienteId: true,
      clearClienteEmpresaId: true,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '',
      nombreClienteResuelto: '',
      buscandoCliente: false,
      clearError: true,
      clearVentaCompletada: true,
    ));
  }
}
