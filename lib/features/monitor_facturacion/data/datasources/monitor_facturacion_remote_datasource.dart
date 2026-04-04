import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/comprobante_item_model.dart';

@lazySingleton
class MonitorFacturacionRemoteDatasource {
  final DioClient _dioClient;
  static const _basePath = '/sunat';

  MonitorFacturacionRemoteDatasource(this._dioClient);

  Future<({List<ComprobanteItemModel> data, int total, int totalPages})> listar({
    String? tipo,
    String? sunatStatus,
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
    if (sunatStatus != null) params['sunatStatus'] = sunatStatus;
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;

    final response = await _dioClient.get('$_basePath/comprobantes', queryParameters: params);
    final body = response.data as Map<String, dynamic>;
    final items = (body['data'] as List).map((e) => ComprobanteItemModel.fromJson(e as Map<String, dynamic>)).toList();

    return (
      data: items,
      total: body['total'] as int? ?? 0,
      totalPages: body['totalPages'] as int? ?? 1,
    );
  }

  Future<Map<String, dynamic>> reenviar(String comprobanteId) async {
    final response = await _dioClient.post('$_basePath/comprobantes/$comprobanteId/enviar');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enviarPendientes() async {
    final response = await _dioClient.post('$_basePath/comprobantes/enviar-pendientes');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> anular(String comprobanteId, String motivo) async {
    final response = await _dioClient.post('$_basePath/comprobantes/$comprobanteId/anular', data: {'motivo': motivo});
    return response.data as Map<String, dynamic>;
  }
}
