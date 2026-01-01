import '../../domain/entities/empresa_list_item.dart';

class EmpresaListItemModel extends EmpresaListItem {
  const EmpresaListItemModel({
    required super.id,
    required super.nombre,
    super.ruc,
    super.subdominio,
    super.logo,
    super.email,
    required super.isActive,
    required super.roles,
    super.planNombre,
    required super.estadoSuscripcion,
    super.fechaVencimiento,
  });

  factory EmpresaListItemModel.fromJson(Map<String, dynamic> json) {
    return EmpresaListItemModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ruc: json['ruc'] as String?,
      subdominio: json['subdominio'] as String?,
      logo: json['logo'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      planNombre: json['planSuscripcion'] != null
          ? (json['planSuscripcion'] as Map<String, dynamic>)['nombre'] as String?
          : null,
      estadoSuscripcion: json['estadoSuscripcion'] as String? ?? 'ACTIVA',
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
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
      'isActive': isActive,
      'roles': roles,
      if (planNombre != null)
        'planSuscripcion': {'nombre': planNombre},
      'estadoSuscripcion': estadoSuscripcion,
      if (fechaVencimiento != null)
        'fechaVencimiento': fechaVencimiento!.toIso8601String(),
    };
  }

  EmpresaListItem toEntity() => this;

  factory EmpresaListItemModel.fromEntity(EmpresaListItem entity) {
    return EmpresaListItemModel(
      id: entity.id,
      nombre: entity.nombre,
      ruc: entity.ruc,
      subdominio: entity.subdominio,
      logo: entity.logo,
      email: entity.email,
      isActive: entity.isActive,
      roles: entity.roles,
      planNombre: entity.planNombre,
      estadoSuscripcion: entity.estadoSuscripcion,
      fechaVencimiento: entity.fechaVencimiento,
    );
  }
}
