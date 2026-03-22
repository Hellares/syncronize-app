import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/monitor_productos_model.dart';

@lazySingleton
class MonitorProductosRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/producto-stock';

  MonitorProductosRemoteDataSource(this._dioClient);

  Future<MonitorProductosModel> getMonitor({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/monitor',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return MonitorProductosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> bulkMarketplace(List<String> ids, bool visible) async {
    await _dioClient.patch(
      '$_basePath/bulk/marketplace',
      data: {
        'ids': ids,
        'visible': visible,
      },
    );
  }

  Future<void> bulkUbicacion(List<String> ids, String ubicacion) async {
    await _dioClient.patch(
      '$_basePath/bulk/ubicacion',
      data: {
        'ids': ids,
        'ubicacion': ubicacion,
      },
    );
  }

  Future<void> bulkPrecioIgv(List<String> ids, bool incluyeIgv) async {
    await _dioClient.patch(
      '$_basePath/bulk/precio-igv',
      data: {
        'ids': ids,
        'incluyeIgv': incluyeIgv,
      },
    );
  }
}
