import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../combo/domain/entities/combo.dart';
import '../../../combo/domain/repositories/combo_repository.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../../../cotizacion/domain/entities/cotizacion_detalle.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_stock.dart';
import '../../../producto/domain/repositories/producto_stock_repository.dart';
import '../../../producto/domain/services/precio_nivel_cache_service.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../../../venta_rapida/domain/repositories/venta_rapida_repository.dart';
import '../../../venta_rapida/domain/usecases/buscar_cliente_por_dni_usecase.dart';
import '../../../venta_rapida/domain/usecases/buscar_cliente_por_ruc_usecase.dart';
import '../../domain/usecases/actualizar_cotizacion_rapida_usecase.dart';
import '../../domain/usecases/crear_cotizacion_rapida_usecase.dart';

part 'cotizacion_rapida_state.dart';

/// Tipos de cotización (solo client-side).
/// - SIMPLE: permite items manuales (sin productoId).
/// - PARA_VENTA: solo items del catálogo, lista para convertir a venta directa.
class TipoCotizacionRapida {
  static const simple = 'SIMPLE';
  static const paraVenta = 'PARA_VENTA';
}

@lazySingleton
class CotizacionRapidaCubit extends Cubit<CotizacionRapidaState> {
  final CrearCotizacionRapidaUseCase _crearCotizacionUseCase;
  final ActualizarCotizacionRapidaUseCase _actualizarCotizacionUseCase;
  final BuscarClientePorDniUseCase _buscarClientePorDniUseCase;
  final BuscarClientePorRucUseCase _buscarClientePorRucUseCase;
  final PrecioNivelCacheService _nivelCacheService;
  final ComboRepository _comboRepository;
  final ProductoStockRepository _stockRepository;
  final RealtimeSyncService _realtimeSync;

  CotizacionRapidaCubit(
    this._crearCotizacionUseCase,
    this._actualizarCotizacionUseCase,
    this._buscarClientePorDniUseCase,
    this._buscarClientePorRucUseCase,
    this._nivelCacheService,
    this._comboRepository,
    this._stockRepository,
    this._realtimeSync,
  ) : super(const CotizacionRapidaState()) {
    _suscribirRealtime();
  }

  /// Token de búsqueda de cliente para descartar respuestas obsoletas.
  int _searchSeq = 0;

  // ── Contexto ──

  void setContexto({
    required String empresaId,
    required String sedeId,
    required String vendedorId,
    double impuestoPorcentaje = 18.0,
    String moneda = 'PEN',
    int diasVigenciaDefault = 7,
  }) {
    emit(state.copyWith(
      empresaId: empresaId,
      sedeId: sedeId,
      vendedorId: vendedorId,
      impuestoPorcentaje: impuestoPorcentaje,
      moneda: moneda,
      // Solo establece la fecha por defecto si todavía no hay una elegida.
      fechaVencimiento: state.fechaVencimiento ??
          DateTime.now().add(Duration(days: diasVigenciaDefault)),
    ));
  }

  // ── Tipo cotización ──

  /// Cambiar entre SIMPLE y PARA_VENTA. Si PARA_VENTA, los items manuales
  /// no se permiten — al cambiar, removemos los manuales existentes.
  /// Si se vuelve a SIMPLE, también limpiamos las opciones de reserva
  /// (no aplican fuera de PARA_VENTA).
  void setTipoCotizacion(String tipo) {
    if (tipo != TipoCotizacionRapida.simple &&
        tipo != TipoCotizacionRapida.paraVenta) {
      return;
    }
    if (tipo == TipoCotizacionRapida.paraVenta) {
      // Filtrar items manuales (sin productoId/varianteId/servicioId).
      final soloCatalogo = state.items
          .where((i) =>
              i.productoId != null ||
              i.varianteId != null ||
              i.servicioId != null)
          .toList();
      emit(state.copyWith(tipoCotizacion: tipo, items: soloCatalogo));
    } else {
      emit(state.copyWith(
        tipoCotizacion: tipo,
        reservarStock: false,
        adelantoMonto: 0,
        clearCajaIdAdelanto: true,
      ));
    }
  }

  // ── Reserva de stock + adelanto ──

