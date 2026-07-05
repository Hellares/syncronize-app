import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../cotizacion/data/models/cotizacion_model.dart';

/// Datasource único de cotizaciones (POS-style).
///
/// Sustituye al antiguo `CotizacionRemoteDataSource` del módulo
/// `features/cotizacion`, que quedó deprecado. Todos los repositorios
/// (regular + rápido) consumen esta clase.
@lazySingleton
class CotizacionRapidaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/cotizaciones';

  CotizacionRapidaRemoteDataSource(this._dioClient);

  /// POST /cotizaciones
  Future<CotizacionModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /cotizaciones?sedeId=...&estado=...
  Future<List<CotizacionModel>> listar({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;
    if (estado != null) queryParams['estado'] = estado;
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;
    if (clienteId != null) queryParams['clienteId'] = clienteId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final data = response.data as List;
    return data
        .map((e) => CotizacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /cotizaciones con paginación por CURSOR (patrón estándar para
  /// listas transaccionales — mismo esquema que compras/kardex). Con
  /// `limit` el backend responde `{ data, hasMore, nextCursor }`.
  Future<({List<CotizacionModel> items, bool hasMore, String? nextCursor})>
      listarPaginado({
    String? sedeId,
    String? estado,
    String? search,
    required int limit,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (sedeId != null) queryParams['sedeId'] = sedeId;
    if (estado != null) queryParams['estado'] = estado;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (cursor != null) queryParams['cursor'] = cursor;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .map((e) => CotizacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      hasMore: body['hasMore'] as bool? ?? false,
      nextCursor: body['nextCursor'] as String?,
    );
  }

  /// GET /cotizaciones/:id
  Future<CotizacionModel> obtener(String cotizacionId) async {
    final response = await _dioClient.get('$_basePath/$cotizacionId');
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /cotizaciones/:id
  Future<CotizacionModel> actualizar(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(
      '$_basePath/$cotizacionId',
      data: data,
    );
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /cotizaciones/:id/estado
  Future<CotizacionModel> cambiarEstado(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '$_basePath/$cotizacionId/estado',
      data: data,
    );
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /cotizaciones/:id/duplicar
  Future<CotizacionModel> duplicar(String cotizacionId) async {
    final response = await _dioClient.post('$_basePath/$cotizacionId/duplicar');
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /cotizaciones/validar-compatibilidad
  Future<Map<String, dynamic>> validarCompatibilidad(
    List<Map<String, dynamic>> detalles,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/validar-compatibilidad',
      data: detalles,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /cotizaciones/:id
  Future<void> eliminar(String cotizacionId) async {
    await _dioClient.delete('$_basePath/$cotizacionId');
  }
}
