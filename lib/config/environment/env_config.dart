/// Configuración de entorno (desarrollo, producción)
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  EnvConfig._();

  //! Cambiar esto según el entorno actual
  static const Environment _currentEnvironment = Environment.production;

  // URLs base según el entorno
  // Nota: 10.0.2.2 es la IP del host desde el emulador Android
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'http://192.168.100.3:3000/api',
    Environment.staging: 'https://staging-api.syncronize.com/api',
    Environment.production: 'https://saas.syncronize.net.pe/api',
  };

  // Frontend URLs según el entorno
  static const Map<Environment, String> _frontendUrls = {
    Environment.development: 'http://192.168.100.3:3000/api',
    Environment.staging: 'https://staging.syncronize.com',
    Environment.production: 'https://saas.syncronize.net.pe/api',
  };

  /// Obtener la URL base de la API según el entorno actual
  static String get baseUrl => _baseUrls[_currentEnvironment]!;

  /// Obtener la URL del frontend según el entorno actual
  static String get frontendUrl => _frontendUrls[_currentEnvironment]!;

  /// Obtener el entorno actual
  static Environment get currentEnvironment => _currentEnvironment;

  /// Verificar si estamos en desarrollo
  static bool get isDevelopment => _currentEnvironment == Environment.development;

  /// Verificar si estamos en producción
  static bool get isProduction => _currentEnvironment == Environment.production;

  /// Verificar si estamos en staging
  static bool get isStaging => _currentEnvironment == Environment.staging;

  /// Habilitar logs según el entorno
  static bool get enableLogs => !isProduction;

  /// Habilitar pretty logger para Dio
  static bool get enablePrettyLogger => isDevelopment;
}
