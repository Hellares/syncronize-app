import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/horario_plantilla_model.dart';

@lazySingleton
class HorarioRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/horario-plantillas';

  HorarioRemoteDataSource(this._dioClient);

  Future<HorarioPlantillaModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return HorarioPlantillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<HorarioPlantillaModel>> getAll() async {
    final response = await _dioClient.get(_basePath);
    final data = response.data as List;
    return data
        .map((e) =>
            HorarioPlantillaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HorarioPlantillaModel> getById(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return HorarioPlantillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<HorarioPlantillaModel> update(
      String id, Map<String, dynamic> data) async {
    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return HorarioPlantillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dioClient.delete('$_basePath/$id');
  }
}
