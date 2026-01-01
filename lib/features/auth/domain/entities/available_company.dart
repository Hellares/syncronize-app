import 'package:equatable/equatable.dart';

/// Entidad de Empresa Disponible para Selección
/// Representa una empresa donde el usuario tiene roles asignados
class AvailableCompany extends Equatable {
  final String id;
  final String nombre;
  final String subdominio;
  final String? logo;
  final List<String> roles;

  const AvailableCompany({
    required this.id,
    required this.nombre,
    required this.subdominio,
    this.logo,
    required this.roles,
  });

  @override
  List<Object?> get props => [id, nombre, subdominio, logo, roles];
}
