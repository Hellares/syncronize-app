import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/caja_model.dart';
import '../models/movimiento_caja_model.dart';
import '../models/resumen_caja_model.dart';

@lazySingleton
class CajaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/caja';

  CajaRemoteDataSource(this._dioClient);

  Future<CajaModel> abrirCaja({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
    String? sedeFacturacionId,
  }) async {
    final data = <String, dynamic>{
      'sedeId': sedeId,
      'montoApertura': montoApertura,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      data['observaciones'] = observaciones;
    }
    if (sedeFacturacionId != null && sedeFacturacionId.isNotEmpty) {
      data['sedeFacturacionId'] = sedeFacturacionId;
    }

    final response = await _dioClient.post('$_basePath/abrir', data: data);
    return CajaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CajaModel?> getCajaActiva() async {
    try {
      final response = await _dioClient.get('$_basePath/activa');
      final data = response.data;
      if (data == null || data == '' || data is! Map<String, dynamic>) {
        return null;
      }
      return CajaModel.fromJson(data);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> crearMovimiento({
    required String cajaId,
    required String tipo,
    required String categoria,
    required String metodoPago,
    required double monto,
    String? descripcion,
    String? categoriaGastoId,
  }) async {
    final data = <String, dynamic>{
      'tipo': tipo,
      'categoria': categoria,
      'metodoPago': metodoPago,
      'monto': monto,
    };
    if (descripcion != null && descripcion.isNotEmpty) {
      data['descripcion'] = descripcion;
    }
    if (categoriaGastoId != null && categoriaGastoId.isNotEmpty) {
      data['categoriaGastoId'] = categoriaGastoId;
    }

    await _dioClient.post('$_basePath/$cajaId/movimiento', data: data);
  }

  Future<List<MovimientoCajaModel>> getMovimientos(String cajaId) async {
    final response = await _dioClient.get('$_basePath/$cajaId/movimientos');
    final data = response.data as List;
    return data
        .map((e) => MovimientoCajaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cerrarCaja({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
  }) async {
    final data = <String, dynamic>{
      'conteos': conteos,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      data['observaciones'] = observaciones;
    }

    await _dioClient.post('$_basePath/$cajaId/cerrar', data: data);
  }

  Future<List<CajaModel>> getHistorial({
    String? sedeId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;

    final response = await _dioClient.get(
      '$_basePath/historial',
      queryParameters: queryParams,
    );

    final data = response.data as List;
    return data
        .map((e) => CajaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenCajaModel> getResumen(String cajaId) async {
    final response = await _dioClient.get('$_basePath/$cajaId/resumen');
    return ResumenCajaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> anularMovimiento({
    required String cajaId,
    required String movimientoId,
    required String autorizadoPorId,
    required String motivo,
  }) async {
    await _dioClient.post(
      '$_basePath/$cajaId/movimiento/$movimientoId/anular',
      data: {'autorizadoPorId': autorizadoPorId, 'motivo': motivo},
    );
  }

  Future<Map<String, dynamic>> getMonitor({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/monitor',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
