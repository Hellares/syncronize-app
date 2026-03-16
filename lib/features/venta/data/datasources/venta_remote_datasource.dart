import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/venta_model.dart';

@lazySingleton
class VentaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/ventas';

  VentaRemoteDataSource(this._dioClient);

  Future<VentaModel> crearVenta(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> crearVentaDesdeCotizacion(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/desde-cotizacion/$cotizacionId',
      data: data,
    );
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<VentaModel>> getVentas({
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
        .map((e) => VentaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VentaModel> getVenta(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> actualizarVenta(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put('$_basePath/$id', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> confirmarVenta(String id) async {
    final response = await _dioClient.post('$_basePath/$id/confirmar');
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> procesarPago(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post('$_basePath/$id/pago', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> anularVenta(String id) async {
    final response = await _dioClient.post('$_basePath/$id/anular');
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getResumen({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/resumen',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
