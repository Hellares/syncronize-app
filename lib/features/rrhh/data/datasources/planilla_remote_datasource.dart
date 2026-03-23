import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/periodo_planilla_model.dart';
import '../models/boleta_pago_model.dart';

@lazySingleton
class PlanillaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/planilla';

  PlanillaRemoteDataSource(this._dioClient);

  // =============================================================
  // PERIODOS
  // =============================================================

  Future<PeriodoPlanillaModel> createPeriodo(
      Map<String, dynamic> data) async {
    final response =
        await _dioClient.post('$_basePath/periodos', data: data);
    return PeriodoPlanillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<PeriodoPlanillaModel>> getPeriodos({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/periodos',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) =>
            PeriodoPlanillaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPeriodosPaginated({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/periodos',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return {
      'data': data
          .map((e) =>
              PeriodoPlanillaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'meta': meta,
    };
  }

  Future<PeriodoPlanillaModel> getPeriodo(String id) async {
    final response = await _dioClient.get('$_basePath/periodos/$id');
    return PeriodoPlanillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PeriodoPlanillaModel> calcularPlanilla(String periodoId) async {
    final response =
        await _dioClient.post('$_basePath/periodos/$periodoId/calcular');
    return PeriodoPlanillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PeriodoPlanillaModel> aprobarPeriodo(String id) async {
    final response =
        await _dioClient.patch('$_basePath/periodos/$id/aprobar');
    return PeriodoPlanillaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> pagarPlanilla(
      String periodoId, Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '$_basePath/periodos/$periodoId/pagar',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // =============================================================
  // BOLETAS
  // =============================================================

  Future<List<BoletaPagoModel>> getBoletas({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/boletas',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => BoletaPagoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getBoletasPaginated({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/boletas',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return {
      'data': data
          .map((e) => BoletaPagoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'meta': meta,
    };
  }

  Future<BoletaPagoModel> getBoleta(String id) async {
    final response = await _dioClient.get('$_basePath/boletas/$id');
    return BoletaPagoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BoletaPagoModel> pagarBoleta(
      String boletaId, Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '$_basePath/boletas/$boletaId/pagar',
      data: data,
    );
    return BoletaPagoModel.fromJson(response.data as Map<String, dynamic>);
  }
}
