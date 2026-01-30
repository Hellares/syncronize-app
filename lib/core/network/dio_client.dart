import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../config/environment/env_config.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';
import 'interceptors/sanitized_logging_interceptor.dart';

/// Cliente HTTP basado en Dio
@lazySingleton
class DioClient {
  late final Dio _dio;

  DioClient({
    required AuthInterceptor authInterceptor,
    required ErrorInterceptor errorInterceptor,
    required RefreshTokenInterceptor refreshTokenInterceptor,
    required SanitizedLoggingInterceptor sanitizedLoggingInterceptor,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          ApiConstants.contentType: 'application/json',
          ApiConstants.accept: 'application/json',
        },
      ),
    );

    // Agregar interceptores en orden específico:
    // 1. RefreshTokenInterceptor - Refresca token si ha expirado
    // 2. AuthInterceptor - Agrega Authorization y X-Tenant-ID headers
    // 3. SanitizedLoggingInterceptor - Loguea todo (después de agregar headers)
    // 4. ErrorInterceptor - Maneja errores HTTP
    _dio.interceptors.addAll([
      refreshTokenInterceptor,
      authInterceptor,
      // Logging sanitizado - loguea DESPUÉS de que authInterceptor agregue headers
      if (EnvConfig.enablePrettyLogger) sanitizedLoggingInterceptor,
      errorInterceptor,
    ]);
  }

  /// Obtener instancia de Dio
  Dio get dio => _dio;

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    void Function(int, int)? onSendProgress,
  }) async {

    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
