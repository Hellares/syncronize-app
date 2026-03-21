import '../../domain/entities/solicitud_empresa.dart';

/// Modelo de datos para un item de solicitud
class SolicitudItemModel {
  final String? id;
  final String descripcion;
  final int cantidad;
  final double? precioReferencia;
  final String? notasItem;
  final bool esManual;
  final String? imagenUrl;

  const SolicitudItemModel({
    this.id,
    required this.descripcion,
    required this.cantidad,
    this.precioReferencia,
    this.notasItem,
    this.esManual = false,
    this.imagenUrl,
  });

  factory SolicitudItemModel.fromJson(Map<String, dynamic> json) {
    return SolicitudItemModel(
      id: json['id'] as String?,
      descripcion: json['descripcion'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      precioReferencia: (json['precioReferencia'] as num?)?.toDouble(),
      notasItem: json['notasItem'] as String?,
      esManual: json['esManual'] as bool? ?? false,
      imagenUrl: json['imagenUrl'] as String?,
    );
  }

  SolicitudItem toEntity() {
    return SolicitudItem(
      id: id,
      descripcion: descripcion,
      cantidad: cantidad,
      precioReferencia: precioReferencia,
      notasItem: notasItem,
      esManual: esManual,
      imagenUrl: imagenUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'descripcion': descripcion,
      'cantidad': cantidad,
      if (precioReferencia != null) 'precioReferencia': precioReferencia,
      if (notasItem != null) 'notasItem': notasItem,
      'esManual': esManual,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
    };
  }
}

/// Modelo de datos para el solicitante
class SolicitanteModel {
  final String? id;
  final String? nombre;
  final String? email;
  final String? telefono;
  final String? dni;

  const SolicitanteModel({
    this.id,
    this.nombre,
    this.email,
    this.telefono,
    this.dni,
  });

  factory SolicitanteModel.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>?;
    return SolicitanteModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String?,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      dni: persona?['dni'] as String?,
    );
  }

  Solicitante toEntity() {
    return Solicitante(
      id: id,
      nombre: nombre,
      email: email,
      telefono: telefono,
      dni: dni,
    );
  }
}

/// Modelo de datos para una solicitud de cotizacion recibida
class SolicitudRecibidaModel {
  final String id;
  final String? codigo;
  final String estado;
  final String? nombreSolicitante;
  final String? emailSolicitante;
  final String? telefonoSolicitante;
  final SolicitanteModel? solicitante;
  final List<SolicitudItemModel> items;
  final String? observaciones;
  final String? respuestaVendedor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const SolicitudRecibidaModel({
    required this.id,
    this.codigo,
    required this.estado,
    this.nombreSolicitante,
    this.emailSolicitante,
    this.telefonoSolicitante,
    this.solicitante,
    this.items = const [],
    this.observaciones,
    this.respuestaVendedor,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory SolicitudRecibidaModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final solicitanteJson = json['solicitante'] as Map<String, dynamic>?;

    return SolicitudRecibidaModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String?,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      nombreSolicitante: json['nombreSolicitante'] as String?,
      emailSolicitante: json['emailSolicitante'] as String?,
      telefonoSolicitante: json['telefonoSolicitante'] as String?,
      solicitante: solicitanteJson != null
          ? SolicitanteModel.fromJson(solicitanteJson)
          : null,
      items: rawItems
          .map((e) => SolicitudItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      observaciones: json['observaciones'] as String?,
      respuestaVendedor: json['respuestaVendedor'] as String?,
      creadoEn: json['creadoEn'] != null
          ? DateTime.tryParse(json['creadoEn'].toString())
          : null,
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.tryParse(json['actualizadoEn'].toString())
          : null,
    );
  }

  SolicitudRecibida toEntity() {
    return SolicitudRecibida(
      id: id,
      codigo: codigo,
      estado: estado,
      nombreSolicitante: nombreSolicitante,
      emailSolicitante: emailSolicitante,
      telefonoSolicitante: telefonoSolicitante,
      solicitante: solicitante?.toEntity(),
      items: items.map((i) => i.toEntity()).toList(),
      observaciones: observaciones,
      respuestaVendedor: respuestaVendedor,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }
}
