import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';

@lazySingleton
class SolicitudEmpresaRemoteDataSource {
  final DioClient _dioClient;
  static const _basePath = '/solicitudes-cotizacion';

  SolicitudEmpresaRemoteDataSource(this._dioClient);

  Future<List<Map<String, dynamic>>> listar({String? estado, String? search}) async {
    final params = <String, dynamic>{};
    if (estado != null) params['estado'] = estado;
    if (search != null) params['search'] = search;

    final response = await _dioClient.get(_basePath, queryParameters: params);
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> detalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> rechazar(String id, String motivo) async {
    await _dioClient.post('$_basePath/$id/rechazar', data: {'motivo': motivo});
  }

  Future<void> cotizar(String id, String cotizacionId) async {
    await _dioClient.post('$_basePath/$id/cotizar', data: {'cotizacionId': cotizacionId});
  }
}
