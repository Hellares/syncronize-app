import '../../../../core/utils/resource.dart';
import '../entities/auth_response.dart';
import '../entities/auth_tokens.dart';
import '../entities/empresa.dart';
import '../entities/rubro_empresa.dart';
import '../entities/session_info.dart';
import '../entities/user.dart';
import '../entities/auth_methods_response.dart';
import '../entities/set_password_response.dart';

/// Contrato del repositorio de autenticación
abstract class AuthRepository {
  /// Registrar un nuevo usuario
  Future<Resource<AuthResponse>> register({
    String? email,
    String? password,
    required String nombres,
    required String apellidos,
    String? telefono,
    String? dni,
    bool? esClienteSinEmail,
    String? subdominioEmpresa,
  });

  /// Iniciar sesión (con credencial: email o DNI)
  Future<Resource<AuthResponse>> login({
    required String credencial, // Puede ser email o DNI
    required String password,
    String? subdominioEmpresa,
    String? loginMode, // 'marketplace' | 'management'
  });

  /// Iniciar sesión con Google (usando ID Token)
  Future<Resource<AuthResponse>> signInWithGoogle({
    required String idToken,
    String? subdominioEmpresa,
    String? loginMode, // 'marketplace' | 'management'
  });

  /// Cerrar sesión
  Future<Resource<void>> logout();

  /// Refrescar token de acceso
  Future<Resource<AuthTokens>> refreshToken({
    required String refreshToken,
  });

  /// Cambiar contraseña
  Future<Resource<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Solicitar recuperación de contraseña
  Future<Resource<void>> forgotPassword({
    required String email,
  });

  /// Resetear contraseña con token
  Future<Resource<void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Verificar email
  Future<Resource<void>> verifyEmail({
    required String token,
  });

  /// Reenviar email de verificación
  Future<Resource<void>> resendVerificationEmail({
    required String email,
  });

  /// Obtener perfil del usuario
  Future<Resource<User>> getProfile();

  /// Obtener sesiones activas
  Future<Resource<List<SessionInfo>>> getSessions();

  /// Revocar una sesión específica
  Future<Resource<void>> revokeSession({
    required String sessionId,
  });

  /// Revocar todas las sesiones excepto la actual
  Future<Resource<void>> revokeOtherSessions();

  /// Verificar si el usuario está autenticado localmente
  Future<bool> isAuthenticated();

  /// Obtener tokens guardados localmente
  Future<Resource<AuthTokens?>> getLocalTokens();

  /// Guardar tokens localmente
  Future<Resource<void>> saveTokens({
    required AuthTokens tokens,
  });

  /// Guardar información del usuario localmente
  Future<Resource<void>> saveUserInfo({
    required User user,
  });

  /// Limpiar datos de autenticación locales
  Future<Resource<void>> clearLocalAuth();

  /// Crear una nueva empresa
  Future<Resource<Empresa>> createEmpresa({
    required String nombre,
    required RubroEmpresa rubro,
    String? ruc,
    String? descripcion,
    String? telefono,
    String? email,
    String? web,
    String? subdominio,
    String? logo,
    List<String>? categoriasMaestrasIds,
    List<String>? marcasMaestrasIds,
  });

  /// Verificar métodos de autenticación disponibles para un email
  Future<Resource<AuthMethodsResponse>> checkAuthMethods(String email);

  /// Establecer contraseña para usuario autenticado (OAuth users)
  Future<Resource<SetPasswordResponse>> setPassword(String password);
}
