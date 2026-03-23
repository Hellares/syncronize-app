import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/empleado_model.dart';

@lazySingleton
class EmpleadoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/empleados';

  EmpleadoRemoteDataSource(this._dioClient);

  Future<EmpleadoModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return EmpleadoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EmpleadoModel>> getAll({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => EmpleadoModel.fromJson(e as Map<String, dynamic>))
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
          .map((e) => EmpleadoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'meta': meta,
    };
  }

  Future<EmpleadoModel> getById(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return EmpleadoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmpleadoModel> update(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return EmpleadoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dioClient.delete('$_basePath/$id');
  }
}
