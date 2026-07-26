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

  /// Editar y eliminar van al controller de campos, no al de plantillas:
  /// el campo se identifica por su id propio, no por la plantilla.
  Future<ConfiguracionCampoModel> updateCampo(
    String campoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionCamposServicio}/$campoId',
      data: data,
    );
    return ConfiguracionCampoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Borrado LÓGICO en el backend (isActive=false).
  Future<void> deleteCampo(String campoId) async {
    await _dioClient.delete(
      '${ApiConstants.configuracionCamposServicio}/$campoId',
    );
  }

  /// El backend asigna `orden` = posición en la lista (1-based), en una
  /// transacción. Hay que mandar TODOS los ids del grupo, no solo los que
  /// se movieron.
  Future<void> reorderCampos(List<String> orderedIds) async {
    await _dioClient.patch(
      '${ApiConstants.configuracionCamposServicio}/reorder',
      data: {'orderedIds': orderedIds},
    );
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
