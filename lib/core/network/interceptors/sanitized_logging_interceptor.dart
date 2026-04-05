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

    // Log compacto de la petición
    _loggerService.debug('🌐 $method $sanitizedUrl', tag: 'HTTP');

    if (sanitizedHeaders != null && sanitizedHeaders.isNotEmpty) {
      final headersStr = sanitizedHeaders.entries
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      _loggerService.debug('  Headers: $headersStr', tag: 'HTTP');
    }

    if (sanitizedQueryParams != null && sanitizedQueryParams.isNotEmpty) {
      final paramsStr = sanitizedQueryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      _loggerService.debug('  Params: $paramsStr', tag: 'HTTP');
    }

    if (sanitizedData != null) {
      _loggerService.debug('  Body: $sanitizedData', tag: 'HTTP');
    }
  }

  /// Loguea una respuesta HTTP sanitizada
  void _logResponse(Response response) {
    final statusCode = response.statusCode;
    final method = response.requestOptions.method;
    final uri = response.requestOptions.uri.toString();

    // Sanitizar URL
    final sanitizedUrl = LogSanitizer.sanitizeUrl(uri);

    // Sanitizar body de respuesta
    final sanitizedData = LogSanitizer.sanitizeBody(response.data);

    // Determinar el emoji según el código de estado
    final emoji = _getStatusEmoji(statusCode);

    // Log compacto de la respuesta
    _loggerService.debug(
      '$emoji $statusCode $method $sanitizedUrl',
      tag: 'HTTP',
    );

    if (sanitizedData != null) {
      // Limitar el tamaño del body en logs
      final dataString = sanitizedData.toString();
      if (dataString.length > 500) {
        _loggerService.debug(
          '  Body: ${dataString.substring(0, 500)}... (${dataString.length} chars)',
          tag: 'HTTP',
        );
      } else {
        _loggerService.debug('  Body: $sanitizedData', tag: 'HTTP');
      }
    }
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

    // Log compacto de error
    _loggerService.error(
      '❌ ${statusCode ?? err.type.name} $method $sanitizedUrl',
      tag: 'HTTP',
    );

    _loggerService.error(
      '  Error: $sanitizedMessage',
      tag: 'HTTP',
    );

    if (sanitizedResponseData != null) {
      final dataString = sanitizedResponseData.toString();
      if (dataString.length > 500) {
        _loggerService.error(
          '  Response: ${dataString.substring(0, 500)}... (${dataString.length} chars)',
          tag: 'HTTP',
        );
      } else {
        _loggerService.error('  Response: $sanitizedResponseData', tag: 'HTTP');
      }
    }
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
