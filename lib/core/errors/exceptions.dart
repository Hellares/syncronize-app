/// Excepción del servidor
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status Code: $statusCode)';
}

/// Excepción de red
class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'Error de conexión',
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Excepción de autenticación
class AuthenticationException implements Exception {
  final String message;
  final int? statusCode;

  const AuthenticationException({
    required this.message,
    this.statusCode = 401,
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Excepción de validación
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException({
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Excepción de caché
class CacheException implements Exception {
  final String message;

  const CacheException({
    this.message = 'Error de caché',
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción de token expirado
class TokenExpiredException implements Exception {
  final String message;

  const TokenExpiredException({
    this.message = 'Token expirado',
  });

  @override
  String toString() => 'TokenExpiredException: $message';
}

/// Excepción de timeout
class TimeoutException implements Exception {
  final String message;

  const TimeoutException({
    this.message = 'Tiempo de espera agotado',
  });

  @override
  String toString() => 'TimeoutException: $message';
}

/// Excepción de autorización
class AuthorizationException implements Exception {
  final String message;

  const AuthorizationException({
    this.message = 'Sin permisos',
  });

  @override
  String toString() => 'AuthorizationException: $message';
}

/// Excepción de rate limit (demasiadas peticiones)
class RateLimitException implements Exception {
  final String message;
  final int? retryAfter; // Segundos hasta que pueda reintentar

  const RateLimitException({
    this.message = 'Demasiadas peticiones. Por favor, espera un momento.',
    this.retryAfter,
  });

  @override
  String toString() => 'RateLimitException: $message';
}
