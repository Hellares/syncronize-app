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

  /// Documento (DNI/RUC) buscado que NO existe ni en el catálogo local ni
  /// en el sistema/API externa. Cuando no es null, la UI abre el
  /// ClienteUnificadoSelector en modo registro pre-llenado y luego lo
  /// limpia con `limpiarDocSinResultado()`.
  final String? docSinResultado;

  // Crédito
  final String condicionPago; // CONTADO | CREDITO
  final int numeroCuotas;
  final int plazoDias;

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

  /// Lista de productos cuyo precio cambió en el backend entre el momento
  /// que el cajero los agregó al carrito y el momento del cobro. Cuando
  /// no es null, la UI muestra un dialog con la lista (precio viejo vs
  /// nuevo) y pide refrescar antes de reintentar.
  ///
  /// Cada item: {descripcion, productoId?, varianteId?, comboId?, cantidad,
  /// precioCliente, precioServer, nivelAplicado?}.
  final List<Map<String, dynamic>>? preciosDesactualizados;

  /// Lista de productos sin stock suficiente al momento del cobro
  /// (otro cajero los vendió, hubo merma, transferencia, etc).
  ///
  /// Cada item: {descripcion, productoId?, varianteId?, comboId?,
  /// cantidadSolicitada, stockDisponible}.
  final List<Map<String, dynamic>>? stockInsuficiente;

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
    this.docSinResultado,
    this.condicionPago = 'CONTADO',
    this.numeroCuotas = 1,
    this.plazoDias = 30,
    this.pagos = const [],
    this.procesando = false,
    this.error,
    this.ventaCompletadaId,
    this.comboPendienteOferta,
    this.preciosDesactualizados,
    this.stockInsuficiente,
  });

  // Totales calculados
  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get descuentoTotal => items.fold(0.0, (sum, i) => sum + i.descuento);
  double get igv => items.fold(0, (sum, i) => sum + i.igv);
  double get icbper => items.fold(0, (sum, i) => sum + i.icbper);
  double get total => items.fold(0, (sum, i) => sum + i.total);
  /// Número de líneas distintas en el carrito.
  int get cantidadItems => items.length;
  /// Suma de unidades de todos los productos en el carrito (para el badge UX).
  int get cantidadUnidades =>
      items.fold(0, (sum, i) => sum + i.cantidad.toInt());
  bool get esCredito => condicionPago == 'CREDITO';

  /// Adelantos ya pagados de las órdenes de servicio en el carrito. El
  /// `total` es por el TOTAL de los servicios (el comprobante se emite
  /// completo); HOY el cliente paga `totalACobrar` = total − adelantos.
  double get adelantoAplicado =>
      items.fold(0.0, (sum, i) => sum + i.ordenAdelanto);

  /// Lo que el cliente debe pagar HOY (total − adelantos aplicados).
  double get totalACobrar {
    final t = total - adelantoAplicado;
    return t > 0 ? t : 0;
  }

  double get totalPagado => pagos.fold(0.0, (sum, p) => sum + ((p['monto'] as num).toDouble()));
  double get vuelto {
    final v = totalPagado - totalACobrar;
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
    bool clearClienteId = false,
    String? clienteEmpresaId,
    bool clearClienteEmpresaId = false,
    String? tipoDocCliente,
    String? numeroDocCliente,
    String? nombreClienteResuelto,
    bool? buscandoCliente,
    String? docSinResultado,
    bool clearDocSinResultado = false,
    String? condicionPago,
    int? numeroCuotas,
    int? plazoDias,
    List<Map<String, dynamic>>? pagos,
    bool? procesando,
    String? error,
    bool clearError = false,
    String? ventaCompletadaId,
    bool clearVentaCompletada = false,
    Combo? comboPendienteOferta,
    bool clearComboPendienteOferta = false,
    List<Map<String, dynamic>>? preciosDesactualizados,
    bool clearPreciosDesactualizados = false,
    List<Map<String, dynamic>>? stockInsuficiente,
    bool clearStockInsuficiente = false,
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
      // Clear flags: el patrón `?? this.x` no permite limpiar con null —
      // cambiar de cliente persona→empresa dejaba AMBOS ids seteados.
      clienteId: clearClienteId ? null : (clienteId ?? this.clienteId),
      clienteEmpresaId: clearClienteEmpresaId
          ? null
          : (clienteEmpresaId ?? this.clienteEmpresaId),
      tipoDocCliente: tipoDocCliente ?? this.tipoDocCliente,
      numeroDocCliente: numeroDocCliente ?? this.numeroDocCliente,
      nombreClienteResuelto: nombreClienteResuelto ?? this.nombreClienteResuelto,
      buscandoCliente: buscandoCliente ?? this.buscandoCliente,
      docSinResultado: clearDocSinResultado
          ? null
          : (docSinResultado ?? this.docSinResultado),
      condicionPago: condicionPago ?? this.condicionPago,
      numeroCuotas: numeroCuotas ?? this.numeroCuotas,
      plazoDias: plazoDias ?? this.plazoDias,
      pagos: pagos ?? this.pagos,
      procesando: procesando ?? this.procesando,
      error: clearError ? null : (error ?? this.error),
      ventaCompletadaId: clearVentaCompletada
          ? null
          : (ventaCompletadaId ?? this.ventaCompletadaId),
      comboPendienteOferta: clearComboPendienteOferta
          ? null
          : (comboPendienteOferta ?? this.comboPendienteOferta),
      preciosDesactualizados: clearPreciosDesactualizados
          ? null
          : (preciosDesactualizados ?? this.preciosDesactualizados),
      stockInsuficiente: clearStockInsuficiente
          ? null
          : (stockInsuficiente ?? this.stockInsuficiente),
    );
  }

  @override
  List<Object?> get props => [
        empresaId, sedeId, vendedorId, impuestoPorcentaje, moneda,
        items, tipoComprobante, clienteGenerico, clienteId, clienteEmpresaId,
        tipoDocCliente, numeroDocCliente, nombreClienteResuelto, buscandoCliente,
        docSinResultado,
        condicionPago, numeroCuotas, plazoDias,
        pagos, procesando, error, ventaCompletadaId, comboPendienteOferta,
        preciosDesactualizados, stockInsuficiente,
      ];
}
