import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_vendedor_model.dart';

@lazySingleton
class DashboardVendedorRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/ventas/analytics';

  DashboardVendedorRemoteDataSource(this._dioClient);

  Future<DashboardVendedorModel> getDashboard({
    String? vendedorId,
    String? sedeId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (vendedorId != null) queryParams['vendedorId'] = vendedorId;
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/dashboard-vendedor',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return DashboardVendedorModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
