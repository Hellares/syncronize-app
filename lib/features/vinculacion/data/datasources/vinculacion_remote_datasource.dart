import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/vinculacion_model.dart';

@lazySingleton
class VinculacionRemoteDataSource {
  final DioClient _dioClient;

  VinculacionRemoteDataSource(this._dioClient);

  // ─── Check RUC ───

  Future<EmpresaVinculableModel?> checkRuc(String ruc) async {
    final response = await _dioClient.get(
      '${ApiConstants.vinculacion}/check-ruc/$ruc',
    );
    if (response.data == null || (response.data is String && response.data == 'null')) {
      return null;
    }
    return EmpresaVinculableModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> checkRucRaw(String ruc) async {
    final response = await _dioClient.get(
      '${ApiConstants.vinculacion}/check-ruc/$ruc',
    );
    if (response.data == null || (response.data is String && response.data == 'null')) {
      return null;
    }
    return response.data as Map<String, dynamic>;
  }

  // ─── CRUD Vinculaciones ───

  Future<VinculacionEmpresaModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.vinculacion,
      data: data,
    );
    return VinculacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> listar({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.vinculacion,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<VinculacionEmpresaModel> getById(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.vinculacion}/$id',
    );
    return VinculacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<VinculacionEmpresaModel>> getPendientes() async {
    final response = await _dioClient.get(
      '${ApiConstants.vinculacion}/pendientes',
    );
    return (response.data as List)
        .map((e) => VinculacionEmpresaModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  // ─── Acciones ───

  Future<VinculacionEmpresaModel> responder(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.vinculacion}/$id/responder',
      data: data,
    );
    return VinculacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<VinculacionEmpresaModel> cancelar(String id) async {
    final response = await _dioClient.patch(
      '${ApiConstants.vinculacion}/$id/cancelar',
    );
    return VinculacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<VinculacionEmpresaModel> desvincular(String id) async {
    final response = await _dioClient.patch(
      '${ApiConstants.vinculacion}/$id/desvincular',
    );
    return VinculacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
