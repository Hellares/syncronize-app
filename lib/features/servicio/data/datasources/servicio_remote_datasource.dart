import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/servicio_model.dart';
import '../../domain/entities/servicio_filtros.dart';

@lazySingleton
class ServicioRemoteDataSource {
  final DioClient _dioClient;

  ServicioRemoteDataSource(this._dioClient);

  Future<ServicioModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.servicios,
      data: data,
    );
    return ServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getServicios({
    required String empresaId,
    required ServicioFiltros filtros,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.servicios,
      queryParameters: filtros.toQueryParams(),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ServicioModel> getServicio(String id) async {
    final response = await _dioClient.get('${ApiConstants.servicios}/$id');
    return ServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ServicioModel> actualizar(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiConstants.servicios}/$id',
      data: data,
    );
    return ServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    await _dioClient.delete('${ApiConstants.servicios}/$id');
  }
}
