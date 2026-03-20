import '../../domain/entities/solicitud_cotizacion.dart';

/// Model para item de solicitud
class SolicitudItemModel {
  final String? id;
  final String descripcion;
  final int cantidad;
  final String? imagenUrl;
  final bool esManual;
  final String? notasItem;
  final String? productoId;
  final String? varianteId;

  const SolicitudItemModel({
    this.id,
    required this.descripcion,
    required this.cantidad,
    this.imagenUrl,
    this.esManual = false,
    this.notasItem,
    this.productoId,
    this.varianteId,
  });

  factory SolicitudItemModel.fromJson(Map<String, dynamic> json) {
    return SolicitudItemModel(
      id: json['id'] as String?,
      descripcion: json['descripcion'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      imagenUrl: json['imagenUrl'] as String?,
      esManual: json['esManual'] as bool? ?? false,
      notasItem: json['notasItem'] as String?,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
      'esManual': esManual,
      if (notasItem != null) 'notasItem': notasItem,
    };
  }

  SolicitudItem toEntity() {
    return SolicitudItem(
      id: id,
      descripcion: descripcion,
      cantidad: cantidad,
      imagenUrl: imagenUrl,
      esManual: esManual,
      notasItem: notasItem,
      productoId: productoId,
      varianteId: varianteId,
    );
  }
}

/// Model para empresa de solicitud
class SolicitudEmpresaModel {
  final String id;
  final String nombre;
  final String? logo;
  final String subdominio;

  const SolicitudEmpresaModel({
    required this.id,
    required this.nombre,
    this.logo,
    required this.subdominio,
  });

  factory SolicitudEmpresaModel.fromJson(Map<String, dynamic> json) {
    return SolicitudEmpresaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      subdominio: json['subdominio'] as String? ?? '',
    );
  }

  SolicitudEmpresa toEntity() {
    return SolicitudEmpresa(
      id: id,
      nombre: nombre,
      logo: logo,
      subdominio: subdominio,
    );
  }
}

/// Model principal de solicitud de cotizacion
class SolicitudCotizacionModel {
  final String id;
  final String codigo;
  final String solicitanteId;
  final String empresaId;
  final String nombreSolicitante;
  final String estado;
  final String? observaciones;
  final String? respuestaVendedor;
  final String? cotizacionId;
  final SolicitudEmpresaModel? empresa;
  final List<SolicitudItemModel> items;
  final dynamic cotizacion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const SolicitudCotizacionModel({
    required this.id,
    required this.codigo,
    required this.solicitanteId,
    required this.empresaId,
    required this.nombreSolicitante,
    required this.estado,
    this.observaciones,
    this.respuestaVendedor,
    this.cotizacionId,
    this.empresa,
    this.items = const [],
    this.cotizacion,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory SolicitudCotizacionModel.fromJson(Map<String, dynamic> json) {
    // Parsear empresa
    SolicitudEmpresaModel? empresa;
    if (json['empresa'] != null && json['empresa'] is Map<String, dynamic>) {
      empresa =
          SolicitudEmpresaModel.fromJson(json['empresa'] as Map<String, dynamic>);
    }

    // Parsear items
    List<SolicitudItemModel> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((e) => SolicitudItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SolicitudCotizacionModel(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      solicitanteId: json['solicitanteId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      nombreSolicitante: json['nombreSolicitante'] as String? ?? '',
      estado: json['estado'] as String? ?? 'PENDIENTE',
      observaciones: json['observaciones'] as String?,
      respuestaVendedor: json['respuestaVendedor'] as String?,
      cotizacionId: json['cotizacionId'] as String?,
      empresa: empresa,
      items: items,
      cotizacion: json['cotizacion'],
      creadoEn: json['creadoEn'] != null
          ? DateTime.tryParse(json['creadoEn'] as String)
          : null,
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.tryParse(json['actualizadoEn'] as String)
          : null,
    );
  }

  SolicitudCotizacion toEntity() {
    return SolicitudCotizacion(
      id: id,
      codigo: codigo,
      solicitanteId: solicitanteId,
      empresaId: empresaId,
      nombreSolicitante: nombreSolicitante,
      estado: EstadoSolicitudCotizacion.fromString(estado),
      observaciones: observaciones,
      respuestaVendedor: respuestaVendedor,
      cotizacionId: cotizacionId,
      empresa: empresa?.toEntity(),
      items: items.map((item) => item.toEntity()).toList(),
      cotizacion: cotizacion,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }
}
