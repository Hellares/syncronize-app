/// Constantes para el almacenamiento local
class StorageConstants {
  StorageConstants._();

  // Secure Storage Keys (para datos sensibles)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userPassword = 'user_password';

  // Shared Preferences Keys (para datos no sensibles)
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userNombres = 'user_nombres';
  static const String userApellidos = 'user_apellidos';
  static const String userDni = 'user_dni';
  static const String userTelefono = 'user_telefono';
  static const String userDireccion = 'user_direccion';
  static const String userEmailVerificado = 'user_email_verificado';
  static const String tenantId = 'tenant_id';
  static const String tenantName = 'tenant_name';
  static const String tenantRole = 'tenant_role';
  static const String loginMode = 'login_mode';
  static const String isLoggedIn = 'is_logged_in';
  static const String rememberMe = 'remember_me';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';

  /// Con cuál de las dos apps de WhatsApp se escribe a los clientes. Es del
  /// DISPOSITIVO, no de la empresa ni del usuario: depende de qué apps tiene
  /// instaladas este celular.
  static const String appWhatsappPreferida = 'app_whatsapp_preferida';
}
