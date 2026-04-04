import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/comprobante_condicion_card.dart';
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

  Future<VentaModel> crearYCobrar(Map<String, dynamic> data) async {
    final response = await _dioClient.post('$_basePath/cobrar', data: data);
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

  Future<VentaModel> anularVenta(String id, {
    required String autorizadoPorId,
    required String motivo,
  }) async {
    final response = await _dioClient.post('$_basePath/$id/anular', data: {
      'autorizadoPorId': autorizadoPorId,
      'motivo': motivo,
    });
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> generarComprobante(String id, {
    required String tipoComprobante,
    String? tipoDocumentoCliente,
  }) async {
    final response = await _dioClient.post('$_basePath/$id/generar-comprobante', data: {
      'tipoComprobante': tipoComprobante,
      if (tipoDocumentoCliente != null) 'tipoDocumentoCliente': tipoDocumentoCliente,
    });
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── SUNAT / Nubefact ──

  Future<Map<String, dynamic>> reenviarASunat(String comprobanteId) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/enviar');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> anularComprobante(String comprobanteId, String motivo) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/anular', data: {
      'motivo': motivo,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> crearNotaCredito(String comprobanteId, {
    required String sedeId,
    required int tipoNota,
    required String motivo,
  }) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/nota-credito', data: {
      'sedeId': sedeId,
      'tipoNota': tipoNota,
      'motivo': motivo,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> crearNotaDebito(String comprobanteId, {
    required String sedeId,
    required int tipoNota,
    required String motivo,
  }) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/nota-debito', data: {
      'sedeId': sedeId,
      'tipoNota': tipoNota,
      'motivo': motivo,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<EmisorItem>> listarEmisores() async {
    final response = await _dioClient.get('/sunat/emisores');
    final list = response.data as List<dynamic>;
    return list.map((e) => EmisorItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getConfiguracionSunat({String? sedeId}) async {
    final params = <String, dynamic>{};
    if (sedeId != null) params['sedeId'] = sedeId;
    final response = await _dioClient.get('/sunat/configuracion', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<VentaModel?> buscarPorCodigo(String codigo) async {
    try {
      final response = await _dioClient.get(
        '$_basePath/buscar',
        queryParameters: {'codigo': codigo},
      );
      if (response.data == null) return null;
      return VentaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        return null;
      }
      rethrow;
    }
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
