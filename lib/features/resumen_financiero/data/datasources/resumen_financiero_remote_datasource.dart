import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/resumen_financiero_model.dart';

@lazySingleton
class ResumenFinancieroRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/resumen-financiero';

  ResumenFinancieroRemoteDataSource(this._dioClient);

  Future<ResumenFinancieroModel> getResumen({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    return ResumenFinancieroModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<GraficoDiarioModel> getGraficoDiario({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;

    final response = await _dioClient.get(
      '$_basePath/grafico-diario',
      queryParameters: queryParams,
    );

    return GraficoDiarioModel.fromJson(response.data as List<dynamic>);
  }

  // ===== EXPORT EXCEL =====

  Future<List<int>> exportLibroContable({
    required int mes,
    required int anio,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final response = await _dioClient.get(
      '/reportes-financieros/export/libro-contable',
      queryParameters: {'mes': mes, 'anio': anio},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
      onReceiveProgress: onReceiveProgress,
    );
    return response.data as List<int>;
  }

  Future<List<int>> exportCuentasCobrar({
    void Function(int, int)? onReceiveProgress,
  }) async {
    final response = await _dioClient.get(
      '/reportes-financieros/export/cuentas-cobrar',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
      onReceiveProgress: onReceiveProgress,
    );
    return response.data as List<int>;
  }

  Future<List<int>> exportCuentasPagar({
    void Function(int, int)? onReceiveProgress,
  }) async {
    final response = await _dioClient.get(
      '/reportes-financieros/export/cuentas-pagar',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
      onReceiveProgress: onReceiveProgress,
    );
    return response.data as List<int>;
  }
}
