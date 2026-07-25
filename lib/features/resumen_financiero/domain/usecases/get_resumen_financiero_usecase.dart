import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/resumen_financiero.dart';
import '../repositories/resumen_financiero_repository.dart';

@injectable
class GetResumenFinancieroUseCase {
  final ResumenFinancieroRepository _repository;

  GetResumenFinancieroUseCase(this._repository);

  Future<Resource<ResumenFinanciero>> call({
    String? fechaDesde,
    String? fechaHasta,
    String? sedeId,
  }) {
    return _repository.getResumen(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      sedeId: sedeId,
    );
  }

  /// Resumen + gráfico en UN request. Método del mismo usecase para no
  /// tocar el registro de DI (mismo patrón que GetVentasUseCase.paginado).
  Future<Resource<DashboardFinanciero>> dashboard({
    String? fechaDesde,
    String? fechaHasta,
    String? sedeId,
  }) {
    return _repository.getDashboard(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      sedeId: sedeId,
    );
  }
}
