import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/incidencia_model.dart';

@lazySingleton
class IncidenciaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/incidencias';

  IncidenciaRemoteDataSource(this._dioClient);

  Future<IncidenciaModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return IncidenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<IncidenciaModel>> getAll({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => IncidenciaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getAllPaginated({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return {
      'data': data
          .map((e) => IncidenciaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'meta': meta,
    };
  }

  Future<IncidenciaModel> getById(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return IncidenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IncidenciaModel> aprobar(String id) async {
    final response = await _dioClient.patch('$_basePath/$id/aprobar');
    return IncidenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IncidenciaModel> rechazar(String id, String motivoRechazo) async {
    final response = await _dioClient.patch(
      '$_basePath/$id/rechazar',
      data: {'motivoRechazo': motivoRechazo},
    );
    return IncidenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IncidenciaModel> cancelar(String id) async {
    final response = await _dioClient.delete('$_basePath/$id');
    return IncidenciaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
