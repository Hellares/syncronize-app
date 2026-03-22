import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tipo_cambio_model.dart';

@lazySingleton
class TipoCambioRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/tipo-cambio';

  TipoCambioRemoteDataSource(this._dioClient);

  Future<TipoCambioModel> getHoy() async {
    final response = await _dioClient.get('$_basePath/hoy');
    return TipoCambioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TipoCambioModel>> getHistorial({
    String? fechaDesde,
    String? fechaHasta,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dioClient.get(
      '$_basePath/historial',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => TipoCambioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TipoCambioModel> registrarManual({
    required double compra,
    required double venta,
    required String fecha,
  }) async {
    final response = await _dioClient.post(
      '$_basePath/manual',
      data: {
        'compra': compra,
        'venta': venta,
        'fecha': fecha,
      },
    );
    return TipoCambioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConfiguracionMonedaModel> getConfiguracion() async {
    final response = await _dioClient.get('$_basePath/configuracion');
    return ConfiguracionMonedaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
