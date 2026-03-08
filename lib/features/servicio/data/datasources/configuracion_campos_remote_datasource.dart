import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/configuracion_campo_model.dart';

@lazySingleton
class ConfiguracionCamposRemoteDataSource {
  final DioClient _dioClient;

  ConfiguracionCamposRemoteDataSource(this._dioClient);

  Future<List<ConfiguracionCampoModel>> getAll({
    String? categoria,
    bool? activo,
  }) async {
    final queryParams = <String, dynamic>{
      if (categoria != null) 'categoria': categoria,
      if (activo != null) 'activo': activo.toString(),
    };

    final response = await _dioClient.get(
      ApiConstants.configuracionCamposServicio,
      queryParameters: queryParams,
    );

    return (response.data as List)
        .map((e) => ConfiguracionCampoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConfiguracionCampoModel> getOne(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.configuracionCamposServicio}/$id',
    );
    return ConfiguracionCampoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConfiguracionCampoModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.configuracionCamposServicio,
      data: data,
    );
    return ConfiguracionCampoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConfiguracionCampoModel> update(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionCamposServicio}/$id',
      data: data,
    );
    return ConfiguracionCampoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dioClient.delete('${ApiConstants.configuracionCamposServicio}/$id');
  }

  Future<List<ConfiguracionCampoModel>> reorder(List<String> orderedIds) async {
    final response = await _dioClient.patch(
      '${ApiConstants.configuracionCamposServicio}/reorder',
      data: {'orderedIds': orderedIds},
    );
    return (response.data as List)
        .map((e) => ConfiguracionCampoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
