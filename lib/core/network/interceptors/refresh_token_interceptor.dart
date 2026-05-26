import 'dart:async';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../constants/constants.dart';
import '../../errors/exceptions.dart';
import '../../services/session_expired_notifier.dart';
import '../../storage/storage.dart';

/// Interceptor para refrescar automáticamente el token cuando expira
@injectable
class RefreshTokenInterceptor extends QueuedInterceptorsWrapper {
  final SecureStorageService _secureStorage;
  final Dio _dio;
  final SessionExpiredNotifier _sessionExpiredNotifier;

  // Lock para prevenir múltiples refreshes simultáneos
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  RefreshTokenInterceptor(
    this._secureStorage,
    @Named('authDio') this._dio,
    this._sessionExpiredNotifier,
  );

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Solo intentar refresh en errores 401 que no sean de endpoints de autenticación
    final isAuthEndpoint = err.requestOptions.path.contains(ApiConstants.refreshToken) ||
        err.requestOptions.path.contains(ApiConstants.login) ||
        err.requestOptions.path.contains(ApiConstants.register) ||
        err.requestOptions.path.contains('/logout') ||
        err.requestOptions.path.contains('/auth/autorizar-operacion');

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      try {
        // Intentar refrescar el token
        await _refreshAccessToken();

        // Reintentar el request original con el nuevo token
        final options = err.requestOptions;

        // Obtener el nuevo access token
        final newAccessToken = await _secureStorage.read(
          key: StorageConstants.accessToken,
        );

        // Actualizar el header con el nuevo token
        if (newAccessToken != null) {
          options.headers[ApiConstants.authorization] = 'Bearer $newAccessToken';
        }

        // Reintentar el request
        final response = await _dio.request(
          options.path,
          options: Options(
            method: options.method,
            headers: options.headers,
          ),
          data: options.data,
          queryParameters: options.queryParameters,
        );

        // Retornar la respuesta exitosa
        return handler.resolve(response);
      } catch (e) {
        // Si el refresh falla, la sesión está realmente terminada
        // (revocada por admin, refresh token expirado, usuario
        // desactivado). Notificamos al AuthBloc para que dispare
        // logout y expulse al usuario a la pantalla de login.
        final reason = err.response?.data is Map &&
                (err.response!.data as Map)['message'] is String
            ? (err.response!.data as Map)['message'] as String
            : 'Sesión expirada. Por favor, inicia sesión nuevamente.';
        _sessionExpiredNotifier.notify(reason);

        // Propagar el error original
        return handler.next(err);
      }
    }

    // Para otros errores, continuar normalmente
    return handler.next(err);
  }

  /// Refresca el access token usando el refresh token
  Future<void> _refreshAccessToken() async {
    // Si ya hay un refresh en progreso, esperar a que termine
    if (_isRefreshing) {
      await _refreshCompleter?.future;
      return;
    }

    // Marcar que estamos refrescando
    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      // Obtener el refresh token actual
      final refreshToken = await _secureStorage.read(
        key: StorageConstants.refreshToken,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        throw AuthenticationException(
          message: 'No hay refresh token disponible',
        );
      }

      // Llamar al endpoint de refresh (sin interceptores para evitar loop)
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            ApiConstants.contentType: 'application/json',
            ApiConstants.accept: 'application/json',
          },
        ),
      );

      // Extraer los nuevos tokens de la respuesta
      final accessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (accessToken == null || newRefreshToken == null) {
        throw AuthenticationException(
          message: 'Respuesta de refresh inválida',
        );
      }

      // Guardar los nuevos tokens
      await _secureStorage.write(
        key: StorageConstants.accessToken,
        value: accessToken,
      );
      await _secureStorage.write(
        key: StorageConstants.refreshToken,
        value: newRefreshToken,
      );

      // Marcar como completado
      _refreshCompleter?.complete();
    } catch (e) {
      // Propagar el error
      _refreshCompleter?.completeError(e);
      rethrow;
    } finally {
      // Resetear el estado
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
}
