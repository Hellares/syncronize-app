import '../../domain/entities/empresa.dart';

/// Modelo de Empresa para la capa de datos
class EmpresaModel extends Empresa {
  const EmpresaModel({
    required super.id,
    required super.nombre,
    super.ruc,
    super.subdominio,
    super.logo,
    super.descripcion,
    super.web,
    super.telefono,
    super.email,
    super.planSuscripcionId,
    super.fechaInicioSuscripcion,
    super.fechaVencimiento,
    super.estadoSuscripcion,
    super.usuariosActuales,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Crear modelo desde JSON
  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ruc: json['ruc'] as String?,
      subdominio: json['subdominio'] as String?,
      logo: json['logo'] as String?,
      descripcion: json['descripcion'] as String?,
      web: json['web'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      planSuscripcionId: json['planSuscripcionId'] as String?,
      fechaInicioSuscripcion: json['fechaInicioSuscripcion'] != null
          ? DateTime.parse(json['fechaInicioSuscripcion'] as String)
          : null,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      estadoSuscripcion: json['estadoSuscripcion'] as String?,
      usuariosActuales: json['usuariosActuales'] as int?,
      createdAt: DateTime.parse(json['creadoEn'] as String),
      updatedAt: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  /// Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (ruc != null) 'ruc': ruc,
      if (subdominio != null) 'subdominio': subdominio,
      if (logo != null) 'logo': logo,
      if (descripcion != null) 'descripcion': descripcion,
      if (web != null) 'web': web,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (planSuscripcionId != null) 'planSuscripcionId': planSuscripcionId,
      if (fechaInicioSuscripcion != null)
        'fechaInicioSuscripcion': fechaInicioSuscripcion!.toIso8601String(),
      if (fechaVencimiento != null)
        'fechaVencimiento': fechaVencimiento!.toIso8601String(),
      if (estadoSuscripcion != null) 'estadoSuscripcion': estadoSuscripcion,
      if (usuariosActuales != null) 'usuariosActuales': usuariosActuales,
      'creadoEn': createdAt.toIso8601String(),
      'actualizadoEn': updatedAt.toIso8601String(),
    };
  }

  /// Convertir a entidad
  Empresa toEntity() => this;

  /// Crear modelo desde entidad
  factory EmpresaModel.fromEntity(Empresa empresa) {
    return EmpresaModel(
      id: empresa.id,
      nombre: empresa.nombre,
      ruc: empresa.ruc,
      subdominio: empresa.subdominio,
      logo: empresa.logo,
      descripcion: empresa.descripcion,
      web: empresa.web,
      telefono: empresa.telefono,
      email: empresa.email,
      planSuscripcionId: empresa.planSuscripcionId,
      fechaInicioSuscripcion: empresa.fechaInicioSuscripcion,
      fechaVencimiento: empresa.fechaVencimiento,
      estadoSuscripcion: empresa.estadoSuscripcion,
      usuariosActuales: empresa.usuariosActuales,
      createdAt: empresa.createdAt,
      updatedAt: empresa.updatedAt,
    );
  }
}
