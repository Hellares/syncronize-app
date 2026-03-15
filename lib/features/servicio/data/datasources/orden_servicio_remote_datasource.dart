import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/orden_servicio_model.dart';
import '../../domain/entities/servicio_filtros.dart';

@lazySingleton
class OrdenServicioRemoteDataSource {
  final DioClient _dioClient;

  OrdenServicioRemoteDataSource(this._dioClient);

  Future<OrdenServicioModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.ordenesServicio,
      data: data,
    );
    return OrdenServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getOrdenes({
    required String empresaId,
    required OrdenServicioFiltros filtros,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.ordenesServicio,
      queryParameters: filtros.toQueryParams(),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMisOrdenes({
    required OrdenServicioFiltros filtros,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.ordenesServicio}/mis-ordenes',
      queryParameters: filtros.toQueryParams(),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<OrdenServicioModel> getOrden(String id) async {
    final response = await _dioClient.get('${ApiConstants.ordenesServicio}/$id');
    return OrdenServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenServicioModel> actualizar(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiConstants.ordenesServicio}/$id',
      data: data,
    );
    return OrdenServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenServicioModel> transitionEstado(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.ordenesServicio}/$id/estado',
      data: data,
    );
    return OrdenServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenServicioModel> assignTecnico(String id, String tecnicoId) async {
    final response = await _dioClient.patch(
      '${ApiConstants.ordenesServicio}/$id/tecnico',
      data: {'tecnicoId': tecnicoId},
    );
    return OrdenServicioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenComponenteModel> addComponente(
    String ordenId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '${ApiConstants.ordenesServicio}/$ordenId/componentes',
      data: data,
    );
    return OrdenComponenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OrdenComponenteModel>> getComponentes(String ordenId) async {
    final response = await _dioClient.get(
      '${ApiConstants.ordenesServicio}/$ordenId/componentes',
    );
    return (response.data as List)
        .map((e) => OrdenComponenteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeComponente(String ordenId, String componenteId) async {
    await _dioClient.delete(
      '${ApiConstants.ordenesServicio}/$ordenId/componentes/$componenteId',
    );
  }

  Future<List<HistorialOrdenServicioModel>> getHistorial(String ordenId) async {
    final response = await _dioClient.get(
      '${ApiConstants.ordenesServicio}/$ordenId/historial',
    );
    return (response.data as List)
        .map((e) => HistorialOrdenServicioModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }
}
