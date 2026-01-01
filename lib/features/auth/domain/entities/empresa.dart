import 'package:equatable/equatable.dart';

/// Entidad de Empresa
class Empresa extends Equatable {
  final String id;
  final String nombre;
  final String? ruc;
  final String? subdominio;
  final String? logo;
  final String? descripcion;
  final String? web;
  final String? telefono;
  final String? email;
  final String? planSuscripcionId;
  final DateTime? fechaInicioSuscripcion;
  final DateTime? fechaVencimiento;
  final String? estadoSuscripcion;
  final int? usuariosActuales;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Empresa({
    required this.id,
    required this.nombre,
    this.ruc,
    this.subdominio,
    this.logo,
    this.descripcion,
    this.web,
    this.telefono,
    this.email,
    this.planSuscripcionId,
    this.fechaInicioSuscripcion,
    this.fechaVencimiento,
    this.estadoSuscripcion,
    this.usuariosActuales,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        ruc,
        subdominio,
        logo,
        descripcion,
        web,
        telefono,
        email,
        planSuscripcionId,
        fechaInicioSuscripcion,
        fechaVencimiento,
        estadoSuscripcion,
        usuariosActuales,
        createdAt,
        updatedAt,
      ];
}
