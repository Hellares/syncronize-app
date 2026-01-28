import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class ResolverItemUsecase {
  final ReporteIncidenciaRepository _repository;

  ResolverItemUsecase(this._repository);

  Future<Resource<ReporteIncidenciaItem>> call({
    required String reporteId,
    required String itemId,
    required AccionIncidenciaProducto accionTomada,
    String? observaciones,
    String? sedeDestinoId,
  }) async {
    return await _repository.resolverItem(
      reporteId: reporteId,
      itemId: itemId,
      accionTomada: accionTomada,
      observaciones: observaciones,
      sedeDestinoId: sedeDestinoId,
    );
  }
}
