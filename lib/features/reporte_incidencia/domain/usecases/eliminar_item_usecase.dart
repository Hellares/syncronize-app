import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class EliminarItemUsecase {
  final ReporteIncidenciaRepository _repository;

  EliminarItemUsecase(this._repository);

  Future<Resource<void>> call({
    required String reporteId,
    required String itemId,
  }) async {
    return await _repository.eliminarItem(
      reporteId: reporteId,
      itemId: itemId,
    );
  }
}
