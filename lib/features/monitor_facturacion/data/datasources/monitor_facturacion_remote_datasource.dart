import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/sincronizacion_series.dart';
import '../models/comprobante_item_model.dart';
import '../models/serie_correlativo_model.dart';
import '../models/sincronizacion_series_model.dart';

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

  /// Consulta masiva de estado SUNAT de los comprobantes PROCESANDO.
  /// Respuesta: { total, actualizados, aunProcesando, noEncontrados, errores:[] }
  Future<Map<String, dynamic>> consultarPendientes() async {
    final response = await _dioClient.post('$_basePath/comprobantes/consultar-pendientes');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> anular(String comprobanteId, String motivo) async {
    final response = await _dioClient.post('$_basePath/comprobantes/$comprobanteId/anular', data: {'motivo': motivo});
    return response.data as Map<String, dynamic>;
  }

  Future<ReporteCorrelativosModel> reporteCorrelativos({String? sedeId, String? fechaDesde, String? fechaHasta}) async {
    final params = <String, dynamic>{};
    if (sedeId != null) params['sedeId'] = sedeId;
    if (fechaDesde != null) params['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) params['fechaHasta'] = fechaHasta;
    final response = await _dioClient.get('$_basePath/reporte-correlativos', queryParameters: params);
    return ReporteCorrelativosModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SincronizacionPreview> previewSincronizacion(String sedeId) async {
    final response = await _dioClient.get(
      '$_basePath/series/preview',
      queryParameters: {'sedeId': sedeId},
    );
    return SincronizacionPreviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ResultadoSincronizacion> aplicarSincronizacion({
    required String sedeId,
    required List<SeleccionSerie> selecciones,
    dynamic branchIdProveedor,
  }) async {
    final body = <String, dynamic>{
      'sedeId': sedeId,
      'selecciones': selecciones.map((s) => s.toJson()).toList(),
    };
    if (branchIdProveedor != null) {
      body['branchIdProveedor'] = branchIdProveedor;
    }
    final response = await _dioClient.post('$_basePath/series/sincronizar', data: body);
    return ResultadoSincronizacionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
