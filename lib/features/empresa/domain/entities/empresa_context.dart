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
  final PlanLimitsInfo? planLimits;

  /// Características PREMIUM habilitadas (gating). Ej: {'YAPE_QR': true}.
  /// Vacío/ausente = ninguna habilitada → el front no ofrece esas features.
  final Map<String, bool> caracteristicas;

  /// Límite por transacción Yape/Plin (tamaño máx de cada tramo en el split).
  final double yapeMaxPorTransaccion;

  /// Tope diario por método Yape/Plin (advertencia en el split).
  final double yapeMaxPorDia;

  const EmpresaContext({
    required this.empresa,
    required this.userRoles,
    required this.sedes,
    required this.permissions,
    required this.statistics,
    this.planLimits,
    this.caracteristicas = const {},
    this.yapeMaxPorTransaccion = 500,
    this.yapeMaxPorDia = 2000,
  });

  /// ¿El cobro Yape/Plin con QR (validación api-yape) está habilitado?
  /// Si NO, Yape se cobra como medio de pago normal (sin hoja/QR/aprobación).
  bool get yapeQrHabilitado => caracteristicas['YAPE_QR'] == true;

  /// Obtiene el rol principal del usuario (el primero de la lista)
  UserRoleInfo? get primaryRole =>
      userRoles.isNotEmpty ? userRoles.first : null;

  /// Obtiene la sede principal (o la primera si ninguna es principal)
  Sede? get sedePrincipal {
    if (sedes.isEmpty) return null;
    for (final sede in sedes) {
      if (sede.esPrincipal) return sede;
    }
    return sedes.first;
  }

  /// ¿El usuario es admin de la empresa? (opera todas las sedes)
  bool get esAdminEmpresa => userRoles.any(
        (r) => r.rol == 'EMPRESA_ADMIN' || r.rol == 'SUPER_ADMIN',
      );

  /// Sedes sobre las que el usuario puede OPERAR (POS): los admin de empresa ven
  /// todas; el resto solo las asignadas (UsuarioSedeRol). Si un no-admin no tiene
  /// ninguna asignada (legacy aún sin migrar), cae a todas — coherente con el
  /// enforcement progresivo del backend (SedeAccessGuard).
  List<Sede> get sedesOperables {
    if (esAdminEmpresa) return sedes;
    final asignadas = sedes.where((s) => s.asignada).toList();
    return asignadas.isNotEmpty ? asignadas : sedes;
  }

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
        planLimits,
        caracteristicas,
        yapeMaxPorTransaccion,
        yapeMaxPorDia,
      ];
}
