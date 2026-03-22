import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/dashboard_vendedor.dart';
import '../repositories/dashboard_vendedor_repository.dart';

@injectable
class GetDashboardVendedorUseCase {
  final DashboardVendedorRepository _repository;
  GetDashboardVendedorUseCase(this._repository);

  Future<Resource<DashboardVendedor>> call({
    String? vendedorId,
    String? sedeId,
  }) {
    return _repository.getDashboard(vendedorId: vendedorId, sedeId: sedeId);
  }
}
