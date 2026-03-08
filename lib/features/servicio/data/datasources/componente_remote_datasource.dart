import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/componente_model.dart';

@lazySingleton
class ComponenteRemoteDataSource {
  final DioClient _dioClient;

  ComponenteRemoteDataSource(this._dioClient);

  Future<List<TipoComponenteModel>> getTipos() async {
    final response = await _dioClient.get(ApiConstants.tiposComponente);
    return (response.data as List)
        .map((e) => TipoComponenteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TipoComponenteModel> crearTipo(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.tiposComponente,
      data: data,
    );
    return TipoComponenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getComponentes({
    String? tipoComponenteId,
    String? search,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (tipoComponenteId != null) queryParams['tipoComponenteId'] = tipoComponenteId;
    if (search != null) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dioClient.get(
      ApiConstants.componentes,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ComponenteModel> crearComponente(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.componentes,
      data: data,
    );
    return ComponenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComponenteModel> getComponente(String id) async {
    final response = await _dioClient.get('${ApiConstants.componentes}/$id');
    return ComponenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComponenteModel> findOrCreateComponente(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '${ApiConstants.componentes}/find-or-create',
      data: data,
    );
    return ComponenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> getMarcas({required String tipoComponenteId}) async {
    final response = await _dioClient.get(
      '${ApiConstants.componentes}/marcas',
      queryParameters: {'tipoComponenteId': tipoComponenteId},
    );
    return ((response.data as Map<String, dynamic>)['marcas'] as List)
        .map((e) => e as String)
        .toList();
  }

  Future<List<String>> getModelos({
    required String tipoComponenteId,
    required String marca,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.componentes}/modelos',
      queryParameters: {
        'tipoComponenteId': tipoComponenteId,
        'marca': marca,
      },
    );
    return ((response.data as Map<String, dynamic>)['modelos'] as List)
        .map((e) => e as String)
        .toList();
  }
}
