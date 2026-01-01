import 'package:equatable/equatable.dart';
import 'auth_tokens.dart';
import 'mode_option.dart';
import 'tenant.dart';
import 'user.dart';

/// Respuesta completa de autenticación (login/register)
class AuthResponse extends Equatable {
  final User user;
  final Tenant? tenant;
  final AuthTokens? tokens;

  /// Modo de login actual: 'marketplace' | 'management'
  final String? mode;

  /// Indica si se requiere que el usuario seleccione un modo
  final bool? requiresSelection;

  /// Mensaje a mostrar al usuario
  final String? message;

  /// Opciones de modo disponibles (marketplace, management con empresas)
  final List<ModeOption>? options;

  const AuthResponse({
    required this.user,
    this.tenant,
    this.tokens,
    this.mode,
    this.requiresSelection,
    this.message,
    this.options,
  });

  /// Indica si se requiere selección de modo
  bool get needsModeSelection => requiresSelection ?? false;

  /// Indica si la respuesta incluye tokens de autenticación
  bool get hasTokens => tokens != null;

  /// Indica si es modo marketplace
  bool get isMarketplaceMode => mode == 'marketplace';

  /// Indica si es modo management
  bool get isManagementMode => mode == 'management';

  /// Obtiene la opción de marketplace
  ModeOption? get marketplaceOption {
    if (options == null || options!.isEmpty) {
      return const ModeOption(
        type: 'marketplace',
        label: 'Ver Marketplace',
        description: 'Explorar productos y servicios',
      );
    }
    try {
      return options!.firstWhere((o) => o.type == 'marketplace');
    } catch (e) {
      return const ModeOption(
        type: 'marketplace',
        label: 'Ver Marketplace',
        description: 'Explorar productos y servicios',
      );
    }
  }

  /// Obtiene la opción de management
  ModeOption? get managementOption {
    if (options == null || options!.isEmpty) return null;
    try {
      return options!.firstWhere((o) => o.type == 'management');
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        user,
        tenant,
        tokens,
        mode,
        requiresSelection,
        message,
        options,
      ];
}
