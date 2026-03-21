import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/inventario_model.dart';

@lazySingleton
class InventarioRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/inventarios';

  InventarioRemoteDataSource(this._dioClient);

  Future<List<InventarioModel>> listar({
    String? sedeId,
    String? estado,
  }) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;
    if (estado != null) queryParams['estado'] = estado;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    final data = response.data as List;
    return data
        .map((e) => InventarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InventarioModel> getDetalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return InventarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InventarioModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return InventarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> iniciar(String id) async {
    await _dioClient.post('$_basePath/$id/iniciar');
  }

  Future<void> registrarConteo({
    required String id,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    await _dioClient.post('$_basePath/$id/items/$itemId/contar', data: data);
  }

  Future<void> finalizarConteo(String id) async {
    await _dioClient.post('$_basePath/$id/finalizar-conteo');
  }

  Future<void> aprobar(String id) async {
    await _dioClient.post('$_basePath/$id/aprobar');
  }

  Future<void> aplicarAjustes(String id) async {
    await _dioClient.post('$_basePath/$id/aplicar-ajustes');
  }

  Future<void> cancelar(String id) async {
    await _dioClient.post('$_basePath/$id/cancelar');
  }
}
