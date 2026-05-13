import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../../combo/domain/entities/combo.dart';
import '../../../combo/domain/repositories/combo_repository.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/services/precio_nivel_cache_service.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
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

  VentaRapidaCubit(
    this._cobrarUseCase,
    this._obtenerClienteGenericoUseCase,
    this._buscarClientePorDniUseCase,
    this._buscarClientePorRucUseCase,
    this._nivelCacheService,
    this._comboRepository,
  ) : super(const VentaRapidaState());

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
    final precioFinal = combo.precioFinal;
    final precioRegularTotal = combo.precioRegularTotal;
    final descuentoTotal = (precioRegularTotal - precioFinal).clamp(0, double.infinity).toDouble();
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
        // El último compensa el redondeo: completa el descuento total.
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
    final idx = items.indexWhere((i) => i.productoId == productoId);
    if (idx < 0) return; // item ya no está en el carrito
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
    // Cap al stock disponible para no permitir vender más de lo que hay
    // (el backend lo rechazaría al cobrar; mejor frenar acá).
    final double stockMax = actual.stockDisponible?.toDouble() ?? double.infinity;
    final double cantidadFinal = cantidad > stockMax ? stockMax : cantidad;
    // ICBPER es per-unit: lo derivamos del valor previo y reescalamos a la
    // nueva cantidad (consistente con `decrementarProducto`).
    final icbperPerUnit =
        actual.cantidad > 0 ? actual.icbper / actual.cantidad : 0.0;
    final nueva = actual
        .recalcularPrecioPorNiveles(cantidadFinal)
        .copyWith(icbper: icbperPerUnit * cantidadFinal);
    final lista = [...state.items];
    lista[index] = nueva;
    emit(state.copyWith(items: lista, clearError: true));
  }

  void actualizarDescuento(int index, double porcentaje) {
    if (index < 0 || index >= state.items.length) return;
    final actual = state.items[index];
    final descuentoCalc = (actual.cantidad * actual.precioUnitario) * (porcentaje / 100);
    final nueva = VentaDetalleInput(
      productoId: actual.productoId,
      descripcion: actual.descripcion,
      cantidad: actual.cantidad,
      precioUnitario: actual.precioUnitario,
      descuento: descuentoCalc,
      porcentajeIGV: actual.porcentajeIGV,
      precioIncluyeIgv: actual.precioIncluyeIgv,
      tipoAfectacion: actual.tipoAfectacion,
      icbper: actual.icbper,
      stockDisponible: actual.stockDisponible,
    );
    final lista = [...state.items];
    lista[index] = nueva;
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
      (i) => i.productoId == productoId && i.origenComboId == null,
    );
    if (idx < 0) return;
    final actual = state.items[idx];
    if (actual.cantidad <= 1) {
      eliminarItem(idx);
      return;
    }
    final nuevaCantidad = actual.cantidad - 1;
    // Mantener icbper proporcional a la cantidad.
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
    emit(state.copyWith(
      items: [],
      pagos: [],
      tipoComprobante: 'TICKET',
      clienteGenerico: false,
      clienteId: null,
      clienteEmpresaId: null,
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
    // Las facturas SUNAT solo se emiten contra RUC. Si el cajero pasa a
    // FACTURA y el tipo de documento previo no era RUC, lo forzamos y
    // limpiamos el cliente resuelto (DNI ya no aplica).
    if (tipo == 'FACTURA' && state.tipoDocCliente != 'RUC') {
      emit(state.copyWith(
        tipoComprobante: tipo,
        tipoDocCliente: 'RUC',
        clienteGenerico: false,
        clienteId: null,
        clienteEmpresaId: null,
        numeroDocCliente: '',
        nombreClienteResuelto: '',
      ));
      return;
    }
    emit(state.copyWith(tipoComprobante: tipo));
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
      clienteId: null,
      clienteEmpresaId: null,
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
      clienteId: invalidar ? null : state.clienteId,
      clienteEmpresaId: invalidar ? null : state.clienteEmpresaId,
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

  /// Busca un cliente empresa (B2B) por RUC vía SUNAT.
  /// Pre-llena `clienteEmpresaId` y `nombreClienteResuelto` (= razón social).
  Future<void> buscarClientePorRuc(String ruc) async {
    if (state.buscandoCliente) return; // guard de re-entrada
    final rucLimpio = ruc.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(rucLimpio)) {
      emit(state.copyWith(error: 'El RUC debe tener 11 dígitos'));
      return;
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

  // ── Cobrar ──

  Future<void> cobrar({bool aceptaRiesgoBancarizacion = false}) async {
    // Guard de re-entrada: evita doble-cobro si el cajero da doble-tap
    // antes de que el botón se deshabilite por rebuild.
    if (state.procesando) return;
    if (state.items.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un producto'));
      return;
    }
    if (state.pagos.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un pago'));
      return;
    }
    if (state.totalPagado + _kPenPaymentTolerance < state.total) {
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
      'esCredito': false,
      if (aceptaRiesgoBancarizacion) 'aceptaRiesgoBancarizacion': true,
      'metodoPago': state.pagos.first['metodo'],
      'montoRecibido': state.totalPagado,
      'pagos': state.pagos.map((p) => {
            'metodoPago': p['metodo'],
            'monto': p['monto'],
            if (p['banco'] != null) 'banco': p['banco'],
            if (p['referencia'] != null) 'referencia': p['referencia'],
          }).toList(),
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
      // Si el backend rechazó la venta porque el precio cambió, exponer
      // las divergencias en el state para que la UI muestre dialog con
      // botón "Refrescar carrito" en vez de un snackbar de error genérico.
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

    // 3. Aplicar nuevo precio base + nuevos niveles a cada item. Después
    //    recalcular `precioUnitario` con la cantidad actual usando los
    //    niveles nuevos.
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

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  void resetCompletada() {
    emit(state.copyWith(
      items: [],
      pagos: [],
      tipoComprobante: 'TICKET',
      clienteGenerico: false,
      clienteId: null,
      clienteEmpresaId: null,
      tipoDocCliente: 'DNI',
      numeroDocCliente: '',
      nombreClienteResuelto: '',
      buscandoCliente: false,
      clearError: true,
      clearVentaCompletada: true,
    ));
  }
}
