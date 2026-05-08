part of 'venta_rapida_cubit.dart';

class VentaRapidaState extends Equatable {
  // Contexto
  final String? empresaId;
  final String? sedeId;
  final String? vendedorId;
  final double impuestoPorcentaje;
  final String moneda;

  // Carrito
  final List<VentaDetalleInput> items;

  // Comprobante / Cliente
  final String tipoComprobante; // TICKET | BOLETA | FACTURA
  final bool clienteGenerico;
  /// Id de EmpresaPersona (cliente persona natural por DNI o genérico).
  final String? clienteId;
  /// Id de ClienteEmpresa (cliente B2B por RUC). Se setea al resolver vía SUNAT.
  final String? clienteEmpresaId;
  final String tipoDocCliente; // DNI | RUC | CE | PASAPORTE
  final String numeroDocCliente;
  /// Nombre completo o razón social del cliente resuelto via RENIEC/SUNAT.
  /// Vacío si no se buscó o si es genérico. Se muestra en la UI.
  final String nombreClienteResuelto;
  /// True mientras se está consultando el DNI/RUC (externo + upsert backend).
  final bool buscandoCliente;

  // Pagos
  final List<Map<String, dynamic>> pagos;

  // Estado UI
  final bool procesando;
  final String? error;
  final String? ventaCompletadaId;

  /// Combo cargado y pendiente de confirmación porque tiene componentes en
  /// oferta. La UI debe mostrar un dialog antes de expandirlo. Si el cajero
  /// confirma → `confirmarComboPendiente()`. Si cancela → `cancelarComboPendiente()`.
  final Combo? comboPendienteOferta;

  const VentaRapidaState({
    this.empresaId,
    this.sedeId,
    this.vendedorId,
    this.impuestoPorcentaje = 18.0,
    this.moneda = 'PEN',
    this.items = const [],
    this.tipoComprobante = 'TICKET',
    this.clienteGenerico = false,
    this.clienteId,
    this.clienteEmpresaId,
    this.tipoDocCliente = 'DNI',
    this.numeroDocCliente = '',
    this.nombreClienteResuelto = '',
    this.buscandoCliente = false,
    this.pagos = const [],
    this.procesando = false,
    this.error,
    this.ventaCompletadaId,
    this.comboPendienteOferta,
  });

  // Totales calculados
  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get igv => items.fold(0, (sum, i) => sum + i.igv);
  double get icbper => items.fold(0, (sum, i) => sum + i.icbper);
  double get total => items.fold(0, (sum, i) => sum + i.total);
  /// Número de líneas distintas en el carrito.
  int get cantidadItems => items.length;
  /// Suma de unidades de todos los productos en el carrito (para el badge UX).
  int get cantidadUnidades =>
      items.fold(0, (sum, i) => sum + i.cantidad.toInt());
  double get totalPagado => pagos.fold(0.0, (sum, p) => sum + ((p['monto'] as num).toDouble()));
  double get vuelto {
    final v = totalPagado - total;
    return v > 0 ? v : 0;
  }

  VentaRapidaState copyWith({
    String? empresaId,
    String? sedeId,
    String? vendedorId,
    double? impuestoPorcentaje,
    String? moneda,
    List<VentaDetalleInput>? items,
    String? tipoComprobante,
    bool? clienteGenerico,
    String? clienteId,
    String? clienteEmpresaId,
    String? tipoDocCliente,
    String? numeroDocCliente,
    String? nombreClienteResuelto,
    bool? buscandoCliente,
    List<Map<String, dynamic>>? pagos,
    bool? procesando,
    String? error,
    bool clearError = false,
    String? ventaCompletadaId,
    bool clearVentaCompletada = false,
    Combo? comboPendienteOferta,
    bool clearComboPendienteOferta = false,
  }) {
    return VentaRapidaState(
      empresaId: empresaId ?? this.empresaId,
      sedeId: sedeId ?? this.sedeId,
      vendedorId: vendedorId ?? this.vendedorId,
      impuestoPorcentaje: impuestoPorcentaje ?? this.impuestoPorcentaje,
      moneda: moneda ?? this.moneda,
      items: items ?? this.items,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      clienteGenerico: clienteGenerico ?? this.clienteGenerico,
      clienteId: clienteId ?? this.clienteId,
      clienteEmpresaId: clienteEmpresaId ?? this.clienteEmpresaId,
      tipoDocCliente: tipoDocCliente ?? this.tipoDocCliente,
      numeroDocCliente: numeroDocCliente ?? this.numeroDocCliente,
      nombreClienteResuelto: nombreClienteResuelto ?? this.nombreClienteResuelto,
      buscandoCliente: buscandoCliente ?? this.buscandoCliente,
      pagos: pagos ?? this.pagos,
      procesando: procesando ?? this.procesando,
      error: clearError ? null : (error ?? this.error),
      ventaCompletadaId: clearVentaCompletada
          ? null
          : (ventaCompletadaId ?? this.ventaCompletadaId),
      comboPendienteOferta: clearComboPendienteOferta
          ? null
          : (comboPendienteOferta ?? this.comboPendienteOferta),
    );
  }

  @override
  List<Object?> get props => [
        empresaId, sedeId, vendedorId, impuestoPorcentaje, moneda,
        items, tipoComprobante, clienteGenerico, clienteId, clienteEmpresaId,
        tipoDocCliente, numeroDocCliente, nombreClienteResuelto, buscandoCliente,
        pagos, procesando, error, ventaCompletadaId, comboPendienteOferta,
      ];
}
