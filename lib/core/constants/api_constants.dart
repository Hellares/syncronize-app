/// Constantes relacionadas con la API
class ApiConstants {
  ApiConstants._();

  // Endpoints de autenticación
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleSignIn = '/auth/google';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerificationEmail = '/auth/resend-verification-email';
  static const String profile = '/auth/profile';
  static const String sessions = '/auth/sessions';

  // Multi-method auth
  static const String checkAuthMethods = '/auth/methods';
  static const String setPassword = '/auth/set-password';

  // Endpoints de empresas
  static const String empresas = '/empresas';

  // Endpoints de productos
  static const String productos = '/productos';

  // Endpoints de plantillas de atributos
  static const String plantillasAtributos = '/producto-atributo-plantillas';

  // Endpoints de configuraciones de precios
  static const String configuracionesPrecios = '/configuraciones-precio';

  // Endpoints de combos
  static const String combos = '/combos';

  // Endpoints de catálogos
  static const String catalogos = '/catalogos';

  // Endpoints de clientes
  static const String clientes = '/clientes';

  // Endpoints de usuarios/empleados
  static const String usuarios = '/usuarios';

  // Endpoints de políticas de descuento
  static const String politicasDescuento = '/politicas-descuento';

  // Headers
  static const String authorization = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String tenantId = 'x-tenant-id'; // Debe coincidir EXACTAMENTE con el backend (case-sensitive)


  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
