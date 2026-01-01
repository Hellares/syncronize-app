/// Constantes generales de la aplicación
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Syncronize';
  static const String appVersion = '1.0.0';

  // Validaciones
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNombresLength = 2;
  static const int maxNombresLength = 50;

  // Timeouts
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);

  // Paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
