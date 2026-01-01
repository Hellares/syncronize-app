import 'package:injectable/injectable.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/storage.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// Interfaz del datasource local de autenticación
abstract class AuthLocalDataSource {
  Future<void> saveTokens(AuthTokensModel tokens);
  Future<AuthTokensModel?> getTokens();
  Future<void> deleteTokens();

  Future<void> saveUserInfo(UserModel user);
  Future<UserModel?> getUserInfo();
  Future<void> deleteUserInfo();

  Future<void> saveTenantInfo({
    required String tenantId,
    required String tenantName,
    required String tenantRole,
  });
  Future<Map<String, String?>?> getTenantInfo();
  Future<void> deleteTenantInfo();

  Future<void> saveLoginMode(String mode);
  Future<String?> getLoginMode();
  Future<void> deleteLoginMode();

  Future<void> setLoggedIn(bool isLoggedIn);
  Future<bool> isLoggedIn();

  Future<void> clearAll();
}

/// Implementación del datasource local
@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthLocalDataSourceImpl(
    this._secureStorage,
    this._localStorage,
  );

  @override
  Future<void> saveTokens(AuthTokensModel tokens) async {
    try {
      await _secureStorage.write(
        key: StorageConstants.accessToken,
        value: tokens.accessToken,
      );
      await _secureStorage.write(
        key: StorageConstants.refreshToken,
        value: tokens.refreshToken,
      );
    } catch (e) {
      throw CacheException(message: 'Error al guardar tokens: $e');
    }
  }

  @override
  Future<AuthTokensModel?> getTokens() async {
    try {
      final accessToken = await _secureStorage.read(
        key: StorageConstants.accessToken,
      );
      final refreshToken = await _secureStorage.read(
        key: StorageConstants.refreshToken,
      );

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      return AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: '3600', // Default, se actualiza en cada login
      );
    } catch (e) {
      throw CacheException(message: 'Error al leer tokens: $e');
    }
  }

  @override
  Future<void> deleteTokens() async {
    try {
      await _secureStorage.delete(key: StorageConstants.accessToken);
      await _secureStorage.delete(key: StorageConstants.refreshToken);
    } catch (e) {
      throw CacheException(message: 'Error al eliminar tokens: $e');
    }
  }

  @override
  Future<void> saveUserInfo(UserModel user) async {
    try {
      await _localStorage.setString(StorageConstants.userId, user.id);
      // Guardar email solo si existe, sino guardar string vacío
      await _localStorage.setString(StorageConstants.userEmail, user.email ?? '');
      await _localStorage.setString(StorageConstants.userNombres, user.nombres);
      await _localStorage.setString(
        StorageConstants.userApellidos,
        user.apellidos,
      );
      // Guardar DNI si existe
      if (user.dni != null) {
        await _localStorage.setString('user_dni', user.dni!);
      }
    } catch (e) {
      throw CacheException(message: 'Error al guardar info de usuario: $e');
    }
  }

  @override
  Future<UserModel?> getUserInfo() async {
    try {
      final userId = _localStorage.getString(StorageConstants.userId);
      if (userId == null) return null;

      final email = _localStorage.getString(StorageConstants.userEmail);
      final nombres = _localStorage.getString(StorageConstants.userNombres);
      final apellidos = _localStorage.getString(StorageConstants.userApellidos);

      if (email == null || nombres == null || apellidos == null) {
        return null;
      }

      // Retornar un UserModel básico con la info guardada
      // Los campos completos se obtendrán del servidor
      return UserModel(
        id: userId,
        email: email,
        nombres: nombres,
        apellidos: apellidos,
        emailVerificado: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw CacheException(message: 'Error al leer info de usuario: $e');
    }
  }

  @override
  Future<void> deleteUserInfo() async {
    try {
      await _localStorage.remove(StorageConstants.userId);
      await _localStorage.remove(StorageConstants.userEmail);
      await _localStorage.remove(StorageConstants.userNombres);
      await _localStorage.remove(StorageConstants.userApellidos);
    } catch (e) {
      throw CacheException(message: 'Error al eliminar info de usuario: $e');
    }
  }

  @override
  Future<void> saveTenantInfo({
    required String tenantId,
    required String tenantName,
    required String tenantRole,
  }) async {
    try {
      await _localStorage.setString(StorageConstants.tenantId, tenantId);
      await _localStorage.setString(StorageConstants.tenantName, tenantName);
      await _localStorage.setString(StorageConstants.tenantRole, tenantRole);
    } catch (e) {
      throw CacheException(message: 'Error al guardar info de tenant: $e');
    }
  }

  @override
  Future<Map<String, String?>?> getTenantInfo() async {
    try {
      final tenantId = _localStorage.getString(StorageConstants.tenantId);
      if (tenantId == null) return null;

      return {
        'id': tenantId,
        'name': _localStorage.getString(StorageConstants.tenantName),
        'role': _localStorage.getString(StorageConstants.tenantRole),
      };
    } catch (e) {
      throw CacheException(message: 'Error al leer info de tenant: $e');
    }
  }

  @override
  Future<void> deleteTenantInfo() async {
    try {
      await _localStorage.remove(StorageConstants.tenantId);
      await _localStorage.remove(StorageConstants.tenantName);
      await _localStorage.remove(StorageConstants.tenantRole);
    } catch (e) {
      throw CacheException(message: 'Error al eliminar info de tenant: $e');
    }
  }

  @override
  Future<void> saveLoginMode(String mode) async {
    try {
      await _localStorage.setString(StorageConstants.loginMode, mode);
    } catch (e) {
      throw CacheException(message: 'Error al guardar modo de login: $e');
    }
  }

  @override
  Future<String?> getLoginMode() async {
    try {
      return _localStorage.getString(StorageConstants.loginMode);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteLoginMode() async {
    try {
      await _localStorage.remove(StorageConstants.loginMode);
    } catch (e) {
      throw CacheException(message: 'Error al eliminar modo de login: $e');
    }
  }

  @override
  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      await _localStorage.setBool(StorageConstants.isLoggedIn, isLoggedIn);
    } catch (e) {
      throw CacheException(message: 'Error al guardar estado de login: $e');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      return _localStorage.getBool(StorageConstants.isLoggedIn) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await deleteTokens();
      await deleteUserInfo();
      await deleteTenantInfo();
      await deleteLoginMode();
      await setLoggedIn(false);
    } catch (e) {
      throw CacheException(message: 'Error al limpiar datos: $e');
    }
  }
}
