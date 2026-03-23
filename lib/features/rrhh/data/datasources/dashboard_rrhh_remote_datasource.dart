import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_rrhh_model.dart';

@lazySingleton
class DashboardRrhhRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/rrhh-dashboard';

  DashboardRrhhRemoteDataSource(this._dioClient);

  Future<DashboardRrhhModel> getDashboard() async {
    final response = await _dioClient.get(_basePath);
    return DashboardRrhhModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
