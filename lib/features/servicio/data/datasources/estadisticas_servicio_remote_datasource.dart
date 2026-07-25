import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/estadisticas_servicio_model.dart';

@lazySingleton
class EstadisticasServicioRemoteDataSource {
  final DioClient _dioClient;

  EstadisticasServicioRemoteDataSource(this._dioClient);

  Future<EstadisticasServicioModel> getEstadisticas({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;

    final response = await _dioClient.get(
      '${ApiConstants.ordenesServicio}/estadisticas',
      queryParameters: queryParams,
    );

    return EstadisticasServicioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Dashboard consolidado (KPIs, embudo, técnicos, equipos, calidad) en
  /// UNA respuesta — el shape se consume como Map en la página.
  Future<Map<String, dynamic>> getDashboard({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;

    final response = await _dioClient.get(
      '${ApiConstants.ordenesServicio}/estadisticas/dashboard',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
