import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cotizacion_model.dart';

/// Data source remoto para operaciones de cotizaciones
@lazySingleton
class CotizacionRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/cotizaciones';

  CotizacionRemoteDataSource(this._dioClient);

  /// Crear cotizacion
  /// POST /cotizaciones
  Future<CotizacionModel> crearCotizacion(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      _basePath,
      data: data,
    );
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Listar cotizaciones con filtros
  /// GET /cotizaciones?sedeId=...&estado=...
  Future<List<CotizacionModel>> getCotizaciones({
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

  /// Obtener cotizacion por ID
  /// GET /cotizaciones/:id
  Future<CotizacionModel> getCotizacion(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualizar cotizacion
  /// PUT /cotizaciones/:id
  Future<CotizacionModel> actualizarCotizacion(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(
      '$_basePath/$id',
      data: data,
    );
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cambiar estado de cotizacion
  /// PATCH /cotizaciones/:id/estado
  Future<CotizacionModel> cambiarEstado(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '$_basePath/$id/estado',
      data: data,
    );
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Duplicar cotizacion
  /// POST /cotizaciones/:id/duplicar
  Future<CotizacionModel> duplicarCotizacion(String id) async {
    final response = await _dioClient.post('$_basePath/$id/duplicar');
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Validar compatibilidad de items
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

  /// Eliminar cotizacion
  /// DELETE /cotizaciones/:id
  Future<void> eliminarCotizacion(String id) async {
    await _dioClient.delete('$_basePath/$id');
  }
}
