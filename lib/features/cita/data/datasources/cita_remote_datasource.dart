import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cita_model.dart';
import '../models/slot_disponibilidad_model.dart';

@lazySingleton
class CitaRemoteDataSource {
  final DioClient _dioClient;

  CitaRemoteDataSource(this._dioClient);

  /// GET /citas/disponibilidad
  Future<DisponibilidadResponseModel> getDisponibilidad({
    required String fecha,
    required String sedeId,
    required String servicioId,
    String? tecnicoId,
  }) async {
    final params = <String, dynamic>{
      'fecha': fecha,
      'sedeId': sedeId,
      'servicioId': servicioId,
    };
    if (tecnicoId != null) params['tecnicoId'] = tecnicoId;

    final response = await _dioClient.get(
      '${ApiConstants.citas}/disponibilidad',
      queryParameters: params,
    );

    return DisponibilidadResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// GET /citas/tecnicos-disponibles
  Future<List<TecnicoDisponibleModel>> getTecnicosDisponibles({
    required String fecha,
    required String horaInicio,
    required String sedeId,
    required String servicioId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.citas}/tecnicos-disponibles',
      queryParameters: {
        'fecha': fecha,
        'horaInicio': horaInicio,
        'sedeId': sedeId,
        'servicioId': servicioId,
      },
    );

    final list = response.data as List;
    return list
        .map((e) =>
            TecnicoDisponibleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /citas
  Future<CitaModel> create(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.citas,
      data: data,
    );
    return CitaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /citas
  Future<Map<String, dynamic>> findAll({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.citas,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /citas/:id
  Future<CitaModel> findOne(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.citas}/$id',
    );
    return CitaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /citas/:id
  Future<CitaModel> update(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiConstants.citas}/$id',
      data: data,
    );
    return CitaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /citas/:id/estado
  Future<Map<String, dynamic>> transitionEstado(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.citas}/$id/estado',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }
}
