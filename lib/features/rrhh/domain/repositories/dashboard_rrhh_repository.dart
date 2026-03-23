import '../../../../core/utils/resource.dart';
import '../entities/dashboard_rrhh.dart';

abstract class DashboardRrhhRepository {
  Future<Resource<DashboardRrhh>> getDashboard();
}
