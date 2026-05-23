part of 'cotizacion_rapida_cubit.dart';

class CotizacionRapidaState extends Equatable {
  // Contexto
  final String? empresaId;
  final String? sedeId;
  final String? vendedorId;
  final double impuestoPorcentaje;
  final String moneda;

  /// SIMPLE | PARA_VENTA — solo client-side, gobierna la UI.
  final String tipoCotizacion;

  // Carrito (mismos items que VR; los manuales tienen productoId == null)
  final List<VentaDetalleInput> items;

  // Cliente
  final bool clienteGenerico;
  /// Id de EmpresaPersona (cliente persona natural por DNI o genérico).
  final String? clienteId;
  /// Id de ClienteEmpresa (cliente B2B por RUC). Por ahora SOLO se usa
  /// client-side: el DTO `CreateCotizacionDto` no lo acepta, los datos del
  /// cliente jurídico se persisten como snapshot (`nombreCliente, documento...`).
  final String? clienteEmpresaId;
  final String tipoDocCliente; // DNI | RUC | CE | PASAPORTE
  final String numeroDocCliente;
  final String nombreClienteResuelto;
  final bool buscandoCliente;

  // Datos finalizar
  final String nombreCotizacion;
  final DateTime? fechaVencimiento;
  final String observaciones;
  final String condiciones;

  // Edición
  /// True cuando estamos editando una cotización existente (no creando una
  /// nueva). Cambia el comportamiento del botón en el carrito y la pantalla
  /// principal de productos.
  final bool modoEdicion;
  /// Id de la cotización que se está editando. Solo válido si `modoEdicion=true`.
  final String? cotizacionEditandoId;

  // Reserva de stock + pago adelantado (solo aplica a modo PARA_VENTA).
  /// Si `true`, el backend reserva el stock de los items del catálogo.
  /// Se libera automáticamente al anular/expirar/convertir.
  final bool reservarStock;

  /// Monto del pago adelantado del cliente (puede ser 0). Se registra
  /// como MovimientoCaja(ADELANTO_COTIZACION) en la caja del cajero.
  final double adelantoMonto;

  /// ID de la caja activa donde se registra el adelanto. Requerido si
  /// `adelantoMonto > 0`.
  final String? cajaIdAdelanto;

  // Estado UI
  final bool procesando;
  final String? error;
  final String? cotizacionCompletadaId;

  /// Combo cargado y pendiente de confirmación porque tiene componentes en
  /// oferta. Mismo patrón que VR.
  final Combo? comboPendienteOferta;

  const CotizacionRapidaState({
    this.empresaId,
    this.sedeId,
    this.vendedorId,
    this.impuestoPorcentaje = 18.0,
    this.moneda = 'PEN',
    this.tipoCotizacion = 'SIMPLE',
    this.items = const [],
    this.clienteGenerico = false,
    this.clienteId,
    this.clienteEmpresaId,
    this.tipoDocCliente = 'DNI',
    this.numeroDocCliente = '',
    this.nombreClienteResuelto = '',
    this.buscandoCliente = false,
    this.nombreCotizacion = '',
    this.fechaVencimiento,
    this.observaciones = '',
    this.condiciones = '',
    this.modoEdicion = false,
    this.cotizacionEditandoId,
    this.reservarStock = false,
    this.adelantoMonto = 0,
    this.cajaIdAdelanto,
    this.procesando = false,
    this.error,
    this.cotizacionCompletadaId,
    this.comboPendienteOferta,
  });

  // Totales
  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get igv => items.fold(0, (sum, i) => sum + i.igv);
  double get icbper => items.fold(0, (sum, i) => sum + i.icbper);
  double get total => items.fold(0, (sum, i) => sum + i.total);
  int get cantidadItems => items.length;
  int get cantidadUnidades =>
      items.fold(0, (sum, i) => sum + i.cantidad.toInt());

