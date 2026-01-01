/// Modelo para respuestas de error del backend
/// Proporciona mensajes amigables para el usuario según el código de error
class BackendErrorResponse {
  final bool success;
  final int status;
  final String message;
  final String error;
  final String code;
  final String? timestamp;
  final Map<String, dynamic>? details;

  BackendErrorResponse({
    required this.success,
    required this.status,
    required this.message,
    required this.error,
    required this.code,
    this.timestamp,
    this.details,
  });

  factory BackendErrorResponse.fromJson(Map<String, dynamic> json) {
    return BackendErrorResponse(
      success: json['success'] ?? false,
      status: json['status'] ?? 500,
      message: json['message'] ?? 'Error desconocido',
      error: json['error'] ?? 'Error',
      code: json['code'] ?? 'UNKNOWN_ERROR',
      timestamp: json['timestamp'],
      details: json['details'],
    );
  }

  /// Mensajes amigables para el usuario según el código de error
  String get userFriendlyMessage {
    switch (code) {
      case 'UNAUTHORIZED':
        return 'Usuario o contraseña incorrectos';
      case 'VALIDATION_ERROR':
        return message; // Los mensajes de validación ya son claros
      case 'SERVICE_UNAVAILABLE':
        return 'El servicio no está disponible. Por favor, intenta más tarde';
      case 'GATEWAY_TIMEOUT':
        return 'La conexión está tardando demasiado. Verifica tu internet';
      case 'FORBIDDEN':
        return 'No tienes permisos para realizar esta acción';
      case 'NOT_FOUND':
        return 'Recurso no encontrado';
      case 'CONFLICT':
        return message; // Los conflictos de negocio tienen mensajes claros
      case 'EMAIL_ALREADY_EXISTS':
        return 'Este correo electrónico ya está registrado';
      case 'INVALID_CREDENTIALS':
        return 'Credenciales inválidas';
      default:
        return message.isNotEmpty ? message : 'Ha ocurrido un error inesperado';
    }
  }
}
