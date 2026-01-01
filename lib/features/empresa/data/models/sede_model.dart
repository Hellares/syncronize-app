import '../../domain/entities/sede.dart';

class SedeModel extends Sede {
  const SedeModel({
    required super.id,
    required super.nombre,
    super.telefono,
    super.email,
    super.direccion,
    required super.esPrincipal,
    required super.isActive,
    super.userRole,
  });

  factory SedeModel.fromJson(Map<String, dynamic> json) {
    return SedeModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      userRole: json['userRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (direccion != null) 'direccion': direccion,
      'esPrincipal': esPrincipal,
      'isActive': isActive,
      if (userRole != null) 'userRole': userRole,
    };
  }

  Sede toEntity() => this;

  factory SedeModel.fromEntity(Sede entity) {
    return SedeModel(
      id: entity.id,
      nombre: entity.nombre,
      telefono: entity.telefono,
      email: entity.email,
      direccion: entity.direccion,
      esPrincipal: entity.esPrincipal,
      isActive: entity.isActive,
      userRole: entity.userRole,
    );
  }
}
