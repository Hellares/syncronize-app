import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/guia_remision_model.dart';

@lazySingleton
class GuiaRemisionRemoteDatasource {
  final DioClient _dioClient;
  static const _basePath = '/guias-remision';

  GuiaRemisionRemoteDatasource(this._dioClient);

  Future<({List<GuiaRemisionModel> data, int total, int totalPages})> listar({
    String? tipo,
    String? estado,
    String? sunatStatus,
    String? motivoTraslado,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (tipo != null) params['tipo'] = tipo;
    if (estado != null) params['estado'] = estado;
    if (sunatStatus != null) params['sunatStatus'] = sunatStatus;
    if (motivoTraslado != null) params['motivoTraslado'] = motivoTraslado;
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;

    final response = await _dioClient.get(_basePath, queryParameters: params);
    final body = response.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .map((e) => GuiaRemisionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      data: items,
      total: body['total'] as int? ?? 0,
      totalPages: body['totalPages'] as int? ?? 1,
    );
  }

  Future<GuiaRemisionModel> obtener(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return GuiaRemisionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GuiaRemisionModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return GuiaRemisionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GuiaRemisionModel> actualizar(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('$_basePath/$id', data: data);
    return GuiaRemisionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> prefillDesdeVenta(String ventaId) async {
    final response = await _dioClient.get('$_basePath/prefill/venta/$ventaId');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getUbigeos() async {
    final response = await _dioClient.get('$_basePath/catalogos/ubigeos');
    final list = response.data as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> enviar(String id) async {
    final response = await _dioClient.post('$_basePath/$id/enviar');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> consultar(String id) async {
    final response = await _dioClient.get('$_basePath/$id/consultar');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enviarPendientes() async {
    final response = await _dioClient.post('$_basePath/enviar-pendientes');
    return response.data as Map<String, dynamic>;
  }

  // --- Vehiculos ---

  Future<List<VehiculoEmpresaModel>> listarVehiculos() async {
    final response = await _dioClient.get('$_basePath/catalogos/vehiculos');
    final list = response.data as List;
    return list
        .map((e) => VehiculoEmpresaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VehiculoEmpresaModel> crearVehiculo(Map<String, dynamic> data) async {
    final response = await _dioClient.post('$_basePath/catalogos/vehiculos', data: data);
    return VehiculoEmpresaModel.fromJson(response.data as Map<String, dynamic>);
  }

  // --- Conductores ---

  Future<List<ConductorEmpresaModel>> listarConductores() async {
    final response = await _dioClient.get('$_basePath/catalogos/conductores');
    final list = response.data as List;
    return list
        .map((e) => ConductorEmpresaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConductorEmpresaModel> crearConductor(Map<String, dynamic> data) async {
    final response = await _dioClient.post('$_basePath/catalogos/conductores', data: data);
    return ConductorEmpresaModel.fromJson(response.data as Map<String, dynamic>);
  }

  // --- Transportistas ---

  Future<List<TransportistaEmpresaModel>> listarTransportistas() async {
    final response = await _dioClient.get('$_basePath/catalogos/transportistas');
    final list = response.data as List;
    return list
        .map((e) => TransportistaEmpresaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransportistaEmpresaModel> crearTransportista(Map<String, dynamic> data) async {
    final response = await _dioClient.post('$_basePath/catalogos/transportistas', data: data);
    return TransportistaEmpresaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
