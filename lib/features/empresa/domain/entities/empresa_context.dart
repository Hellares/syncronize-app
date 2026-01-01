import 'package:equatable/equatable.dart';
import 'empresa_info.dart';
import 'empresa_permissions.dart';
import 'empresa_statistics.dart';
import 'sede.dart';
import 'user_role_info.dart';

/// Entidad que representa el contexto completo de la empresa
/// Contiene toda la información necesaria para operar en la empresa seleccionada
class EmpresaContext extends Equatable {
  final EmpresaInfo empresa;
  final List<UserRoleInfo> userRoles;
  final List<Sede> sedes;
  final EmpresaPermissions permissions;
  final EmpresaStatistics statistics;

  const EmpresaContext({
    required this.empresa,
    required this.userRoles,
    required this.sedes,
    required this.permissions,
    required this.statistics,
  });

  /// Obtiene el rol principal del usuario (el primero de la lista)
  UserRoleInfo? get primaryRole =>
      userRoles.isNotEmpty ? userRoles.first : null;

  /// Obtiene la sede principal
  Sede? get sedePrincipal =>
      sedes.firstWhere((s) => s.esPrincipal, orElse: () => sedes.first);

  /// Indica si el usuario tiene múltiples roles
  bool get hasMultipleRoles => userRoles.length > 1;

  /// Obtiene todos los nombres de roles
  List<String> get roleNames => userRoles.map((r) => r.rol).toList();

  @override
  List<Object?> get props => [
        empresa,
        userRoles,
        sedes,
        permissions,
        statistics,
      ];
}
