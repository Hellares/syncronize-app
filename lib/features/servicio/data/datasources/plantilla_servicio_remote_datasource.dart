import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/plantilla_servicio_model.dart';
import '../models/configuracion_campo_model.dart';

@lazySingleton
class PlantillaServicioRemoteDataSource {
  final DioClient _dioClient;

  PlantillaServicioRemoteDataSource(this._dioClient);

  Future<PlantillaServicioModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.plantillasServicio,
      data: data,
    );
    return PlantillaServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PlantillaServicioModel>> getAll() async {
    final response = await _dioClient.get(ApiConstants.plantillasServicio);
    return (response.data as List)
        .map((e) => PlantillaServicioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlantillaServicioModel> getOne(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.plantillasServicio}/$id',
    );
    return PlantillaServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlantillaServicioModel> actualizar(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiConstants.plantillasServicio}/$id',
      data: data,
    );
    return PlantillaServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    await _dioClient.delete('${ApiConstants.plantillasServicio}/$id');
  }

  Future<ConfiguracionCampoModel> addCampo(String plantillaId, Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '${ApiConstants.plantillasServicio}/$plantillaId/campos',
      data: data,
    );
    return ConfiguracionCampoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ConfiguracionCampoModel>> getCampos(String plantillaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.plantillasServicio}/$plantillaId/campos',
    );
    return (response.data as List)
        .map((e) => ConfiguracionCampoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConfiguracionCampoModel>> getCamposByServicioId(String servicioId) async {
    final response = await _dioClient.get(
      '${ApiConstants.plantillasServicio}/por-servicio/$servicioId',
    );
    return (response.data as List)
        .map((e) => ConfiguracionCampoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