  /// Activa o desactiva la reserva de stock. Si se apaga, también
  /// limpia el monto adelantado (sin reserva no tiene sentido el
  /// adelanto vinculado).
  void setReservarStock(bool valor) {
    if (state.tipoCotizacion != TipoCotizacionRapida.paraVenta) return;
    if (valor) {
      emit(state.copyWith(reservarStock: true));
    } else {
      emit(state.copyWith(
        reservarStock: false,
        adelantoMonto: 0,
        clearCajaIdAdelanto: true,
      ));
    }
  }

  /// Monto del adelanto. 0 = sin adelanto.
  void setAdelantoMonto(double monto) {
    if (monto < 0) return;
    emit(state.copyWith(adelantoMonto: monto));
  }

  /// Caja activa donde se registra el adelanto. Debe corresponder a una
  /// caja ABIERTA del cajero en la sede de la cotización (el backend lo
  /// valida).
  void setCajaIdAdelanto(String? cajaId) {
    if (cajaId == null) {
      emit(state.copyWith(clearCajaIdAdelanto: true));
    } else {
      emit(state.copyWith(cajaIdAdelanto: cajaId));
    }
  }

  // ── Carrito (items de catálogo) — clon de VR.agregarProducto ──

  void agregarProducto(ProductoListItem producto) {
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
    );
    final itemConNivel = nivelesEnCache != null
        ? item.recalcularPrecioPorNiveles(1)
        : item;
    emit(state.copyWith(
      items: [...state.items, itemConNivel],
      clearError: true,
    ));

