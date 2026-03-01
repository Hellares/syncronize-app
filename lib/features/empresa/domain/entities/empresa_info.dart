import 'package:equatable/equatable.dart';

/// Información del plan de suscripción
class PlanSuscripcion extends Equatable {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String periodo;

  const PlanSuscripcion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.periodo,
  });

  /// Indica si es el plan gratuito
  bool get isFreePlan => precio == 0 || nombre.toUpperCase().contains('BÁSICO');

  @override
  List<Object?> get props => [id, nombre, descripcion, precio, periodo];
}

/// Entidad que representa la información básica de la empresa
class EmpresaInfo extends Equatable {
  final String id;
  final String nombre;
  final String? ruc;
  final String? subdominio;
  final String? logo;
  final String? email;
  final String? telefono;
  final String? descripcion;
  final String? web;
  final String? razonSocial;
  final String? rubro;
  final String? tipoContribuyente;
  final String? estadoContribuyente;
  final String? condicionContribuyente;
  final String? direccionFiscal;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? ubigeo;
  final String? planSuscripcionId;
  final String estadoSuscripcion;
  final int usuariosActuales;
  final DateTime? fechaInicioSuscripcion;
  final DateTime? fechaVencimiento;
  final PlanSuscripcion? planSuscripcion;

  const EmpresaInfo({
    required this.id,
    required this.nombre,
    this.ruc,
    this.subdominio,
    this.logo,
    this.email,
    this.telefono,
    this.descripcion,
    this.web,
    this.razonSocial,
    this.rubro,
    this.tipoContribuyente,
    this.estadoContribuyente,
    this.condicionContribuyente,
    this.direccionFiscal,
    this.departamento,
    this.provincia,
    this.distrito,
    this.ubigeo,
    this.planSuscripcionId,
    required this.estadoSuscripcion,
    required this.usuariosActuales,
    this.fechaInicioSuscripcion,
    this.fechaVencimiento,
    this.planSuscripcion,
  });

  /// Indica si la suscripción está activa
  bool get isSubscriptionActive => estadoSuscripcion == 'ACTIVA';

  /// Indica si la suscripción está próxima a vencer (menos de 7 días)
  bool get isSubscriptionExpiringSoon {
    if (fechaVencimiento == null) return false;
    final daysUntilExpiration = fechaVencimiento!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration > 0;
  }

  /// Indica si la suscripción ha vencido
  bool get isSubscriptionExpired {
    if (fechaVencimiento == null) return false;
    return DateTime.now().isAfter(fechaVencimiento!);
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        ruc,
        subdominio,
        logo,
        email,
        telefono,
        descripcion,
        web,
        razonSocial,
        rubro,
        tipoContribuyente,
        estadoContribuyente,
        condicionContribuyente,
        direccionFiscal,
        departamento,
        provincia,
        distrito,
        ubigeo,
        planSuscripcionId,
        estadoSuscripcion,
        usuariosActuales,
        fechaInicioSuscripcion,
        fechaVencimiento,
        planSuscripcion,
      ];
}
