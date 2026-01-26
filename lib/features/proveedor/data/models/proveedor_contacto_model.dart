import '../../domain/entities/proveedor_contacto.dart';

/// Model que representa un contacto del proveedor
class ProveedorContactoModel extends ProveedorContacto {
  const ProveedorContactoModel({
    required super.id,
    required super.proveedorId,
    required super.nombre,
    super.cargo,
    super.email,
    super.telefono,
    super.telefonoMovil,
    required super.esPrincipal,
    required super.creadoEn,
  });

  /// Crea una instancia desde JSON
  factory ProveedorContactoModel.fromJson(Map<String, dynamic> json) {
    return ProveedorContactoModel(
      id: json['id'] as String,
      proveedorId: json['proveedorId'] as String,
      nombre: json['nombre'] as String,
      cargo: json['cargo'] as String?,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      telefonoMovil: json['telefonoMovil'] as String?,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'cargo': cargo,
      'email': email,
      'telefono': telefono,
      'telefonoMovil': telefonoMovil,
      'esPrincipal': esPrincipal,
    };
  }
}
