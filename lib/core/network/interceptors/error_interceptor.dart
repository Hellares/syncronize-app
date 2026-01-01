import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../errors/exceptions.dart';
import '../../utils/log_sanitizer.dart';

/// Interceptor para manejar errores de red con sanitización de datos sensibles
@injectable
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException(
          message: 'La conexión tardó demasiado tiempo. Intenta nuevamente.',
        );

      case DioExceptionType.badResponse:
        _handleResponseError(err);
        break;

      case DioExceptionType.cancel:
        throw Exception('Solicitud cancelada');

      case DioExceptionType.connectionError:
        throw NetworkException(
          message: 'Error de conexión. Verifica tu conexión a internet.',
        );

      default:
        // Sanitizar el mensaje de error antes de lanzar la excepción
        final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(
          err.message ?? 'Error de red inesperado',
        );
        throw NetworkException(
          message: 'Error de red inesperado: $sanitizedMessage',
        );
    }

    handler.next(err);
  }

  void _handleResponseError(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    String message = 'Error del servidor';

    // Sanitizar el data antes de procesarlo
    final sanitizedData = LogSanitizer.sanitizeBody(data);

    // Intentar extraer el mensaje del backend (del data sanitizado)
    if (sanitizedData is Map<String, dynamic>) {
      message = sanitizedData['message'] ?? message;
    }

    // Sanitizar el mensaje de error
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);

    switch (statusCode) {
      case 400:
        // Bad Request - puede incluir errores de validación
        if (sanitizedData is Map<String, dynamic> &&
            sanitizedData.containsKey('errors')) {
          final errors = sanitizedData['errors'] as Map<String, dynamic>?;
          throw ValidationException(
            message: sanitizedMessage,
            errors: errors?.map(
              (key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              ),
            ),
          );
        }
        throw ValidationException(message: sanitizedMessage);

      case 401:
        if (sanitizedMessage.toLowerCase().contains('token') &&
            sanitizedMessage.toLowerCase().contains('expirado')) {
          throw TokenExpiredException(message: sanitizedMessage);
        }
        throw AuthenticationException(
          message: sanitizedMessage,
          statusCode: statusCode,
        );

      case 403:
        throw AuthorizationException(message: sanitizedMessage);

      case 404:
        throw ServerException(
          message: 'Recurso no encontrado',
          statusCode: statusCode,
        );

      case 409:
        throw ServerException(
          message: sanitizedMessage,
          statusCode: statusCode,
        );

      case 422:
        throw ValidationException(message: sanitizedMessage);

      case 429:
        // Too Many Requests - Rate limiting
        final retryAfter = err.response?.headers.value('retry-after');
        final retrySeconds = retryAfter != null ? int.tryParse(retryAfter) : null;

        throw RateLimitException(
          message: 'Demasiados intentos. Por favor, espera un momento e intenta nuevamente.',
          retryAfter: retrySeconds,
        );

      case 500:
      case 502:
      case 503:
        throw ServerException(
          message: 'Error del servidor. Intenta más tarde.',
          statusCode: statusCode,
        );

      default:
        throw ServerException(
          message: sanitizedMessage,
          statusCode: statusCode,
        );
    }
  }
}
