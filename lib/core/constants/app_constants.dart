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

  // Tributario
  /// ICBPER (Ley N° 30884) por bolsa plástica. Tarifa vigente desde 2023:
  /// S/ 0.50 por unidad (2019: 0.10, 2020: 0.20, 2021: 0.30, 2022: 0.40).
  /// FUENTE ÚNICA — no hardcodear la tarifa en cubits/selectores.
  static const double icbperPorUnidad = 0.50;

  // Paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
