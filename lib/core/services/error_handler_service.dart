import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../errors/exceptions.dart';
import '../utils/resource.dart';
import 'logger_service.dart';

/// Servicio centralizado para manejo de errores
///
/// Este servicio convierte excepciones en objetos Resource con mensajes
/// amigables para el usuario. Integra automáticamente el logging de errores.
@lazySingleton
class ErrorHandlerService {
  final LoggerService _logger;

  ErrorHandlerService(this._logger);

  /// Maneja cualquier excepción y la convierte en un Resource Error
  ///
  /// Parámetros:
  /// - [exception]: La excepción a manejar
  /// - [context]: Contexto opcional para logging (ej: 'Login', 'Register')
  /// - [defaultMessage]: Mensaje por defecto si no se puede determinar uno específico
  ///
  /// Ejemplo:
  /// ```dart
  /// try {
  ///   final response = await _authApi.login(email, password);
  ///   return Success(response);
  /// } catch (e) {
  ///   return _errorHandler.handleException(
  ///     e,
  ///     context: 'Login',
  ///     defaultMessage: 'Error al iniciar sesión',
  ///   );
  /// }
  /// ```
  Resource<T> handleException<T>(
    Object exception, {
    String? context,
    String defaultMessage = 'Error inesperado',
  }) {
    // Log el error automáticamente
    _logger.error(
      '[$context] Error capturado',
      tag: context,
      exception: exception,
      stackTrace: exception is Exception ? StackTrace.current : null,
    );

    // Si es un DioException, extraer la excepción interna
    if (exception is DioException && exception.error != null) {
      return _handleInnerException<T>(
        exception.error!,
        context: context,
        defaultMessage: defaultMessage,
      );
    }

    // Manejar excepciones personalizadas
    return _handleInnerException<T>(
      exception,
      context: context,
      defaultMessage: defaultMessage,
    );
  }

  /// Maneja la excepción interna (después de extraer de DioException)
  Resource<T> _handleInnerException<T>(
    Object exception, {
    String? context,
    required String defaultMessage,
  }) {
    // RateLimitException
    if (exception is RateLimitException) {
      return Error(
        exception.retryAfter != null
            ? 'Demasiados intentos. Por favor, espera ${exception.retryAfter} segundos e intenta nuevamente.'
            : exception.message,
        errorCode: 'RATE_LIMIT',
        statusCode: 429,
      );
    }

    // AuthenticationException
    if (exception is AuthenticationException) {
      return Error(
        exception.message,
        errorCode: 'AUTHENTICATION_ERROR',
        statusCode: exception.statusCode,
      );
    }

    // TokenExpiredException
    if (exception is TokenExpiredException) {
      return Error(
        'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
        errorCode: 'TOKEN_EXPIRED',
        statusCode: 401,
      );
    }

    // AuthorizationException
    if (exception is AuthorizationException) {
      return Error(
        exception.message,
        errorCode: 'AUTHORIZATION_ERROR',
        statusCode: 403,
      );
    }

    // ValidationException
    if (exception is ValidationException) {
      return Error(
        exception.message,
        errorCode: 'VALIDATION_ERROR',
        statusCode: 400,
      );
    }

    // NetworkException
    if (exception is NetworkException) {
      return Error(
        exception.message,
        errorCode: 'NETWORK_ERROR',
      );
    }

    // TimeoutException
    if (exception is TimeoutException) {
      return Error(
        exception.message,
        errorCode: 'TIMEOUT_ERROR',
      );
    }

    // ServerException
    if (exception is ServerException) {
      return Error(
        exception.message,
        errorCode: 'SERVER_ERROR',
        statusCode: exception.statusCode,
      );
    }

    // CacheException
    if (exception is CacheException) {
      return Error(
        exception.message,
        errorCode: 'CACHE_ERROR',
      );
    }

    // Excepción genérica no manejada
    _logger.warning(
      '[$context] Excepción no manejada específicamente: ${exception.runtimeType}',
    );

    return Error(
      defaultMessage,
      errorCode: 'UNKNOWN_ERROR',
    );
  }

  /// Versión async de handleException para uso con Future
  ///
  /// Ejemplo:
  /// ```dart
  /// return _errorHandler.handleExceptionAsync<UserModel>(
  ///   () async => await _authApi.login(email, password),
  ///   context: 'Login',
  ///   defaultMessage: 'Error al iniciar sesión',
  /// );
  /// ```
  Future<Resource<T>> handleExceptionAsync<T>(
    Future<T> Function() operation, {
    String? context,
    String defaultMessage = 'Error inesperado',
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e) {
      return handleException<T>(
        e,
        context: context,
        defaultMessage: defaultMessage,
      );
    }
  }
}
