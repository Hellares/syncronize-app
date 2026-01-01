/// Utilidad para sanitizar datos sensibles en logs
///
/// Remueve tokens, contraseñas y otra información sensible
/// antes de que sea registrada en los logs.
class LogSanitizer {
  /// Headers sensibles que deben ser ocultados
  static const List<String> _sensitiveHeaders = [
    'authorization',
    'Authorization',
    'x-api-key',
    'X-API-Key',
    'api-key',
    'Api-Key',
    'x-auth-token',
    'X-Auth-Token',
    'cookie',
    'Cookie',
    'set-cookie',
    'Set-Cookie',
  ];

  /// Campos sensibles en el body que deben ser ocultados
  static const List<String> _sensitiveFields = [
    'password',
    'Password',
    'passwordHash',
    'currentPassword',
    'newPassword',
    'confirmPassword',
    'accessToken',
    'access_token',
    'refreshToken',
    'refresh_token',
    'token',
    'Token',
    'apiKey',
    'api_key',
    'secret',
    'Secret',
    'privateKey',
    'private_key',
    'clientSecret',
    'client_secret',
    'resetToken',
    'verificationToken',
    'emailVerificationToken',
  ];

  /// Texto de reemplazo para datos sensibles
  static const String _redactedText = '***REDACTED***';

  /// Sanitiza los headers de una petición/respuesta HTTP
  static Map<String, dynamic>? sanitizeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    final sanitized = Map<String, dynamic>.from(headers);

    for (final sensitiveHeader in _sensitiveHeaders) {
      if (sanitized.containsKey(sensitiveHeader)) {
        sanitized[sensitiveHeader] = _redactedText;
      }
    }

    return sanitized;
  }

  /// Sanitiza el body de una petición/respuesta HTTP
  static dynamic sanitizeBody(dynamic body) {
    if (body == null) return null;

    // Si es un Map, sanitizar recursivamente
    if (body is Map<String, dynamic>) {
      return _sanitizeMap(body);
    }

    // Si es una List, sanitizar cada elemento
    if (body is List) {
      return body.map((item) => sanitizeBody(item)).toList();
    }

    // Si es un String que podría ser JSON, intentar parsearlo
    if (body is String) {
      try {
        final decoded = _tryDecodeJson(body);
        if (decoded != null) {
          return sanitizeBody(decoded);
        }
      } catch (_) {
        // Si no es JSON válido, revisar si contiene patrones de tokens
        return _sanitizeString(body);
      }
    }

    return body;
  }

  /// Sanitiza un Map recursivamente
  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      // Si la key es sensible, reemplazar el valor
      if (_isSensitiveField(key)) {
        sanitized[key] = _redactedText;
      } else if (value is Map<String, dynamic>) {
        // Si el valor es otro Map, sanitizar recursivamente
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List) {
        // Si el valor es una List, sanitizar cada elemento
        sanitized[key] = value.map((item) => sanitizeBody(item)).toList();
      } else if (value is String) {
        // Si el valor es String, revisar si contiene tokens
        sanitized[key] = _sanitizeString(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Verifica si un campo es sensible
  static bool _isSensitiveField(String fieldName) {
    final lowerFieldName = fieldName.toLowerCase();

    for (final sensitiveField in _sensitiveFields) {
      if (lowerFieldName == sensitiveField.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Sanitiza un String que podría contener tokens JWT o API keys
  static String _sanitizeString(String value) {
    // Patrón para JWT (tres partes separadas por puntos)
    final jwtPattern = RegExp(
      r'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*',
    );

    // Patrón para Bearer tokens
    final bearerPattern = RegExp(
      r'Bearer\s+[a-zA-Z0-9._-]+',
      caseSensitive: false,
    );

    // Patrón para API keys (strings largos alfanuméricos)
    final apiKeyPattern = RegExp(
      r'[a-zA-Z0-9]{32,}',
    );

    var sanitized = value;

    // Reemplazar JWTs
    sanitized = sanitized.replaceAll(jwtPattern, _redactedText);

    // Reemplazar Bearer tokens
    sanitized = sanitized.replaceAll(bearerPattern, 'Bearer $_redactedText');

    // Solo reemplazar API keys si el string es muy largo
    if (value.length > 32 && apiKeyPattern.hasMatch(value)) {
      sanitized = sanitized.replaceAll(apiKeyPattern, _redactedText);
    }

    return sanitized;
  }

  /// Intenta decodificar un String JSON
  static dynamic _tryDecodeJson(String jsonString) {
    try {
      // Intenta parsear como JSON
      final trimmed = jsonString.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return null; // No implementar parsing aquí para evitar dependencias
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Sanitiza parámetros de query
  static Map<String, dynamic>? sanitizeQueryParams(
    Map<String, dynamic>? queryParams,
  ) {
    if (queryParams == null) return null;

    final sanitized = <String, dynamic>{};

    for (final entry in queryParams.entries) {
      if (_isSensitiveField(entry.key)) {
        sanitized[entry.key] = _redactedText;
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  /// Sanitiza una URL completa (oculta tokens en query params)
  static String sanitizeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final sanitizedParams = <String, String>{};

    uri.queryParameters.forEach((key, value) {
      if (_isSensitiveField(key)) {
        sanitizedParams[key] = _redactedText;
      } else {
        sanitizedParams[key] = value;
      }
    });

    if (sanitizedParams.isEmpty) return url;

    final sanitizedUri = uri.replace(
      queryParameters: sanitizedParams.isEmpty ? null : sanitizedParams,
    );

    return sanitizedUri.toString();
  }

  /// Sanitiza un mensaje de error completo
  static String sanitizeErrorMessage(String message) {
    return _sanitizeString(message);
  }

  /// Verifica si un valor es sensible (útil para logging condicional)
  static bool isSensitiveValue(String value) {
    // JWT pattern
    if (RegExp(r'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*')
        .hasMatch(value)) {
      return true;
    }

    // Bearer pattern
    if (RegExp(r'Bearer\s+', caseSensitive: false).hasMatch(value)) {
      return true;
    }

    // API keys (strings muy largos)
    if (value.length > 32 && RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
      return true;
    }

    return false;
  }
}
