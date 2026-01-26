import 'package:equatable/equatable.dart';

/// Entity que representa un contacto del proveedor
class ProveedorContacto extends Equatable {
  final String id;
  final String proveedorId;
  final String nombre;
  final String? cargo;
  final String? email;
  final String? telefono;
  final String? telefonoMovil;
  final bool esPrincipal;
  final DateTime creadoEn;

  const ProveedorContacto({
    required this.id,
    required this.proveedorId,
    required this.nombre,
    this.cargo,
    this.email,
    this.telefono,
    this.telefonoMovil,
    required this.esPrincipal,
    required this.creadoEn,
  });

  /// Obtiene el mejor teléfono disponible
  String? get telefonoPreferido {
    return telefonoMovil ?? telefono;
  }

  /// Verifica si tiene información de contacto completa
  bool get datosCompletos {
    return email != null && (telefono != null || telefonoMovil != null);
  }

  @override
  List<Object?> get props => [
        id,
        proveedorId,
        nombre,
        cargo,
        email,
        telefono,
        telefonoMovil,
        esPrincipal,
        creadoEn,
      ];
}
