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
  }) {
    return _repository.getResumen(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }
}