    if (nivelesEnCache == null) {
      _cargarNivelesYActualizar(producto.id);
    }
  }

  /// Agrega un item manual (sin productoId). Solo permitido en modo SIMPLE.
  void agregarItemManual({
    required String descripcion,
    required double cantidad,
    required double precioUnitario,
  }) {
    if (state.tipoCotizacion == TipoCotizacionRapida.paraVenta) {
      emit(state.copyWith(
        error: 'Los items manuales no se permiten en cotización para venta',
      ));
      return;
    }
    final desc = descripcion.trim();
    if (desc.isEmpty || cantidad <= 0 || precioUnitario < 0) {
      emit(state.copyWith(error: 'Datos del item manual inválidos'));
      return;
    }
    final igvPorc = state.impuestoPorcentaje;
    final item = VentaDetalleInput(
      // Sin productoId/varianteId/servicioId — el backend lo guarda como
      // detalle puramente descriptivo. Reutilizamos VentaDetalleInput por
      // su lógica de totales (subtotal/igv/total).
      descripcion: desc,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      precioBase: precioUnitario,
      porcentajeIGV: igvPorc,
      // El cajero ingresa el precio FINAL al cliente (estilo POS Perú: el
      // precio en mostrador siempre incluye IGV). Mesa S/800 → total S/800.
      // Si lo dejáramos en `false`, sumaría 18% encima y daría S/944.
      precioIncluyeIgv: true,
      tipoAfectacion: '10',
      icbper: 0,
    );
    emit(state.copyWith(
      items: [...state.items, item],
      clearError: true,
    ));
  }

  /// Agrega varios items manuales de una vez (batch). Eficiente cuando el
  /// cajero compone una lista en el dialog y quiere confirmar todo junto:
  /// emite UN solo state en lugar de N.
  void agregarItemsManuales(
    List<({String descripcion, double cantidad, double precioUnitario})> items,
  ) {
    if (state.tipoCotizacion == TipoCotizacionRapida.paraVenta) {
      emit(state.copyWith(
        error: 'Los items manuales no se permiten en cotización para venta',
      ));
      return;
    }
    if (items.isEmpty) return;
    final igvPorc = state.impuestoPorcentaje;
    final nuevos = <VentaDetalleInput>[];
    for (final i in items) {
      final desc = i.descripcion.trim();
      if (desc.isEmpty || i.cantidad <= 0 || i.precioUnitario < 0) continue;
      nuevos.add(VentaDetalleInput(
        descripcion: desc,
        cantidad: i.cantidad,
        precioUnitario: i.precioUnitario,
        precioBase: i.precioUnitario,
        porcentajeIGV: igvPorc,
        // Mismo criterio que `agregarItemManual`: el precio que ingresa el
        // cajero ya incluye IGV (estilo POS Perú).
        precioIncluyeIgv: true,
        tipoAfectacion: '10',
        icbper: 0,
      ));
    }
    if (nuevos.isEmpty) return;
    emit(state.copyWith(
      items: [...state.items, ...nuevos],
      clearError: true,
    ));
  }

  /// True si el item del carrito es manual (no tiene FK a catálogo).
  bool esItemManual(VentaDetalleInput item) =>
      item.productoId == null &&
      item.varianteId == null &&
      item.servicioId == null;

  // ── Combos (mismo patrón que VR) ──

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

    final hayOfertaActiva = combo.componentes
        .any((c) => c.componenteInfo?.ofertaActiva ?? false);
    if (hayOfertaActiva) {
      emit(state.copyWith(comboPendienteOferta: combo, clearError: true));
      return;
    }

    _expandirYAgregarCombo(combo);
  }

  void confirmarComboPendiente() {
    final combo = state.comboPendienteOferta;
    if (combo == null) return;
    emit(state.copyWith(clearComboPendienteOferta: true));
    _expandirYAgregarCombo(combo);
  }

  void cancelarComboPendiente() {
    emit(state.copyWith(clearComboPendienteOferta: true));
  }

  void _expandirYAgregarCombo(Combo combo) {
    final precioFinal = combo.precioFinal;
    final precioRegularTotal = combo.precioRegularTotal;
    final descuentoTotal =
        (precioRegularTotal - precioFinal).clamp(0, double.infinity).toDouble();
    final igvPorc = state.impuestoPorcentaje;
    final componentes = combo.componentes;

    double descuentoAcumulado = 0;
    final nuevos = <VentaDetalleInput>[];
    for (var i = 0; i < componentes.length; i++) {
      final c = componentes[i];
      final esUltimo = i == componentes.length - 1;
      final precioRegularComponente = c.precioUnitarioRegular;
      final precioRegularTotalComp = precioRegularComponente * c.cantidad;

      double descuentoComponente;
      if (esUltimo) {
        descuentoComponente = descuentoTotal - descuentoAcumulado;
      } else if (precioRegularTotal > 0) {
        descuentoComponente =
            descuentoTotal * (precioRegularTotalComp / precioRegularTotal);
        descuentoComponente = (descuentoComponente * 100).round() / 100.0;
      } else {
        descuentoComponente = descuentoTotal / componentes.length;
        descuentoComponente = (descuentoComponente * 100).round() / 100.0;
      }
      descuentoAcumulado += descuentoComponente;

      nuevos.add(VentaDetalleInput(
        productoId: c.componenteProductoId,
        varianteId: c.componenteVarianteId,
        descripcion: c.nombre,
        cantidad: c.cantidad.toDouble(),
        precioUnitario: precioRegularComponente,
        descuento: descuentoComponente,
        precioBase: precioRegularComponente,
        porcentajeIGV: igvPorc,
        precioIncluyeIgv: true,
        tipoAfectacion: '10',
        icbper: 0,
        stockDisponible: c.stockDisponible,
        origenComboId: combo.id,
        origenComboNombre: combo.nombre,
      ));
    }

    emit(state.copyWith(
      items: [...state.items, ...nuevos],
      clearError: true,
    ));
  }

  // ── Niveles de precio ──

  Future<List<PrecioNivel>> getNivelesProducto(String productoId) =>
      _nivelCacheService.getNiveles(productoId);

  Future<void> _cargarNivelesYActualizar(String productoId) async {
    final niveles = await _nivelCacheService.getNiveles(productoId);
    if (isClosed) return;
    final items = state.items;
    final idx = items.indexWhere((i) => i.productoId == productoId);
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

  // ── Edición carrito ──

  void actualizarCantidad(int index, double cantidad) {
    if (index < 0 || index >= state.items.length) return;
    if (cantidad <= 0) return;
    final actual = state.items[index];
    // Solo cap por stock cuando es item de catálogo (manual no tiene stock).
    final double stockMax =
        actual.stockDisponible?.toDouble() ?? double.infinity;
    final double cantidadFinal = cantidad > stockMax ? stockMax : cantidad;
    final icbperPerUnit =
        actual.cantidad > 0 ? actual.icbper / actual.cantidad : 0.0;
    final nueva = actual
        .recalcularPrecioPorNiveles(cantidadFinal)
        .copyWith(icbper: icbperPerUnit * cantidadFinal);
    final lista = [...state.items];
    lista[index] = nueva;
    emit(state.copyWith(items: lista, clearError: true));
  }

  void actualizarPrecioManual(int index, double precioUnitario) {
    if (index < 0 || index >= state.items.length) return;
    if (precioUnitario < 0) return;
    final actual = state.items[index];
    // Solo permitido editar precio en items manuales; los de catálogo usan niveles.
    if (!esItemManual(actual)) return;
    final lista = [...state.items];
    lista[index] = actual.copyWith(
      precioUnitario: precioUnitario,
      precioBase: precioUnitario,
      clearNivelAplicado: true,
    );
    emit(state.copyWith(items: lista, clearError: true));
  }

  void actualizarDescuento(int index, double porcentaje) {
    if (index < 0 || index >= state.items.length) return;
    final actual = state.items[index];
    final descuentoCalc =
        (actual.cantidad * actual.precioUnitario) * (porcentaje / 100);
    final lista = [...state.items];
    lista[index] = actual.copyWith(descuento: descuentoCalc);
    emit(state.copyWith(items: lista, clearError: true));
  }

  void eliminarItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final lista = [...state.items]..removeAt(index);
    emit(state.copyWith(items: lista, clearError: true));
  }

  void decrementarProducto(String productoId) {
    final idx = state.items.indexWhere(
      (i) => i.productoId == productoId && i.origenComboId == null,
    );
    if (idx < 0) return;
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

  void eliminarCombo(String origenComboId) {
    final lista = state.items
        .where((i) => i.origenComboId != origenComboId)
        .toList();
    emit(state.copyWith(items: lista, clearError: true));
  }

  void vaciarCarrito() {
    emit(state.copyWith(
      items: [],
      clienteGenerico: false,
      clienteId: null,
      clienteEmpresaId: null,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '',
      nombreClienteResuelto: '',
      buscandoCliente: false,
      observaciones: '',
      condiciones: '',
      nombreCotizacion: '',
      clearError: true,
      clearCotizacionCompletada: true,
    ));
  }

  // ── Cliente (mismo patrón que VR) ──

  void setClienteGenerico() {
    emit(state.copyWith(
      clienteGenerico: true,
      clienteId: null,
      clienteEmpresaId: null,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '',
      nombreClienteResuelto: '',
    ));
  }

  void setTipoDocCliente(String tipo) {
    emit(state.copyWith(
      tipoDocCliente: tipo,
      clienteGenerico: false,
      clienteId: null,
      clienteEmpresaId: null,
      nombreClienteResuelto: '',
    ));
  }

  void setNumeroDocCliente(String numero) {
    final invalidar = numero.trim() != state.numeroDocCliente.trim();
    emit(state.copyWith(
      numeroDocCliente: numero,
      clienteGenerico: false,
      clienteId: invalidar ? null : state.clienteId,
      clienteEmpresaId: invalidar ? null : state.clienteEmpresaId,
      nombreClienteResuelto: invalidar ? '' : state.nombreClienteResuelto,
    ));
  }

  Future<void> buscarClientePorDni(String dni) async {
    if (state.buscandoCliente) return;
    final dniLimpio = dni.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(dniLimpio)) {
      emit(state.copyWith(error: 'El DNI debe tener 8 dígitos'));
      return;
    }
    if (dniLimpio == '00000000') {
      emit(state.copyWith(error: 'Para cliente sin documento usá "Genérico"'));
      return;
    }

    final mySeq = ++_searchSeq;
    emit(state.copyWith(buscandoCliente: true, clearError: true));
    final result = await _buscarClientePorDniUseCase(dniLimpio);
    if (isClosed) return;
    if (mySeq != _searchSeq) return;

    if (result is Success<ClienteResueltoDni>) {
      final c = result.data;
      emit(state.copyWith(
        buscandoCliente: false,
        clienteGenerico: false,
        clienteId: c.clienteEmpresaId,
        clienteEmpresaId: null,
        tipoDocCliente: 'DNI',
        numeroDocCliente: c.dni,
        nombreClienteResuelto: c.nombreCompleto,
      ));
    } else if (result is Error<ClienteResueltoDni>) {
      emit(state.copyWith(
        buscandoCliente: false,
        error: result.message,
        nombreClienteResuelto: '',
        clienteId: null,
      ));
    }
  }

  /// Aplica un cliente ya resuelto (típicamente del `ClienteUnificadoSelector`)
  /// al state. Como el bottom sheet ya hizo la búsqueda externa, solo
  /// sincronizamos los campos sin volver a llamar al backend.
  void aplicarClienteResuelto({
    String? clienteId,
    String? clienteEmpresaId,
    required String tipoDocCliente,
    required String numeroDocCliente,
    required String nombreResuelto,
  }) {
    emit(state.copyWith(
      buscandoCliente: false,
      clienteGenerico: false,
      clienteId: clienteId,
      clienteEmpresaId: clienteEmpresaId,
      tipoDocCliente: tipoDocCliente,
      numeroDocCliente: numeroDocCliente,
      nombreClienteResuelto: nombreResuelto,
      clearError: true,
    ));
  }

  Future<void> buscarClientePorRuc(String ruc) async {
    if (state.buscandoCliente) return;
    final rucLimpio = ruc.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(rucLimpio)) {
      emit(state.copyWith(error: 'El RUC debe tener 11 dígitos'));
      return;
    }

    final mySeq = ++_searchSeq;
    emit(state.copyWith(buscandoCliente: true, clearError: true));
    final result = await _buscarClientePorRucUseCase(rucLimpio);
    if (isClosed) return;
    if (mySeq != _searchSeq) return;

    if (result is Success<ClienteResueltoRuc>) {
      final c = result.data;
      emit(state.copyWith(
        buscandoCliente: false,
        clienteGenerico: false,
        clienteId: null,
        clienteEmpresaId: c.clienteEmpresaId,
        tipoDocCliente: 'RUC',
        numeroDocCliente: c.ruc,
        nombreClienteResuelto: c.razonSocial,
      ));
    } else if (result is Error<ClienteResueltoRuc>) {
      emit(state.copyWith(
        buscandoCliente: false,
        error: result.message,
        nombreClienteResuelto: '',
        clienteEmpresaId: null,
      ));
    }
  }

  // ── Datos finalizar ──

  void setFechaVencimiento(DateTime? fecha) {
    emit(state.copyWith(fechaVencimiento: fecha));
  }

  void setNombreCotizacion(String nombre) {
    emit(state.copyWith(nombreCotizacion: nombre));
  }

  void setObservaciones(String texto) {
    emit(state.copyWith(observaciones: texto));
  }

  void setCondiciones(String texto) {
    emit(state.copyWith(condiciones: texto));
  }

  // ── Crear cotización ──

  Future<void> crearCotizacion() async {
    if (state.procesando) return;
    if (state.items.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un item'));
      return;
    }
    if (state.sedeId == null || state.vendedorId == null) {
      emit(state.copyWith(error: 'Falta contexto de sede/vendedor'));
      return;
    }

    emit(state.copyWith(procesando: true, clearError: true));

    final docTipeado = state.numeroDocCliente.trim();
    final tieneClienteRucResuelto = state.clienteEmpresaId != null &&
        state.nombreClienteResuelto.isNotEmpty &&
        docTipeado.isNotEmpty;
    final tieneClienteDniResuelto = !tieneClienteRucResuelto &&
        state.clienteId != null &&
        state.nombreClienteResuelto.isNotEmpty &&
        docTipeado.isNotEmpty;
    final esGenerico = !tieneClienteRucResuelto &&
        !tieneClienteDniResuelto &&
        (state.clienteGenerico || docTipeado.isEmpty);

    final nombreCliente = esGenerico
        ? 'CLIENTES VARIOS'
        : ((tieneClienteRucResuelto || tieneClienteDniResuelto)
            ? state.nombreClienteResuelto
            : docTipeado);

    final data = <String, dynamic>{
      'sedeId': state.sedeId,
      'vendedorId': state.vendedorId,
      // Solo `clienteId` (EmpresaPersona). El backend NO acepta
      // `clienteEmpresaId` en el DTO actual; los datos del cliente B2B
      // resuelto por RUC quedan como snapshot (`nombreCliente, documentoCliente`).
      if (tieneClienteDniResuelto && state.clienteId != null)
        'clienteId': state.clienteId,
      'nombreCliente': nombreCliente,
      if (docTipeado.isNotEmpty) 'documentoCliente': docTipeado,
      'moneda': state.moneda,
      if (state.fechaVencimiento != null)
        'fechaVencimiento': state.fechaVencimiento!.toIso8601String(),
      if (state.nombreCotizacion.trim().isNotEmpty)
        'nombre': state.nombreCotizacion.trim(),
      if (state.observaciones.trim().isNotEmpty)
        'observaciones': state.observaciones.trim(),
      if (state.condiciones.trim().isNotEmpty)
        'condiciones': state.condiciones.trim(),
      'detalles': state.items.map((item) => item.toMap()).toList(),
      // Reserva de stock + adelanto. Solo aplica en modo PARA_VENTA;
      // el setter `setTipoCotizacion('SIMPLE')` ya limpió estos flags
      // si el usuario cambió de modo.
      if (state.reservarStock) 'reservarStock': true,
      if (state.adelantoMonto > 0) 'adelantoMonto': state.adelantoMonto,
      if (state.adelantoMonto > 0 && state.cajaIdAdelanto != null)
        'cajaId': state.cajaIdAdelanto,
    };

    final result = await _crearCotizacionUseCase(data: data);
    if (isClosed) return;

    if (result is Success<Cotizacion>) {
      emit(state.copyWith(
        procesando: false,
        cotizacionCompletadaId: result.data.id,
      ));
    } else if (result is Error<Cotizacion>) {
      emit(state.copyWith(
        procesando: false,
        error: result.message,
      ));
    }
  }

  // ── Edición ──

  /// Carga una cotización existente al state para editar sus items.
  /// El cubit pasa a `modoEdicion=true`. Solo se permite editar si la
  /// cotización está en BORRADOR (validación final del backend).
  ///
  /// El campo `precioIncluyeIgv` se infiere por aritmética (no se
  /// persiste en BD): si `cantidad·precioUnitario − descuento ≈ total`,
  /// el precio ya incluye IGV; si no, se le sumó IGV encima.
  void cargarParaEdicion(Cotizacion cot) {
    final detalles = cot.detalles ?? const <CotizacionDetalle>[];
    final items = detalles.map((d) {
      final subtotalBruto = d.cantidad * d.precioUnitario - d.descuento;
      final totalSinIcbper = d.total - d.icbper;
      final incluyeIgv = (subtotalBruto - totalSinIcbper).abs() < 0.5;
      return VentaDetalleInput(
        productoId: d.productoId,
        varianteId: d.varianteId,
        servicioId: d.servicioId,
        descripcion: d.descripcion,
        cantidad: d.cantidad,
        precioUnitario: d.precioUnitario,
        precioBase: d.precioUnitario,
        descuento: d.descuento,
        porcentajeIGV: d.porcentajeIGV,
        precioIncluyeIgv: incluyeIgv,
        tipoAfectacion: d.tipoAfectacion,
        icbper: d.icbper,
      );
    }).toList();

    // Inferir tipo: si todos los items tienen FK a catálogo, PARA_VENTA;
    // si hay alguno manual, SIMPLE.
    final hayManual = items.any((i) =>
        i.productoId == null &&
        i.varianteId == null &&
        i.servicioId == null);
    final tipo = hayManual
        ? TipoCotizacionRapida.simple
        : TipoCotizacionRapida.paraVenta;

    emit(state.copyWith(
      items: items,
      modoEdicion: true,
      cotizacionEditandoId: cot.id,
      tipoCotizacion: tipo,
      moneda: cot.moneda,
      nombreCotizacion: cot.nombre ?? '',
      observaciones: cot.observaciones ?? '',
      condiciones: cot.condiciones ?? '',
      fechaVencimiento: cot.fechaVencimiento,
      clienteId: cot.clienteId,
      // `Cotizacion` (entity Flutter) no expone clienteEmpresaId — el
      // backend solo persiste clienteId. Si el cliente fue B2B, los datos
      // viven en los snapshots (nombreCliente, documentoCliente).
      numeroDocCliente: cot.documentoCliente ?? '',
      nombreClienteResuelto: cot.nombreCliente,
      tipoDocCliente: (cot.documentoCliente?.length == 11) ? 'RUC' : 'DNI',
      clearError: true,
      clearCotizacionCompletada: true,
    ));
  }

  /// Guarda los cambios de items vía PUT /cotizaciones/:id. Solo manda
  /// `detalles` (no toca cliente/fecha/observaciones — para eso está el
  /// stepper viejo). El backend rechaza si la cotización ya no está en
  /// BORRADOR.
  Future<void> guardarEdicion() async {
    if (state.procesando) return;
    if (!state.modoEdicion || state.cotizacionEditandoId == null) {
      emit(state.copyWith(error: 'No hay cotización en modo edición'));
      return;
    }
    if (state.items.isEmpty) {
      emit(state.copyWith(
        error: 'La cotización debe tener al menos un item'));
      return;
    }

    emit(state.copyWith(procesando: true, clearError: true));

    final data = <String, dynamic>{
      'detalles': state.items.map((it) => it.toMap()).toList(),
    };

    final result = await _actualizarCotizacionUseCase(
      cotizacionId: state.cotizacionEditandoId!,
      data: data,
    );
    if (isClosed) return;

    if (result is Success<Cotizacion>) {
      emit(state.copyWith(
        procesando: false,
        cotizacionCompletadaId: result.data.id,
      ));
    } else if (result is Error<Cotizacion>) {
      emit(state.copyWith(
        procesando: false,
        error: result.message,
      ));
    }
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  void resetCompletada() {
    emit(state.copyWith(
      items: [],
      clienteGenerico: false,
      clienteId: null,
      clienteEmpresaId: null,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '',
      nombreClienteResuelto: '',
      buscandoCliente: false,
      observaciones: '',
      condiciones: '',
      nombreCotizacion: '',
      tipoCotizacion: TipoCotizacionRapida.simple,
      modoEdicion: false,
      // Reset de flags de reserva — el switch debe volver a OFF al
      // empezar una cotización nueva tras completar la anterior.
      reservarStock: false,
      adelantoMonto: 0,
      clearCajaIdAdelanto: true,
      clearCotizacionEditandoId: true,
      clearError: true,
      clearCotizacionCompletada: true,
    ));
  }

  // ── Sync realtime del carrito (capa 1: FCM data-only) ──
  //
  // Réplica del patrón del VR cubit: si llega FCM (precio/stock/niveles/
  // producto_actualizado) y el productoId está en el carrito de la
  // cotización, re-fetch niveles + precio + stock por sede. Sin esto,
  // los items quedaban con el precio viejo hasta que el cajero enviaba
  // la cotización (y el backend la guardaba con datos stale).
  //
  // Items combo (`origenComboId != null`) NO se tocan — el precio del
  // combo se prorratea al armarlo.

  StreamSubscription<RealtimeEvent>? _realtimeSub;
  Timer? _realtimeDebounce;
  final Set<String> _pendingProductoIds = {};
  bool _pendingSyncAll = false;
  int _syncSeq = 0;

  void _suscribirRealtime() {
    _realtimeSub = _realtimeSync.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    // Mientras se procesa el envío de la cotización NO tocamos el carrito.
    if (state.procesando) return;

    final evtEmpresaId = _empresaIdFromEvent(event);
    final evtSedeId = _sedeIdFromEvent(event);
    final evtProductoId = _productoIdFromEvent(event);

    // Filtrado defensivo por empresa y sede del carrito.
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
    if (e is RealtimeProductoActualizado) return e.empresaId;
    return null;
  }

  String? _sedeIdFromEvent(RealtimeEvent e) {
    if (e is RealtimePrecioCambiado) return e.sedeId;
    if (e is RealtimeStockCambiado) return e.sedeId;
    return null; // niveles y PRODUCTO_ACTUALIZADO no son por sede
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

  Future<void> _sincronizarItemsCarrito(
    Set<String> productoIds,
    bool syncAll,
  ) async {
    final items = state.items;
    if (items.isEmpty) return;

    final mySeq = ++_syncSeq;

    // Items afectados: filtramos por productoId (excluyendo combos e
    // items manuales sin productoId).
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

    // 1. Invalidar y refetch niveles (idempotente).
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

    // 3. Aplicar nuevos valores a cada item afectado.
    final nuevos = [...state.items];
    var huboCambios = false;
    for (final idx in afectados) {
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
    emit(state.copyWith(items: nuevos));
  }

  @override
  Future<void> close() {
    _realtimeDebounce?.cancel();
    _realtimeSub?.cancel();
    return super.close();
  }
}
