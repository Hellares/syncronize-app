import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';

@lazySingleton
class PedidoEmpresaRemoteDataSource {
  final DioClient _dioClient;
  static const _basePath = '/pedidos-marketplace';

  PedidoEmpresaRemoteDataSource(this._dioClient);

  Future<List<Map<String, dynamic>>> listarPedidos({
    String? estado,
    String? search,
  }) async {
    String url = _basePath;
    final params = <String, dynamic>{};
    if (estado != null) params['estado'] = estado;
    if (search != null) params['search'] = search;

    final response = await _dioClient.get(url, queryParameters: params);
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> detallePedido(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> validarPago(String id, {required String accion, String? motivoRechazo}) async {
    await _dioClient.post('$_basePath/$id/validar-pago', data: {
      'accion': accion,
      if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
    });
  }

  Future<void> cambiarEstado(String id, {required String estado, String? codigoSeguimiento}) async {
    await _dioClient.patch('$_basePath/$id/estado', data: {
      'estado': estado,
      if (codigoSeguimiento != null) 'codigoSeguimiento': codigoSeguimiento,
    });
  }

  Future<Map<String, dynamic>> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    return response.data as Map<String, dynamic>;
  }
}
