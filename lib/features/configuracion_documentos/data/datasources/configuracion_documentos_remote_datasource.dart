import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/configuracion_documentos_model.dart';
import '../models/plantilla_documento_model.dart';
import '../models/configuracion_documento_completa_model.dart';

@lazySingleton
class ConfiguracionDocumentosRemoteDataSource {
  final DioClient _dioClient;

  ConfiguracionDocumentosRemoteDataSource(this._dioClient);

  Future<ConfiguracionDocumentosModel> getConfiguracion() async {
    final response = await _dioClient.get(
      ApiConstants.configuracionDocumentos,
    );
    return ConfiguracionDocumentosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ConfiguracionDocumentosModel> updateConfiguracion(
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(
      ApiConstants.configuracionDocumentos,
      data: data,
    );
    return ConfiguracionDocumentosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<PlantillaDocumentoModel>> getPlantillas() async {
    final response = await _dioClient.get(
      '${ApiConstants.configuracionDocumentos}/plantillas',
    );
    final list = response.data as List;
    return list
        .map((e) =>
            PlantillaDocumentoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlantillaDocumentoModel> getPlantillaByTipo(
    String tipo, {
    String? formato,
  }) async {
    final queryParams = <String, dynamic>{};
    if (formato != null) queryParams['formato'] = formato;

    final response = await _dioClient.get(
      '${ApiConstants.configuracionDocumentos}/plantillas/$tipo',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return PlantillaDocumentoModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<PlantillaDocumentoModel> updatePlantilla(
    String tipo,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionDocumentos}/plantillas/$tipo',
      data: data,
    );
    return PlantillaDocumentoModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ConfiguracionDocumentoCompletaModel> getConfiguracionCompleta(
    String tipo, {
    String? formato,
    String? sedeId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (formato != null) queryParams['formato'] = formato;
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '${ApiConstants.configuracionDocumentos}/completa/$tipo',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return ConfiguracionDocumentoCompletaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
