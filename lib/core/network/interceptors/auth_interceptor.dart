import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../constants/constants.dart';
import '../../storage/storage.dart';

/// Interceptor para agregar el token de autenticación a las peticiones
@injectable
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthInterceptor(
    this._secureStorage,
    this._localStorage,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Obtener y agregar el access token del almacenamiento seguro
    final accessToken = await _secureStorage.read(
      key: StorageConstants.accessToken,
    );

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers[ApiConstants.authorization] = 'Bearer $accessToken';
    }

    // Agregar tenant ID si existe (excepto para el endpoint de switch-tenant)
    final isSwitchTenantEndpoint = options.path.contains('/auth/switch-tenant');

    if (!isSwitchTenantEndpoint) {
      final tenantId = _localStorage.getString(StorageConstants.tenantId);
      if (tenantId != null && tenantId.isNotEmpty) {
        options.headers[ApiConstants.tenantId] = tenantId;
      }
    }

    handler.next(options);
  }
}
