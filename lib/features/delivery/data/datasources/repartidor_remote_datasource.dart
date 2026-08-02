import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';

/// Repartidor FREELANCE de Syncronize: registro público, verificación OTP
/// y perfil. Devuelve mapas crudos (el panel es simple y el shape lo
/// define el backend — ver repartidores.controller).
@lazySingleton
class RepartidorRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/repartidores';

  RepartidorRemoteDataSource(this._dioClient);

  /// Registro PÚBLICO (sin sesión): valida el DNI en RENIEC y crea la
  /// cuenta login-DNI. Queda PENDIENTE de aprobación.
  Future<Map<String, dynamic>> registrar({
    required String dni,
    required String celular,
    required String password,
    required List<String> zonas,
    String? placaVehiculo,
  }) async {
    final response = await _dioClient.post('$_basePath/registro', data: {
      'dni': dni,
      'celular': celular,
      'password': password,
      'zonas': zonas,
      if (placaVehiculo != null && placaVehiculo.isNotEmpty)
        'placaVehiculo': placaVehiculo,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Catálogo de ubigeo en cascada para el selector de zonas. Los tres son
  /// PÚBLICOS: el registro del repartidor no tiene sesión todavía.
  Future<List<({String codigo, String nombre})>> ubigeoDepartamentos() =>
      _ubigeo('/delivery-local/catalogos/ubigeo/departamentos');

  Future<List<({String codigo, String nombre})>> ubigeoProvincias(
    String departamento,
  ) =>
      _ubigeo(
        '/delivery-local/catalogos/ubigeo/provincias',
        {'departamento': departamento},
      );

  Future<List<({String codigo, String nombre})>> ubigeoDistritos(
    String provincia,
  ) =>
      _ubigeo(
        '/delivery-local/catalogos/ubigeo/distritos',
        {'provincia': provincia},
      );

  Future<List<({String codigo, String nombre})>> _ubigeo(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final r = await _dioClient.get(path, queryParameters: query);
    return (r.data as List<dynamic>)
        .map((e) => (
              codigo: (e as Map<String, dynamic>)['codigo'] as String,
              nombre: e['nombre'] as String,
            ))
        .toList();
  }

  /// Perfil del repartidor autenticado (404 = no es repartidor).
  Future<Map<String, dynamic>> miPerfil() async {
    final response = await _dioClient.get('$_basePath/mi-perfil');
    return response.data as Map<String, dynamic>;
  }

  Future<void> enviarOtp() async {
    await _dioClient.post('$_basePath/otp/enviar');
  }

  Future<void> verificarOtp(String codigo) async {
    await _dioClient.post('$_basePath/otp/verificar', data: {'codigo': codigo});
  }

  Future<Map<String, dynamic>> actualizarPerfil(
      Map<String, dynamic> data) async {
    final response = await _dioClient.put('$_basePath/mi-perfil', data: data);
    return response.data as Map<String, dynamic>;
  }
}
