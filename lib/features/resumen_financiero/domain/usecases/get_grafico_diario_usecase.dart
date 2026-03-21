import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/resumen_financiero.dart';
import '../repositories/resumen_financiero_repository.dart';

@injectable
class GetGraficoDiarioUseCase {
  final ResumenFinancieroRepository _repository;

  GetGraficoDiarioUseCase(this._repository);

  Future<Resource<GraficoDiario>> call({
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return _repository.getGraficoDiario(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }
}
