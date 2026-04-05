import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../utils/log_sanitizer.dart';

/// Servicio centralizado de logging usando Talker con sanitización automática
///
/// Proporciona logs estructurados con niveles:
/// - debug: Información de desarrollo
/// - info: Información general
/// - warning: Advertencias que no son críticas
/// - error: Errores que requieren atención
/// - critical: Errores críticos que afectan la app
///
/// IMPORTANTE: Todos los mensajes son sanitizados automáticamente
/// para remover tokens, contraseñas y otros datos sensibles.
@lazySingleton
class LoggerService {
  late final Talker _talker;

  LoggerService() {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        enabled: true,
        useConsoleLogs: kDebugMode, // Solo en debug mode
        useHistory: true,
        maxHistoryItems: 500,
      ),
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          enableColors: true,
          level: kDebugMode ? LogLevel.debug : LogLevel.warning,
        ),
      ),
    );
  }

  /// Obtener instancia de Talker (para configuración avanzada)
  Talker get talker => _talker;

  /// Log de debug (solo en modo desarrollo)
  /// Sanitiza automáticamente el mensaje antes de loguearlo
  void debug(String message, {String? tag}) {
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);
    _talker.debug(
      _formatMessage(sanitizedMessage, tag),
    );
  }

  /// Log de información general
  /// Sanitiza automáticamente el mensaje antes de loguearlo
  void info(String message, {String? tag}) {
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);
    _talker.info(
      _formatMessage(sanitizedMessage, tag),
    );
  }

  /// Log de advertencia
  /// Sanitiza automáticamente el mensaje antes de loguearlo
  void warning(String message, {String? tag, Object? exception}) {
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);
    final sanitizedException =
        exception != null ? _sanitizeException(exception) : null;
    _talker.warning(
      _formatMessage(sanitizedMessage, tag),
      sanitizedException,
    );
  }

  /// Log de error
  /// Sanitiza automáticamente el mensaje y la excepción antes de loguearlos
  void error(
    String message, {
    String? tag,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);
    final sanitizedException =
        exception != null ? _sanitizeException(exception) : null;
    _talker.error(
      _formatMessage(sanitizedMessage, tag),
      sanitizedException,
      stackTrace,
    );
  }

  /// Log de error crítico
  /// Sanitiza automáticamente el mensaje y la excepción antes de loguearlos
  void critical(
    String message, {
    String? tag,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);
    final sanitizedException =
        exception != null ? _sanitizeException(exception) : null;
    _talker.critical(
      _formatMessage(sanitizedMessage, tag),
      sanitizedException,
      stackTrace,
    );
  }

  /// Log de evento personalizado
  /// Sanitiza automáticamente el mensaje antes de loguearlo
  void log(String message, {String? tag}) {
    final sanitizedMessage = LogSanitizer.sanitizeErrorMessage(message);
    _talker.log(
      _formatMessage(sanitizedMessage, tag),
    );
  }

  /// Log de acción de usuario (útil para analytics)
  /// Sanitiza automáticamente los datos antes de loguearlos
  void logAction(String action, {Map<String, dynamic>? data}) {
    final sanitizedData =
        data != null ? LogSanitizer.sanitizeBody(data) : null;
    _talker.info(
      '🎯 USER ACTION: $action ${sanitizedData != null ? '| Data: $sanitizedData' : ''}',
    );
  }

  /// Log de navegación (útil para debugging de rutas)
  /// Sanitiza automáticamente los parámetros antes de loguearlos
  void logNavigation(String route, {Map<String, dynamic>? params}) {
    final sanitizedParams =
        params != null ? LogSanitizer.sanitizeQueryParams(params) : null;
    _talker.debug(
      '🧭 NAVIGATION: $route ${sanitizedParams != null ? '| Params: $sanitizedParams' : ''}',
    );
  }

  /// Log de API call (complementario a SanitizedLoggingInterceptor)
  /// Sanitiza automáticamente los parámetros antes de loguearlos
  void logApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? params,
  }) {
    final sanitizedEndpoint = LogSanitizer.sanitizeUrl(endpoint);
    final sanitizedParams =
        params != null ? LogSanitizer.sanitizeQueryParams(params) : null;
    _talker.debug(
      '🌐 API: $method $sanitizedEndpoint ${sanitizedParams != null ? '| Params: $sanitizedParams' : ''}',
    );
  }

  /// Log de cambio de estado (útil para BLoC/Cubit)
  void logStateChange(String stateName, {String? previous, String? current}) {
    final sanitizedPrevious = previous != null
        ? LogSanitizer.sanitizeErrorMessage(previous)
        : 'initial';
    final sanitizedCurrent =
        current != null ? LogSanitizer.sanitizeErrorMessage(current) : 'new';
    _talker.debug(
      '📊 STATE CHANGE: $stateName | $sanitizedPrevious → $sanitizedCurrent',
    );
  }

  /// Log de evento del ciclo de vida
  void logLifecycle(String event, {String? screen}) {
    _talker.debug(
      '♻️ LIFECYCLE: $event ${screen != null ? '| Screen: $screen' : ''}',
    );
  }

  /// Formatear mensaje con tag opcional
  String _formatMessage(String message, String? tag) {
    return tag != null ? '[$tag] $message' : message;
  }

  /// Sanitiza una excepción antes de loguearla
  Object _sanitizeException(Object exception) {
    final exceptionString = exception.toString();
    final sanitized = LogSanitizer.sanitizeErrorMessage(exceptionString);
    return sanitized;
  }

  /// Limpiar historial de logs
  void clearLogs() {
    _talker.cleanHistory();
  }

  /// Obtener todos los logs como String (útil para export/soporte)
  String getAllLogs() {
    return _talker.history
        .map((log) => '${log.displayTime} [${log.logLevel}] ${log.displayMessage}')
        .join('\n');
  }
}