  /// True si la cotización es convertible directamente a venta (todos los
  /// items son de catálogo, sin manuales). El backend usa este criterio
  /// implícitamente — un item sin productoId no tiene stock que descontar.
  bool get esConvertibleAVenta =>
      items.isNotEmpty &&
      items.every((i) =>
          i.productoId != null ||
          i.varianteId != null ||
          i.servicioId != null);

  CotizacionRapidaState copyWith({
    String? empresaId,
    String? sedeId,
    String? vendedorId,
    double? impuestoPorcentaje,
    String? moneda,
    String? tipoCotizacion,
    List<VentaDetalleInput>? items,
    bool? clienteGenerico,
    String? clienteId,
    String? clienteEmpresaId,
    String? tipoDocCliente,
    String? numeroDocCliente,
    String? nombreClienteResuelto,
    bool? buscandoCliente,
    String? nombreCotizacion,
    DateTime? fechaVencimiento,
    String? observaciones,
    String? condiciones,
    bool? modoEdicion,
    String? cotizacionEditandoId,
    bool clearCotizacionEditandoId = false,
    bool? reservarStock,
    double? adelantoMonto,
    String? cajaIdAdelanto,
    bool clearCajaIdAdelanto = false,
    bool? procesando,
    String? error,
    bool clearError = false,
    String? cotizacionCompletadaId,
    bool clearCotizacionCompletada = false,
    Combo? comboPendienteOferta,
    bool clearComboPendienteOferta = false,
  }) {
    return CotizacionRapidaState(
      empresaId: empresaId ?? this.empresaId,
      sedeId: sedeId ?? this.sedeId,
      vendedorId: vendedorId ?? this.vendedorId,
      impuestoPorcentaje: impuestoPorcentaje ?? this.impuestoPorcentaje,
      moneda: moneda ?? this.moneda,
      tipoCotizacion: tipoCotizacion ?? this.tipoCotizacion,
      items: items ?? this.items,
      clienteGenerico: clienteGenerico ?? this.clienteGenerico,
      clienteId: clienteId ?? this.clienteId,
      clienteEmpresaId: clienteEmpresaId ?? this.clienteEmpresaId,
      tipoDocCliente: tipoDocCliente ?? this.tipoDocCliente,
      numeroDocCliente: numeroDocCliente ?? this.numeroDocCliente,
      nombreClienteResuelto:
          nombreClienteResuelto ?? this.nombreClienteResuelto,
      buscandoCliente: buscandoCliente ?? this.buscandoCliente,
      nombreCotizacion: nombreCotizacion ?? this.nombreCotizacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      observaciones: observaciones ?? this.observaciones,
      condiciones: condiciones ?? this.condiciones,
      modoEdicion: modoEdicion ?? this.modoEdicion,
      cotizacionEditandoId: clearCotizacionEditandoId
          ? null
          : (cotizacionEditandoId ?? this.cotizacionEditandoId),
      reservarStock: reservarStock ?? this.reservarStock,
      adelantoMonto: adelantoMonto ?? this.adelantoMonto,
      cajaIdAdelanto: clearCajaIdAdelanto
          ? null
          : (cajaIdAdelanto ?? this.cajaIdAdelanto),
      procesando: procesando ?? this.procesando,
      error: clearError ? null : (error ?? this.error),
      cotizacionCompletadaId: clearCotizacionCompletada
          ? null
          : (cotizacionCompletadaId ?? this.cotizacionCompletadaId),
      comboPendienteOferta: clearComboPendienteOferta
          ? null
          : (comboPendienteOferta ?? this.comboPendienteOferta),
    );
  }

  @override
  List<Object?> get props => [
        empresaId, sedeId, vendedorId, impuestoPorcentaje, moneda,
        tipoCotizacion, items,
        clienteGenerico, clienteId, clienteEmpresaId, tipoDocCliente,
        numeroDocCliente, nombreClienteResuelto, buscandoCliente,
        nombreCotizacion, fechaVencimiento, observaciones, condiciones,
        modoEdicion, cotizacionEditandoId,
        reservarStock, adelantoMonto, cajaIdAdelanto,
        procesando, error, cotizacionCompletadaId, comboPendienteOferta,
      ];
}
