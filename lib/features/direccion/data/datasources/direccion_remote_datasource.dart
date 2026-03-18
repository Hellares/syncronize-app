import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/direccion_persona_model.dart';

@lazySingleton
class DireccionRemoteDataSource {
  final DioClient _dioClient;

  DireccionRemoteDataSource(this._dioClient);

  Future<List<DireccionPersonaModel>> listar() async {
    final response = await _dioClient.get(ApiConstants.misDirecciones);
    final list = response.data as List;
    return list
        .map((e) => DireccionPersonaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DireccionPersonaModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(ApiConstants.misDirecciones, data: data);
    return DireccionPersonaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DireccionPersonaModel> actualizar(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('${ApiConstants.misDirecciones}/$id', data: data);
    return DireccionPersonaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    await _dioClient.delete('${ApiConstants.misDirecciones}/$id');
  }

  Future<DireccionPersonaModel> marcarPredeterminada(String id) async {
    final response = await _dioClient.patch('${ApiConstants.misDirecciones}/$id/predeterminada');
    return DireccionPersonaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
