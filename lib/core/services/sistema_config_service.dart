import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Servicio para obtener la configuracion publica del sistema.
/// Cachea la respuesta en memoria para evitar llamadas repetidas.
@lazySingleton
class SistemaConfigService {
  final DioClient _client;
  Map<String, dynamic>? _cache;

  SistemaConfigService(this._client);

  Future<Map<String, dynamic>> getConfig() async {
    if (_cache != null) return _cache!;

    try {
      final response =
          await _client.get(ApiConstants.configuracionSistemaPublica);
      final data = response.data is Map<String, dynamic>
          ? ((response.data as Map<String, dynamic>)['data'] ??
              response.data) as Map<String, dynamic>
          : <String, dynamic>{};
      _cache = data;
      return data;
    } catch (e) {
      return _getDefaults();
    }
  }

  void invalidateCache() => _cache = null;

  Map<String, dynamic> _getDefaults() => {
        'yapeNumero': '942857613',
        'yapeTitular': 'Syncronize SAC',
        'plinNumero': '942857613',
        'plinTitular': 'Syncronize SAC',
        'bancoCuenta': '191-12345678-0-12',
        'bancoCci': '002-191-12345678012-34',
        'bancoNombre': 'BCP',
        'bancoTitular': 'Syncronize SAC',
        'whatsappSoporte': '51942857613',
        'emailSoporte': 'soporte@syncronize.net.pe',
        'diasGracia': 7,
        'modoMantenimiento': false,
      };

  // Convenience getters
  Future<String> get yapeNumero async =>
      (await getConfig())['yapeNumero'] as String? ?? '942857613';
  Future<String> get yapeTitular async =>
      (await getConfig())['yapeTitular'] as String? ?? 'Syncronize SAC';
  Future<String> get plinNumero async =>
      (await getConfig())['plinNumero'] as String? ?? '942857613';
  Future<String> get plinTitular async =>
      (await getConfig())['plinTitular'] as String? ?? 'Syncronize SAC';
  Future<String> get bancoNombre async =>
      (await getConfig())['bancoNombre'] as String? ?? 'BCP';
  Future<String> get bancoCuenta async =>
      (await getConfig())['bancoCuenta'] as String? ?? '191-12345678-0-12';
  Future<String> get bancoCci async =>
      (await getConfig())['bancoCci'] as String? ??
      '002-191-12345678012-34';
  Future<String> get bancoTitular async =>
      (await getConfig())['bancoTitular'] as String? ?? 'Syncronize SAC';
  Future<String> get whatsappSoporte async =>
      (await getConfig())['whatsappSoporte'] as String? ?? '51942857613';
  Future<String> get emailSoporte async =>
      (await getConfig())['emailSoporte'] as String? ??
      'soporte@syncronize.net.pe';
  Future<int> get diasGracia async =>
      (await getConfig())['diasGracia'] as int? ?? 7;
  Future<bool> get modoMantenimiento async =>
      (await getConfig())['modoMantenimiento'] as bool? ?? false;
}
