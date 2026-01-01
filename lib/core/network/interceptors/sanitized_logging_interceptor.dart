import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../services/logger_service.dart';
import '../../utils/log_sanitizer.dart';

/// Interceptor para logging de peticiones HTTP con sanitización de datos sensibles
///
/// Este interceptor reemplaza o complementa TalkerDioLogger con sanitización
/// de tokens, contraseñas y otros datos sensibles antes de loguearlos.
@injectable
class SanitizedLoggingInterceptor extends Interceptor {
  final LoggerService _loggerService;

  SanitizedLoggingInterceptor(this._loggerService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logError(err);
    handler.next(err);
  }

  /// Loguea una petición HTTP sanitizada
  void _logRequest(RequestOptions options) {
    final method = options.method;
    final uri = options.uri.toString();

    // Sanitizar URL (por si tiene tokens en query params)
    final sanitizedUrl = LogSanitizer.sanitizeUrl(uri);

    // Sanitizar headers
    final sanitizedHeaders = LogSanitizer.sanitizeHeaders(
      options.headers.map((key, value) => MapEntry(key, value.toString())),
    );

    // Sanitizar query params
    final sanitizedQueryParams = LogSanitizer.sanitizeQueryParams(
      options.queryParameters,
    );

    // Sanitizar body
    final sanitizedData = LogSanitizer.sanitizeBody(options.data);

    // Log de la petición
    _loggerService.debug(
      '┌─────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    _loggerService.debug('│ 🌐 REQUEST', tag: 'HTTP');
    _loggerService.debug('│ $method $sanitizedUrl', tag: 'HTTP');

    if (sanitizedHeaders != null && sanitizedHeaders.isNotEmpty) {
      _loggerService.debug('│ Headers:', tag: 'HTTP');
      sanitizedHeaders.forEach((key, value) {
        _loggerService.debug('│   $key: $value', tag: 'HTTP');
      });
    }

    if (sanitizedQueryParams != null && sanitizedQueryParams.isNotEmpty) {
      _loggerService.debug('│ Query Parameters:', tag: 'HTTP');
      sanitizedQueryParams.forEach((key, value) {
        _loggerService.debug('│   $key: $value', tag: 'HTTP');
      });
    }

    if (sanitizedData != null) {
      _loggerService.debug('│ Body: $sanitizedData', tag: 'HTTP');
    }

    _loggerService.debug(
      '└─────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
  }

  /// Loguea una respuesta HTTP sanitizada
  void _logResponse(Response response) {
    final statusCode = response.statusCode;
    final method = response.requestOptions.method;
    final uri = response.requestOptions.uri.toString();

    // Sanitizar URL
    final sanitizedUrl = LogSanitizer.sanitizeUrl(uri);

    // Sanitizar headers de respuesta
    final sanitizedHeaders = LogSanitizer.sanitizeHeaders(
      response.headers.map.map((key, value) => MapEntry(key, value.join(', '))),
    );

    // Sanitizar body de respuesta
    final sanitizedData = LogSanitizer.sanitizeBody(response.data);

    // Determinar el emoji según el código de estado
    final emoji = _getStatusEmoji(statusCode);

    _loggerService.debug(
      '┌─────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    _loggerService.debug('│ $emoji RESPONSE', tag: 'HTTP');
    _loggerService.debug('│ $method $sanitizedUrl', tag: 'HTTP');
    _loggerService.debug('│ Status: $statusCode', tag: 'HTTP');

    if (sanitizedHeaders != null && sanitizedHeaders.isNotEmpty) {
      _loggerService.debug('│ Headers:', tag: 'HTTP');
      sanitizedHeaders.forEach((key, value) {
        _loggerService.debug('│   $key: $value', tag: 'HTTP');
      });
    }

    if (sanitizedData != null) {
      // Limitar el tamaño del body en logs
      final dataString = sanitizedData.toString();
      if (dataString.length > 1000) {
        _loggerService.debug(
          '│ Body: ${dataString.substring(0, 1000)}... (truncado)',
          tag: 'HTTP',
        );
      } else {
        _loggerService.debug('│ Body: $sanitizedData', tag: 'HTTP');
      }
    }

    _loggerService.debug(
      '└─────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
  }

  /// Loguea un error HTTP sanitizado
  void _logError(DioException err) {
    final method = err.requestOptions.method;
    final uri = err.requestOptions.uri.toString();
    final statusCode = err.response?.statusCode;

    // Sanitizar URL
    final sanitizedUrl = LogSanitizer.sanitizeUrl(uri);

    // Sanitizar mensaje de error
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(
      err.message ?? 'Error desconocido',
    );

    // Sanitizar response data si existe
    final sanitizedResponseData = err.response != null
        ? LogSanitizer.sanitizeBody(err.response!.data)
        : null;

    // Sanitizar headers de error
    final sanitizedHeaders = err.response?.headers != null
        ? LogSanitizer.sanitizeHeaders(
            err.response!.headers.map.map(
              (key, value) => MapEntry(key, value.join(', ')),
            ),
          )
        : null;

    _loggerService.error(
      '┌─────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    _loggerService.error('│ ❌ ERROR', tag: 'HTTP');
    _loggerService.error('│ $method $sanitizedUrl', tag: 'HTTP');

    if (statusCode != null) {
      _loggerService.error('│ Status: $statusCode', tag: 'HTTP');
    }

    _loggerService.error('│ Type: ${err.type}', tag: 'HTTP');
    _loggerService.error('│ Message: $sanitizedMessage', tag: 'HTTP');

    if (sanitizedHeaders != null && sanitizedHeaders.isNotEmpty) {
      _loggerService.error('│ Response Headers:', tag: 'HTTP');
      sanitizedHeaders.forEach((key, value) {
        _loggerService.error('│   $key: $value', tag: 'HTTP');
      });
    }

    if (sanitizedResponseData != null) {
      _loggerService.error(
        '│ Response: $sanitizedResponseData',
        tag: 'HTTP',
      );
    }

    _loggerService.error(
      '└─────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
  }

  /// Obtiene el emoji apropiado según el código de estado HTTP
  String _getStatusEmoji(int? statusCode) {
    if (statusCode == null) return '❓';

    if (statusCode >= 200 && statusCode < 300) {
      return '✅'; // Success
    } else if (statusCode >= 300 && statusCode < 400) {
      return '↪️'; // Redirect
    } else if (statusCode >= 400 && statusCode < 500) {
      return '⚠️'; // Client error
    } else if (statusCode >= 500) {
      return '❌'; // Server error
    }

    return '❓';
  }
}
