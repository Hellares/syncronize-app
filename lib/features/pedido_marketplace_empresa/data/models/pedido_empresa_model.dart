import '../../domain/entities/pedido_empresa.dart';

class PedidoMarketplaceEmpresaModel {
  final String id;
  final String codigo;
  final String estado;
  final String nombreComprador;
  final String? emailComprador;
  final String? telefonoComprador;
  final double total;
  final String? direccionEnvio;
  final String? referenciaEnvio;
  final String? distritoEnvio;
  final String? provinciaEnvio;
  final String? departamentoEnvio;
  final Map<String, dynamic>? coordenadasEnvio;
  final String? metodoPago;
  final String? comprobantePagoUrl;
  final String? motivoRechazo;
  final String? codigoSeguimiento;
  final List<PedidoItemModel> detalles;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const PedidoMarketplaceEmpresaModel({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.nombreComprador,
    this.emailComprador,
    this.telefonoComprador,
    required this.total,
    this.direccionEnvio,
    this.referenciaEnvio,
    this.distritoEnvio,
    this.provinciaEnvio,
    this.departamentoEnvio,
    this.coordenadasEnvio,
    this.metodoPago,
    this.comprobantePagoUrl,
    this.motivoRechazo,
    this.codigoSeguimiento,
    required this.detalles,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory PedidoMarketplaceEmpresaModel.fromJson(Map<String, dynamic> json) {
    return PedidoMarketplaceEmpresaModel(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      nombreComprador: json['nombreComprador'] as String? ?? '',
      emailComprador: json['emailComprador'] as String?,
      telefonoComprador: json['telefonoComprador'] as String?,
      total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
      direccionEnvio: json['direccionEnvio'] as String?,
      referenciaEnvio: json['referenciaEnvio'] as String?,
      distritoEnvio: json['distritoEnvio'] as String?,
      provinciaEnvio: json['provinciaEnvio'] as String?,
      departamentoEnvio: json['departamentoEnvio'] as String?,
      coordenadasEnvio: json['coordenadasEnvio'] as Map<String, dynamic>?,
      metodoPago: json['metodoPago'] as String?,
      comprobantePagoUrl: json['comprobantePagoUrl'] as String?,
      motivoRechazo: json['motivoRechazo'] as String?,
      codigoSeguimiento: json['codigoSeguimiento'] as String?,
      detalles: (json['detalles'] as List<dynamic>?)
              ?.map((e) => PedidoItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      creadoEn: json['creadoEn'] != null
          ? DateTime.tryParse(json['creadoEn'].toString())
          : null,
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.tryParse(json['actualizadoEn'].toString())
          : null,
    );
  }

  PedidoMarketplaceEmpresa toEntity() {
    return PedidoMarketplaceEmpresa(
      id: id,
      codigo: codigo,
      estado: estado,
      nombreComprador: nombreComprador,
      emailComprador: emailComprador,
      telefonoComprador: telefonoComprador,
      total: total,
      direccionEnvio: direccionEnvio,
      referenciaEnvio: referenciaEnvio,
      distritoEnvio: distritoEnvio,
      provinciaEnvio: provinciaEnvio,
      departamentoEnvio: departamentoEnvio,
      coordenadasEnvio: coordenadasEnvio,
      metodoPago: metodoPago,
      comprobantePagoUrl: comprobantePagoUrl,
      motivoRechazo: motivoRechazo,
      codigoSeguimiento: codigoSeguimiento,
      detalles: detalles.map((e) => e.toEntity()).toList(),
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }
}

class PedidoItemModel {
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? imagenUrl;

  const PedidoItemModel({
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.imagenUrl,
  });

  factory PedidoItemModel.fromJson(Map<String, dynamic> json) {
    final cantidad = json['cantidad'] as int? ?? 1;
    final precioUnitario =
        double.tryParse(json['precioUnitario']?.toString() ?? '') ?? 0;
    return PedidoItemModel(
      productoNombre: json['descripcion'] as String? ?? '',
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '') ??
          (cantidad * precioUnitario),
      imagenUrl: json['imagenUrl'] as String?,
    );
  }

  PedidoItem toEntity() {
    return PedidoItem(
      productoNombre: productoNombre,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
      imagenUrl: imagenUrl,
    );
  }
}

class ResumenPedidosModel {
  final int total;
  final int pendientePago;
  final int pagoEnviado;
  final int pagoValidado;
  final int enPreparacion;
  final int enviados;
  final int entregados;
  final int cancelados;
  final int pagoRechazado;

  const ResumenPedidosModel({
    required this.total,
    required this.pendientePago,
    required this.pagoEnviado,
    required this.pagoValidado,
    required this.enPreparacion,
    required this.enviados,
    required this.entregados,
    required this.cancelados,
    required this.pagoRechazado,
  });

  factory ResumenPedidosModel.fromJson(Map<String, dynamic> json) {
    return ResumenPedidosModel(
      total: json['total'] as int? ?? 0,
      pendientePago: json['pendientePago'] as int? ?? 0,
      pagoEnviado: json['pagoEnviado'] as int? ?? 0,
      pagoValidado: json['pagoValidado'] as int? ?? 0,
      enPreparacion: json['enPreparacion'] as int? ?? 0,
      enviados: json['enviados'] as int? ?? 0,
      entregados: json['entregados'] as int? ?? 0,
      cancelados: json['cancelados'] as int? ?? 0,
      pagoRechazado: json['pagoRechazado'] as int? ?? 0,
    );
  }

  ResumenPedidos toEntity() {
    return ResumenPedidos(
      total: total,
      pendientePago: pendientePago,
      pagoEnviado: pagoEnviado,
      pagoValidado: pagoValidado,
      enPreparacion: enPreparacion,
      enviados: enviados,
      entregados: entregados,
      cancelados: cancelados,
      pagoRechazado: pagoRechazado,
    );
  }
}
