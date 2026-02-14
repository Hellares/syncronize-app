import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/atributo_plantilla_model.dart';

/// Data source remoto para operaciones de plantillas de atributos
@lazySingleton
class PlantillaRemoteDataSource {
  final DioClient _dioClient;

  PlantillaRemoteDataSource(this._dioClient);

  /// Crea una nueva plantilla de atributos
  ///
  /// POST /producto-atributo-plantillas
  Future<AtributoPlantillaModel> crearPlantilla(
    CreatePlantillaDto dto,
  ) async {
    final response = await _dioClient.post(
      ApiConstants.plantillasAtributos,
      data: dto.toJson(),
    );

    return AtributoPlantillaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene todas las plantillas de atributos
  ///
  /// GET /producto-atributo-plantillas?categoriaId=xxx
  Future<List<AtributoPlantillaModel>> getPlantillas({
    String? categoriaId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (categoriaId != null) {
      queryParams['categoriaId'] = categoriaId;
    }

    final response = await _dioClient.get(
      ApiConstants.plantillasAtributos,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => AtributoPlantillaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene una plantilla por ID
  ///
  /// GET /producto-atributo-plantillas/:id
  Future<AtributoPlantillaModel> getPlantilla(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.plantillasAtributos}/$id',
    );

    return AtributoPlantillaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza una plantilla existente
  ///
  /// PATCH /producto-atributo-plantillas/:id
  Future<AtributoPlantillaModel> actualizarPlantilla(
    String id,
    UpdatePlantillaDto dto,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.plantillasAtributos}/$id',
      data: dto.toJson(),
    );

    return AtributoPlantillaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina una plantilla (soft delete)
  ///
  /// DELETE /producto-atributo-plantillas/:id
  Future<void> eliminarPlantilla(String id) async {
    await _dioClient.delete(
      '${ApiConstants.plantillasAtributos}/$id',
    );
  }

  /// Aplica una plantilla a un producto o variante
  ///
  /// POST /producto-atributo-plantillas/aplicar
  Future<Map<String, dynamic>> aplicarPlantilla(
    AplicarPlantillaDto dto,
  ) async {
    final response = await _dioClient.post(
      '${ApiConstants.plantillasAtributos}/aplicar',
      data: dto.toJson(),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Obtiene información de límites del plan
  ///
  /// GET /producto-atributo-plantillas/limits-info
  Future<Map<String, dynamic>> getLimitsInfo() async {
    final response = await _dioClient.get(
      '${ApiConstants.plantillasAtributos}/limits-info',
    );

    return response.data as Map<String, dynamic>;
  }
}
