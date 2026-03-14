import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tercerizacion_model.dart';

@lazySingleton
class TercerizacionRemoteDataSource {
  final DioClient _dioClient;

  TercerizacionRemoteDataSource(this._dioClient);

  // ─── Empresas vinculadas ───

  Future<List<Map<String, dynamic>>> getEmpresasVinculadas() async {
    final response = await _dioClient.get(
      '${ApiConstants.tercerizacion}/vinculadas',
    );
    return (response.data as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ─── Directorio ───

  Future<Map<String, dynamic>> buscarEmpresas({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.tercerizacion}/directorio',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── CRUD Tercerizaciones ───

  Future<TercerizacionServicioModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.tercerizacion,
      data: data,
    );
    return TercerizacionServicioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> listar({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.tercerizacion,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<TercerizacionServicioModel> getById(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.tercerizacion}/$id',
    );
    return TercerizacionServicioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<TercerizacionServicioModel>> getPendientes() async {
    final response = await _dioClient.get(
      '${ApiConstants.tercerizacion}/pendientes',
    );
    return (response.data as List)
        .map((e) => TercerizacionServicioModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  // ─── Acciones ───

  Future<TercerizacionServicioModel> responder(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.tercerizacion}/$id/responder',
      data: data,
    );
    return TercerizacionServicioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<TercerizacionServicioModel> completar(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.tercerizacion}/$id/completar',
      data: data,
    );
    return TercerizacionServicioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<TercerizacionServicioModel> cancelar(String id) async {
    final response = await _dioClient.patch(
      '${ApiConstants.tercerizacion}/$id/cancelar',
    );
    return TercerizacionServicioModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
