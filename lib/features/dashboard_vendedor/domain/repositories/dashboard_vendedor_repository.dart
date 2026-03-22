import '../../../../core/utils/resource.dart';
import '../entities/dashboard_vendedor.dart';

abstract class DashboardVendedorRepository {
  Future<Resource<DashboardVendedor>> getDashboard({
    String? vendedorId,
    String? sedeId,
  });
}
