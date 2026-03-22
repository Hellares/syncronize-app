import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/agente_bancario_model.dart';
import '../models/operacion_agente_model.dart';

@lazySingleton
class AgenteBancarioRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/agentes-bancarios';

  AgenteBancarioRemoteDataSource(this._dioClient);

  Future<ResumenAgentesModel> getResumen({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/resumen',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return ResumenAgentesModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<AgenteBancarioModel>> getAgentes({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AgenteBancarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgenteBancarioModel> getDetalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return AgenteBancarioModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AgenteBancarioModel> crear(
      String sedeId, Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '$_basePath/sede/$sedeId',
      data: data,
    );
    return AgenteBancarioModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<OperacionAgenteModel> registrarOperacion(
      String agenteId, Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '$_basePath/$agenteId/operacion',
      data: data,
    );
    return OperacionAgenteModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> anularOperacion(
      String agenteId, String operacionId, String motivo) async {
    await _dioClient.post(
      '$_basePath/$agenteId/operacion/$operacionId/anular',
      data: {'motivo': motivo},
    );
  }

  Future<List<OperacionAgenteModel>> getOperaciones(
    String agenteId, {
    String? tipo,
    String? fechaDesde,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (tipo != null) queryParams['tipo'] = tipo;
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dioClient.get(
      '$_basePath/$agenteId/operaciones',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => OperacionAgenteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
