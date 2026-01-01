import 'package:injectable/injectable.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/rubro_empresa.dart';
import '../models/auth_response_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/empresa_model.dart';
import '../models/session_info_model.dart';
import '../models/user_model.dart';
import '../models/auth_methods_response_model.dart';
import '../models/set_password_response_model.dart';

/// Interfaz del datasource remoto de autenticación
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    String? email,
    String? password,
    required String nombres,
    required String apellidos,
    String? telefono,
    String? dni,
    bool? esClienteSinEmail,
    String? subdominioEmpresa,
  });

  Future<AuthResponseModel> login({
    required String credencial, // Puede ser email o DNI
    required String password,
    String? subdominioEmpresa,
    String? loginMode,
  });

  Future<AuthResponseModel> signInWithGoogle({
    required String idToken,
    String? subdominioEmpresa,
    String? loginMode,
  });

  Future<void> logout();

  Future<AuthTokensModel> refreshToken({
    required String refreshToken,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> forgotPassword({
    required String email,
  });

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<void> verifyEmail({
    required String token,
  });

  Future<void> resendVerificationEmail({
    required String email,
  });

  Future<UserModel> getProfile();

  Future<List<SessionInfoModel>> getSessions();

  Future<void> revokeSession({
    required String sessionId,
  });

  Future<void> revokeOtherSessions();

  Future<EmpresaModel> createEmpresa({
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
  Future<AuthMethodsResponseModel> checkAuthMethods({
    required String email,
  });

  /// Establecer contraseña para usuario autenticado (OAuth users)
  Future<SetPasswordResponseModel> setPassword({
    required String password,
  });
}

/// Implementación del datasource remoto
@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<AuthResponseModel> register({
    String? email,
    String? password,
    required String nombres,
    required String apellidos,
    String? telefono,
    String? dni,
    bool? esClienteSinEmail,
    String? subdominioEmpresa,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.register,
        data: {
          if (email != null) 'email': email,
          if (password != null) 'password': password,
          'nombres': nombres,
          'apellidos': apellidos,
          if (telefono != null) 'telefono': telefono,
          if (dni != null) 'dni': dni,
          if (esClienteSinEmail != null) 'esClienteSinEmail': esClienteSinEmail,
          if (subdominioEmpresa != null) 'subdominioEmpresa': subdominioEmpresa,
        },
      );

      return AuthResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> login({
    required String credencial,
    required String password,
    String? subdominioEmpresa,
    String? loginMode,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {
          'credencial': credencial,
          'password': password,
          if (subdominioEmpresa != null) 'subdominioEmpresa': subdominioEmpresa,
          if (loginMode != null) 'loginMode': loginMode,
        },
      );

      return AuthResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> signInWithGoogle({
    required String idToken,
    String? subdominioEmpresa,
    String? loginMode,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.googleSignIn,
        data: {
          'idToken': idToken,
          if (subdominioEmpresa != null) 'subdominioEmpresa': subdominioEmpresa,
          if (loginMode != null) 'loginMode': loginMode,
        },
      );

      return AuthResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthTokensModel> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
      );

      return AuthTokensModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      await _client.post(
        ApiConstants.forgotPassword,
        data: {
          'email': email,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyEmail({
    required String token,
  }) async {
    try {
      await _client.get('${ApiConstants.verifyEmail}/$token');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resendVerificationEmail({
    required String email,
  }) async {
    try {
      await _client.post(
        ApiConstants.resendVerificationEmail,
        data: {
          'email': email,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _client.get(ApiConstants.profile);
      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<SessionInfoModel>> getSessions() async {
    try {
      final response = await _client.get(ApiConstants.sessions);
      final List<dynamic> sessions = response.data;
      return sessions
          .map((session) => SessionInfoModel.fromJson(session))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
  }) async {
    try {
      await _client.delete('${ApiConstants.sessions}/$sessionId');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> revokeOtherSessions() async {
    try {
      await _client.delete('${ApiConstants.sessions}/others');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EmpresaModel> createEmpresa({
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
    try {
      final response = await _client.post(
        '${ApiConstants.empresas}/con-catalogos',
        data: {
          'nombre': nombre,
          'rubro': rubro.value,
          if (ruc != null && ruc.isNotEmpty) 'ruc': ruc,
          if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
          if (email != null && email.isNotEmpty) 'email': email,
          if (web != null && web.isNotEmpty) 'web': web,
          if (subdominio != null && subdominio.isNotEmpty) 'subdominio': subdominio,
          if (logo != null && logo.isNotEmpty) 'logo': logo,
          if (categoriasMaestrasIds != null && categoriasMaestrasIds.isNotEmpty)
            'categoriasMaestrasIds': categoriasMaestrasIds,
          if (marcasMaestrasIds != null && marcasMaestrasIds.isNotEmpty)
            'marcasMaestrasIds': marcasMaestrasIds,
        },
      );

      return EmpresaModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthMethodsResponseModel> checkAuthMethods({
    required String email,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.checkAuthMethods,
        data: {
          'email': email,
        },
      );

      return AuthMethodsResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SetPasswordResponseModel> setPassword({
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.setPassword,
        data: {
          'password': password,
        },
      );

      return SetPasswordResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
