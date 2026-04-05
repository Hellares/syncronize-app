import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/devolucion_venta_model.dart';

@lazySingleton
class DevolucionVentaRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/devoluciones-venta';

  DevolucionVentaRemoteDataSource(this._dioClient);

  Future<DevolucionVentaModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return DevolucionVentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DevolucionVentaModel>> getAll({
    String? sedeId, String? estado, String? ventaId, String? search,
  }) async {
    final params = <String, dynamic>{};
    if (sedeId != null) params['sedeId'] = sedeId;
    if (estado != null) params['estado'] = estado;
    if (ventaId != null) params['ventaId'] = ventaId;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dioClient.get(_basePath, queryParameters: params);
    return (response.data as List)
        .map((e) => DevolucionVentaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DevolucionVentaModel> getOne(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return DevolucionVentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DevolucionVentaModel> aprobar(String id) async {
    final response = await _dioClient.post('$_basePath/$id/aprobar');
    return DevolucionVentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DevolucionVentaModel> procesar(String id) async {
    final response = await _dioClient.post('$_basePath/$id/procesar');
    return DevolucionVentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DevolucionVentaModel> rechazar(String id, {String? motivo}) async {
    final response = await _dioClient.post(
      '$_basePath/$id/rechazar',
      data: motivo != null ? {'motivo': motivo} : {},
    );
    return DevolucionVentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DevolucionVentaModel> cancelar(String id) async {
    final response = await _dioClient.post('$_basePath/$id/cancelar');
    return DevolucionVentaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
