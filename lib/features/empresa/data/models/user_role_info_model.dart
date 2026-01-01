import '../../domain/entities/user_role_info.dart';

class UserRoleInfoModel extends UserRoleInfo {
  const UserRoleInfoModel({
    required super.id,
    required super.rol,
    required super.isActive,
    required super.estado,
    super.fechaAprobacion,
  });

  factory UserRoleInfoModel.fromJson(Map<String, dynamic> json) {
    return UserRoleInfoModel(
      id: json['id'] as String,
      rol: json['rol'] as String,
      isActive: json['isActive'] as bool? ?? true,
      estado: json['estado'] as String? ?? 'ACTIVO',
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rol': rol,
      'isActive': isActive,
      'estado': estado,
      if (fechaAprobacion != null)
        'fechaAprobacion': fechaAprobacion!.toIso8601String(),
    };
  }

  UserRoleInfo toEntity() => this;

  factory UserRoleInfoModel.fromEntity(UserRoleInfo entity) {
    return UserRoleInfoModel(
      id: entity.id,
      rol: entity.rol,
      isActive: entity.isActive,
      estado: entity.estado,
      fechaAprobacion: entity.fechaAprobacion,
    );
  }
}
