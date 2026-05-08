/// Configuracion de entorno de la app.
///
/// El flavor se inyecta en build-time via `--dart-define=FLAVOR=dev|prod`.
/// Default: prod (si alguien arma sin pasar el define, no apunta a beta por error).
class EnvConfig {
  EnvConfig._();

  static const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static const Map<String, String> _baseUrls = {
    'dev': 'https://saas-beta.syncronize.net.pe/api',
    'prod': 'https://saas.syncronize.net.pe/api',
  };

  static String get baseUrl => _baseUrls[_flavor] ?? _baseUrls['prod']!;

  static String get flavor => _flavor;

  static bool get isDev => _flavor == 'dev';
  static bool get isProd => _flavor == 'prod';

  static bool get enablePrettyLogger => isDev;
}
