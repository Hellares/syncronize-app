import 'package:equatable/equatable.dart';

/// Entidad que representa la información de rol del usuario en la empresa
class UserRoleInfo extends Equatable {
  final String id;
  final String rol;
  final bool isActive;
  final String estado;
  final DateTime? fechaAprobacion;

  const UserRoleInfo({
    required this.id,
    required this.rol,
    required this.isActive,
    required this.estado,
    this.fechaAprobacion,
  });

  /// Indica si el rol es administrativo
  bool get isAdminRole =>
      rol == 'SUPER_ADMIN' || rol == 'EMPRESA_ADMIN' || rol == 'SEDE_ADMIN';

  /// Indica si el usuario está activo en este rol
  bool get isActiveAndApproved => isActive && estado == 'ACTIVO';

  @override
  List<Object?> get props => [
        id,
        rol,
        isActive,
        estado,
        fechaAprobacion,
      ];
}
