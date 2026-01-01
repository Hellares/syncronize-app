import 'package:equatable/equatable.dart';

/// Entity que representa un item de empresa en la lista de empresas del usuario
class EmpresaListItem extends Equatable {
  final String id;
  final String nombre;
  final String? ruc;
  final String? subdominio;
  final String? logo;
  final String? email;
  final bool isActive;
  final List<String> roles; // Roles del usuario en esta empresa
  final String? planNombre;
  final String estadoSuscripcion;
  final DateTime? fechaVencimiento;

  const EmpresaListItem({
    required this.id,
    required this.nombre,
    this.ruc,
    this.subdominio,
    this.logo,
    this.email,
    required this.isActive,
    required this.roles,
    this.planNombre,
    required this.estadoSuscripcion,
    this.fechaVencimiento,
  });

  /// Obtiene el rol principal del usuario (el más alto en jerarquía)
  String? get primaryRole {
    if (roles.isEmpty) return null;

    // Orden de jerarquía de roles
    const roleHierarchy = [
      'SUPER_ADMIN',
      'EMPRESA_ADMIN',
      'SEDE_ADMIN',
      'CONTADOR',
      'CAJERO',
      'VENDEDOR',
      'TECNICO',
      'LECTURA',
    ];

    for (final role in roleHierarchy) {
      if (roles.contains(role)) return role;
    }

    return roles.first;
  }

  /// Verifica si el usuario es administrador
  bool get isAdmin {
    return roles.contains('SUPER_ADMIN') || roles.contains('EMPRESA_ADMIN');
  }

  /// Verifica si la suscripción está activa
  bool get isSubscriptionActive {
    return estadoSuscripcion == 'ACTIVA';
  }

  /// Verifica si la suscripción está por vencer (menos de 7 días)
  bool get isSubscriptionExpiringSoon {
    if (fechaVencimiento == null) return false;
    final now = DateTime.now();
    final daysUntilExpiration = fechaVencimiento!.difference(now).inDays;
    return daysUntilExpiration > 0 && daysUntilExpiration <= 7;
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        ruc,
        subdominio,
        logo,
        email,
        isActive,
        roles,
        planNombre,
        estadoSuscripcion,
        fechaVencimiento,
      ];
}
