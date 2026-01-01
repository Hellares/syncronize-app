/// Patrón Resource para manejo de estados simplificado
/// Reemplaza Either con un approach más directo
abstract class Resource<T> {}

/// Estado inicial
class Initial extends Resource {}

/// Estado de carga
class Loading extends Resource {}

/// Estado de éxito con datos
class Success<T> extends Resource<T> {
  final T data;
  Success(this.data);
}

/// Estado de error con información detallada
class Error<T> extends Resource<T> {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;

  Error(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.details,
  });

  /// Verifica si es un error de autenticación
  bool get isAuthError =>
      errorCode == 'UNAUTHORIZED' || errorCode == 'FORBIDDEN';

  /// Verifica si es un error de validación
  bool get isValidationError =>
      errorCode == 'VALIDATION_ERROR' || errorCode == 'BAD_REQUEST';

  /// Verifica si es un error de red
  bool get isNetworkError =>
      errorCode == 'SERVICE_UNAVAILABLE' ||
      errorCode == 'GATEWAY_TIMEOUT' ||
      errorCode == 'NETWORK_ERROR';

  /// Verifica si es un error del servidor
  bool get isServerError => statusCode != null && statusCode! >= 500;
}
