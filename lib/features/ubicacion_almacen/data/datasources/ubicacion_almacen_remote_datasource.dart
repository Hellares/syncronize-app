import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ubicacion_almacen_model.dart';

@lazySingleton
class UbicacionAlmacenRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/ubicaciones-almacen';

  UbicacionAlmacenRemoteDataSource(this._dioClient);

  /// Lista ubicaciones de una sede con filtros opcionales.
  Future<List<UbicacionAlmacenModel>> getUbicaciones(
    String sedeId, {
    String? tipo,
    String? parentId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (tipo != null) queryParams['tipo'] = tipo;
    if (parentId != null) queryParams['parentId'] = parentId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dioClient.get(
      '$_basePath/sede/$sedeId',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data;
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .map((e) => UbicacionAlmacenModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el arbol jerarquico completo de ubicaciones de una sede.
  Future<List<UbicacionAlmacenModel>> getArbol(String sedeId) async {
    final response = await _dioClient.get('$_basePath/sede/$sedeId/arbol');
    final data = response.data;
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .map((e) => UbicacionAlmacenModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el detalle de una ubicacion por id.
  Future<UbicacionAlmacenModel> getDetalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return UbicacionAlmacenModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Crea una nueva ubicacion en una sede.
  Future<UbicacionAlmacenModel> crear(
    String sedeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/sede/$sedeId',
      data: data,
    );
    return UbicacionAlmacenModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Actualiza una ubicacion existente.
  Future<UbicacionAlmacenModel> actualizar(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return UbicacionAlmacenModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Desactiva (elimina logicamente) una ubicacion.
  Future<void> desactivar(String id) async {
    await _dioClient.delete('$_basePath/$id');
  }
}
