import '../../domain/entities/pedido_marketplace.dart';

class EmpresaInfoModel {
  final String id;
  final String nombre;
  final String? logo;
  final String subdominio;

  const EmpresaInfoModel({
    required this.id,
    required this.nombre,
    this.logo,
    required this.subdominio,
  });

  factory EmpresaInfoModel.fromJson(Map<String, dynamic> json) {
    return EmpresaInfoModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      subdominio: json['subdominio'] as String? ?? '',
    );
  }

  EmpresaInfo toEntity() {
    return EmpresaInfo(
      id: id,
      nombre: nombre,
      logo: logo,
      subdominio: subdominio,
    );
  }
}

class PedidoDetalleModel {
  final String id;
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? imagenUrl;

  const PedidoDetalleModel({
    required this.id,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.imagenUrl,
  });

  factory PedidoDetalleModel.fromJson(Map<String, dynamic> json) {
    return PedidoDetalleModel(
      id: json['id'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 1,
      precioUnitario: _toDouble(json['precioUnitario']),
      subtotal: _toDouble(json['subtotal']),
      imagenUrl: json['imagenUrl'] as String?,
    );
  }

  PedidoDetalle toEntity() {
    return PedidoDetalle(
      id: id,
      descripcion: descripcion,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
      imagenUrl: imagenUrl,
    );
  }
}

class PedidoMarketplaceModel {
  final String id;
  final String codigo;
  final String compradorId;
  final String empresaId;
  final String nombreComprador;
  final String emailComprador;
  final String? telefonoComprador;
  final String direccionEnvio;
  final double subtotal;
  final double total;
  final String moneda;
  final String estado;
  final String metodoPago;
  final String? comprobantePagoUrl;
  final String? motivoRechazo;
  final DateTime creadoEn;
  // Fechas de hitos del pedido (timeline de seguimiento).
  final DateTime? pagoValidadoEn;
  final DateTime? enviadoEn;
  final DateTime? entregadoEn;
  final DateTime? actualizadoEn;
  final bool yapeAutomaticoDisponible;
  final EmpresaInfoModel empresa;
  final List<PedidoDetalleModel> detalles;

  const PedidoMarketplaceModel({
    required this.id,
    required this.codigo,
    required this.compradorId,
    required this.empresaId,
    required this.nombreComprador,
    required this.emailComprador,
    this.telefonoComprador,
    required this.direccionEnvio,
    required this.subtotal,
    required this.total,
    required this.moneda,
    required this.estado,
    required this.metodoPago,
    this.comprobantePagoUrl,
    this.motivoRechazo,
    required this.creadoEn,
    this.pagoValidadoEn,
    this.enviadoEn,
    this.entregadoEn,
    this.actualizadoEn,
    this.yapeAutomaticoDisponible = false,
    required this.empresa,
    required this.detalles,
  });

  factory PedidoMarketplaceModel.fromJson(Map<String, dynamic> json) {
    final empresaJson = json['empresa'] as Map<String, dynamic>? ?? {};
    final detallesJson = json['detalles'] as List<dynamic>? ?? [];

    return PedidoMarketplaceModel(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      compradorId: json['compradorId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      nombreComprador: json['nombreComprador'] as String? ?? '',
      emailComprador: json['emailComprador'] as String? ?? '',
      telefonoComprador: json['telefonoComprador'] as String?,
      direccionEnvio: json['direccionEnvio'] as String? ?? '',
      subtotal: _toDouble(json['subtotal']),
      total: _toDouble(json['total']),
      moneda: json['moneda'] as String? ?? 'PEN',
      estado: json['estado'] as String? ?? 'PENDIENTE_PAGO',
      metodoPago: json['metodoPago'] as String? ?? '',
      comprobantePagoUrl: json['comprobantePagoUrl'] as String?,
      motivoRechazo: json['motivoRechazo'] as String?,
      creadoEn: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : DateTime.now(),
      pagoValidadoEn: _toDate(json['pagoValidadoEn']),
      enviadoEn: _toDate(json['enviadoEn']),
      entregadoEn: _toDate(json['entregadoEn']),
      actualizadoEn: _toDate(json['actualizadoEn']),
      // Compat: si el backend aún no manda el flag (listados), se asume
      // true para conservar el comportamiento previo (el sheet se cierra
      // solo si no está habilitado).
      yapeAutomaticoDisponible:
          json['yapeAutomaticoDisponible'] as bool? ?? true,
      empresa: EmpresaInfoModel.fromJson(empresaJson),
      detalles: detallesJson
          .map((e) => PedidoDetalleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  PedidoMarketplace toEntity() {
    return PedidoMarketplace(
      id: id,
      codigo: codigo,
      compradorId: compradorId,
      empresaId: empresaId,
      nombreComprador: nombreComprador,
      emailComprador: emailComprador,
      telefonoComprador: telefonoComprador,
      direccionEnvio: direccionEnvio,
      subtotal: subtotal,
      total: total,
      moneda: moneda,
      estado: EstadoPedidoMarketplace.fromString(estado),
      metodoPago: metodoPago,
      comprobantePagoUrl: comprobantePagoUrl,
      motivoRechazo: motivoRechazo,
      creadoEn: creadoEn,
      pagoValidadoEn: pagoValidadoEn,
      enviadoEn: enviadoEn,
      entregadoEn: entregadoEn,
      actualizadoEn: actualizadoEn,
      yapeAutomaticoDisponible: yapeAutomaticoDisponible,
      empresa: empresa.toEntity(),
      detalles: detalles.map((d) => d.toEntity()).toList(),
    );
  }
}

DateTime? _toDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
