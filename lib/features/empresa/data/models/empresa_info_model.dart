import '../../domain/entities/empresa_info.dart';

class PlanSuscripcionModel extends PlanSuscripcion {
  const PlanSuscripcionModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.precio,
    required super.periodo,
  });

  factory PlanSuscripcionModel.fromJson(Map<String, dynamic> json) {
    return PlanSuscripcionModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      periodo: json['periodo'] as String? ?? 'MENSUAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'periodo': periodo,
    };
  }

  PlanSuscripcion toEntity() => this;

  factory PlanSuscripcionModel.fromEntity(PlanSuscripcion entity) {
    return PlanSuscripcionModel(
      id: entity.id,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
      precio: entity.precio,
      periodo: entity.periodo,
    );
  }
}

class EmpresaInfoModel extends EmpresaInfo {
  const EmpresaInfoModel({
    required super.id,
    required super.nombre,
    super.ruc,
    super.subdominio,
    super.logo,
    super.email,
    super.telefono,
    super.descripcion,
    super.web,
    super.planSuscripcionId,
    required super.estadoSuscripcion,
    required super.usuariosActuales,
    super.fechaInicioSuscripcion,
    super.fechaVencimiento,
    super.planSuscripcion,
  });

  factory EmpresaInfoModel.fromJson(Map<String, dynamic> json) {
    return EmpresaInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ruc: json['ruc'] as String?,
      subdominio: json['subdominio'] as String?,
      logo: json['logo'] as String?,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      descripcion: json['descripcion'] as String?,
      web: json['web'] as String?,
      planSuscripcionId: json['planSuscripcionId'] as String?,
      estadoSuscripcion: json['estadoSuscripcion'] as String? ?? 'ACTIVA',
      usuariosActuales: json['usuariosActuales'] as int? ?? 0,
      fechaInicioSuscripcion: json['fechaInicioSuscripcion'] != null
          ? DateTime.parse(json['fechaInicioSuscripcion'] as String)
          : null,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      planSuscripcion: json['planSuscripcion'] != null
          ? PlanSuscripcionModel.fromJson(
              json['planSuscripcion'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (ruc != null) 'ruc': ruc,
      if (subdominio != null) 'subdominio': subdominio,
      if (logo != null) 'logo': logo,
      if (email != null) 'email': email,
      if (telefono != null) 'telefono': telefono,
      if (descripcion != null) 'descripcion': descripcion,
      if (web != null) 'web': web,
      if (planSuscripcionId != null) 'planSuscripcionId': planSuscripcionId,
      'estadoSuscripcion': estadoSuscripcion,
      'usuariosActuales': usuariosActuales,
      if (fechaInicioSuscripcion != null)
        'fechaInicioSuscripcion': fechaInicioSuscripcion!.toIso8601String(),
      if (fechaVencimiento != null)
        'fechaVencimiento': fechaVencimiento!.toIso8601String(),
      if (planSuscripcion != null)
        'planSuscripcion':
            PlanSuscripcionModel.fromEntity(planSuscripcion!).toJson(),
    };
  }

  EmpresaInfo toEntity() => this;

  factory EmpresaInfoModel.fromEntity(EmpresaInfo entity) {
    return EmpresaInfoModel(
      id: entity.id,
      nombre: entity.nombre,
      ruc: entity.ruc,
      subdominio: entity.subdominio,
      logo: entity.logo,
      email: entity.email,
      telefono: entity.telefono,
      descripcion: entity.descripcion,
      web: entity.web,
      planSuscripcionId: entity.planSuscripcionId,
      estadoSuscripcion: entity.estadoSuscripcion,
      usuariosActuales: entity.usuariosActuales,
      fechaInicioSuscripcion: entity.fechaInicioSuscripcion,
      fechaVencimiento: entity.fechaVencimiento,
      planSuscripcion: entity.planSuscripcion != null
          ? PlanSuscripcionModel(
              id: entity.planSuscripcion!.id,
              nombre: entity.planSuscripcion!.nombre,
              descripcion: entity.planSuscripcion!.descripcion,
              precio: entity.planSuscripcion!.precio,
              periodo: entity.planSuscripcion!.periodo,
            )
          : null,
    );
  }
}
