import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/turno_model.dart';

@lazySingleton
class TurnoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/turnos';

  TurnoRemoteDataSource(this._dioClient);

  Future<TurnoModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return TurnoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TurnoModel>> getAll() async {
    final response = await _dioClient.get(_basePath);
    final data = response.data as List;
    return data
        .map((e) => TurnoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TurnoModel> update(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return TurnoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dioClient.delete('$_basePath/$id');
  }
}
