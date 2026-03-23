import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/adelanto_model.dart';

@lazySingleton
class AdelantoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/adelantos';

  AdelantoRemoteDataSource(this._dioClient);

  Future<AdelantoModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return AdelantoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdelantoModel>> getAll({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => AdelantoModel.fromJson(e as Map<String, dynamic>))
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
          .map((e) => AdelantoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'meta': meta,
    };
  }

  Future<AdelantoModel> aprobar(String id) async {
    final response = await _dioClient.patch('$_basePath/$id/aprobar');
    return AdelantoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdelantoModel> rechazar(String id, String motivoRechazo) async {
    final response = await _dioClient.patch(
      '$_basePath/$id/rechazar',
      data: {'motivoRechazo': motivoRechazo},
    );
    return AdelantoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdelantoModel> pagar(String id, Map<String, dynamic> data) async {
    final response =
        await _dioClient.post('$_basePath/$id/pagar', data: data);
    return AdelantoModel.fromJson(response.data as Map<String, dynamic>);
  }
}
