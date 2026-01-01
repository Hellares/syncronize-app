import 'package:injectable/injectable.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/empresa.dart';
import '../../domain/entities/rubro_empresa.dart';
import '../../domain/entities/session_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_methods_response.dart';
import '../../domain/entities/set_password_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ErrorHandlerService errorHandler;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.errorHandler,
  });

  @override
  Future<Resource<AuthResponse>> register({
    String? email,
    String? password,
    required String nombres,
    required String apellidos,
    String? telefono,
    String? dni,
    bool? esClienteSinEmail,
    String? subdominioEmpresa,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        dni: dni,
        esClienteSinEmail: esClienteSinEmail,
        subdominioEmpresa: subdominioEmpresa,
      );

      final authResponse = result.toEntity();

      // Solo guardar tokens si la respuesta incluye tokens
      if (authResponse.hasTokens && authResponse.tokens != null) {
        await localDataSource.saveTokens(
          AuthTokensModel.fromEntity(authResponse.tokens!),
        );
        await localDataSource.saveUserInfo(
          UserModel.fromEntity(authResponse.user),
        );
        if (authResponse.tenant != null) {
          await localDataSource.saveTenantInfo(
            tenantId: authResponse.tenant!.id,
            tenantName: authResponse.tenant!.name,
            tenantRole: authResponse.tenant!.role,
          );
        }
        await localDataSource.setLoggedIn(true);
      }

      return Success(authResponse);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Register',
        defaultMessage: 'Error al registrar usuario',
      );
    }
  }

  @override
  Future<Resource<AuthResponse>> login({
    required String credencial,
    required String password,
    String? subdominioEmpresa,
    String? loginMode,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.login(
        credencial: credencial,
        password: password,
        subdominioEmpresa: subdominioEmpresa,
        loginMode: loginMode,
      );

      final authResponse = result.toEntity();

      // Solo guardar tokens si la respuesta incluye tokens
      // (no cuando requiresSelection es true)
      if (authResponse.hasTokens && authResponse.tokens != null) {
        await localDataSource.saveTokens(
          AuthTokensModel.fromEntity(authResponse.tokens!),
        );
        await localDataSource.saveUserInfo(
          UserModel.fromEntity(authResponse.user),
        );
        // Guardar modo de login
        if (authResponse.mode != null) {
          await localDataSource.saveLoginMode(authResponse.mode!);
        }
        if (authResponse.tenant != null) {
          await localDataSource.saveTenantInfo(
            tenantId: authResponse.tenant!.id,
            tenantName: authResponse.tenant!.name,
            tenantRole: authResponse.tenant!.role,
          );
        }
        await localDataSource.setLoggedIn(true);
      }

      return Success(authResponse);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Login',
        defaultMessage: 'Error al iniciar sesión',
      );
    }
  }

  @override
  Future<Resource<AuthResponse>> signInWithGoogle({
    required String idToken,
    String? subdominioEmpresa,
    String? loginMode,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.signInWithGoogle(
        idToken: idToken,
        subdominioEmpresa: subdominioEmpresa,
        loginMode: loginMode,
      );

      final authResponse = result.toEntity();

      // Guardar tokens y datos del usuario solo si los hay (no cuando requiere selección de modo)
      if (authResponse.hasTokens && authResponse.tokens != null) {
        await localDataSource.saveTokens(
          AuthTokensModel.fromEntity(authResponse.tokens!),
        );
        await localDataSource.saveUserInfo(
          UserModel.fromEntity(authResponse.user),
        );
        // Guardar modo de login
        if (authResponse.mode != null) {
          await localDataSource.saveLoginMode(authResponse.mode!);
        }
        if (authResponse.tenant != null) {
          await localDataSource.saveTenantInfo(
            tenantId: authResponse.tenant!.id,
            tenantName: authResponse.tenant!.name,
            tenantRole: authResponse.tenant!.role,
          );
        }
        await localDataSource.setLoggedIn(true);
      }

      return Success(authResponse);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Google Sign-In',
        defaultMessage: 'Error al iniciar sesión con Google',
      );
    }
  }

  @override
  Future<Resource<void>> logout() async {
    try {
      // Intentar cerrar sesión en el servidor (si hay conexión)
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (e) {
          // Continuar con el logout local aunque falle el remoto
        }
      }

      // Limpiar datos locales siempre
      await localDataSource.clearAll();

      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'Logout',
        defaultMessage: 'Error al cerrar sesión',
      );
    }
  }

  @override
  Future<Resource<AuthTokens>> refreshToken({
    required String refreshToken,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );

      final tokens = result.toEntity();

      // Guardar nuevos tokens
      await localDataSource.saveTokens(result);

      return Success(tokens);
    } on TokenExpiredException catch (e) {
      // Si el refresh token expiró, limpiar datos locales
      await localDataSource.clearAll();
      return errorHandler.handleException(
        e,
        context: 'RefreshToken',
        defaultMessage: 'Tu sesión ha expirado',
      );
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'RefreshToken',
        defaultMessage: 'Error al refrescar token',
      );
    }
  }

  @override
  Future<Resource<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'ChangePassword',
        defaultMessage: 'Error al cambiar contraseña',
      );
    }
  }

  @override
  Future<Resource<void>> forgotPassword({
    required String email,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.forgotPassword(email: email);
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'ForgotPassword',
        defaultMessage: 'Error al solicitar recuperación',
      );
    }
  }

  @override
  Future<Resource<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'ResetPassword',
        defaultMessage: 'Error al resetear contraseña',
      );
    }
  }

  @override
  Future<Resource<void>> verifyEmail({
    required String token,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.verifyEmail(token: token);
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'VerifyEmail',
        defaultMessage: 'Error al verificar email',
      );
    }
  }

  @override
  Future<Resource<void>> resendVerificationEmail({
    required String email,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.resendVerificationEmail(email: email);
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'ResendVerificationEmail',
        defaultMessage: 'Error al reenviar email de verificación',
      );
    }
  }

  @override
  Future<Resource<User>> getProfile() async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.getProfile();
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'GetProfile',
        defaultMessage: 'Error al obtener perfil',
      );
    }
  }

  @override
  Future<Resource<List<SessionInfo>>> getSessions() async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await remoteDataSource.getSessions();
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'GetSessions',
        defaultMessage: 'Error al obtener sesiones',
      );
    }
  }

  @override
  Future<Resource<void>> revokeSession({
    required String sessionId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.revokeSession(sessionId: sessionId);
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'RevokeSession',
        defaultMessage: 'Error al revocar sesión',
      );
    }
  }

  @override
  Future<Resource<void>> revokeOtherSessions() async {
    if (!await networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      await remoteDataSource.revokeOtherSessions();
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'RevokeOtherSessions',
        defaultMessage: 'Error al revocar sesiones',
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Resource<AuthTokens?>> getLocalTokens() async {
    try {
      final tokens = await localDataSource.getTokens();
      return Success(tokens?.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'GetLocalTokens',
        defaultMessage: 'Error al obtener tokens',
      );
    }
  }

  @override
  Future<Resource<void>> saveTokens({
    required AuthTokens tokens,
  }) async {
    try {
      await localDataSource.saveTokens(AuthTokensModel.fromEntity(tokens));
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'SaveTokens',
        defaultMessage: 'Error al guardar tokens',
      );
    }
  }

  @override
  Future<Resource<void>> saveUserInfo({
    required User user,
  }) async {
    try {
      await localDataSource.saveUserInfo(UserModel.fromEntity(user));
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'SaveUserInfo',
        defaultMessage: 'Error al guardar usuario',
      );
    }
  }

  @override
  Future<Resource<void>> clearLocalAuth() async {
    try {
      await localDataSource.clearAll();
      return Success(null);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'ClearLocalAuth',
        defaultMessage: 'Error al limpiar datos',
      );
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.createEmpresa(
        nombre: nombre,
        rubro: rubro,
        ruc: ruc,
        descripcion: descripcion,
        telefono: telefono,
        email: email,
        web: web,
        subdominio: subdominio,
        logo: logo,
        categoriasMaestrasIds: categoriasMaestrasIds,
        marcasMaestrasIds: marcasMaestrasIds,
      );

      final empresa = result.toEntity();

      return Success(empresa);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'CreateEmpresa',
        defaultMessage: 'Error al crear empresa',
      );
    }
  }

  @override
  Future<Resource<AuthMethodsResponse>> checkAuthMethods(String email) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.checkAuthMethods(email: email);
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'CheckAuthMethods',
        defaultMessage: 'Error al verificar métodos de autenticación',
      );
    }
  }

  @override
  Future<Resource<SetPasswordResponse>> setPassword(String password) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.setPassword(password: password);
      return Success(result.toEntity());
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'SetPassword',
        defaultMessage: 'Error al establecer contraseña',
      );
    }
  }
}
