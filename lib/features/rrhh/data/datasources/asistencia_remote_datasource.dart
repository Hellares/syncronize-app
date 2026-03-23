import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/asistencia_model.dart';

@lazySingleton
class AsistenciaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/asistencias';

  AsistenciaRemoteDataSource(this._dioClient);

  Future<AsistenciaModel> registrarEntrada(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return AsistenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AsistenciaModel> registrarSalida(
      String id, Map<String, dynamic> data) async {
    final response =
        await _dioClient.patch('$_basePath/$id/salida', data: data);
    return AsistenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AsistenciaModel>> getAll({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => AsistenciaModel.fromJson(e as Map<String, dynamic>))
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
          .map((e) => AsistenciaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'meta': meta,
    };
  }

  Future<AsistenciaResumenModel> getResumenMensual(
      String empleadoId, int mes, int anio) async {
    final response = await _dioClient.get(
      '$_basePath/resumen/$empleadoId',
      queryParameters: {'mes': mes, 'anio': anio},
    );
    return AsistenciaResumenModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<AsistenciaModel>> registrarBulk(
      Map<String, dynamic> data) async {
    final response = await _dioClient.post('$_basePath/bulk', data: data);
    if (response.data is List) {
      return (response.data as List)
          .map((e) => AsistenciaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
