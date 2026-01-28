import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class AgregarItemUsecase {
  final ReporteIncidenciaRepository _repository;

  AgregarItemUsecase(this._repository);

  Future<Resource<ReporteIncidenciaItem>> call({
    required String reporteId,
    required String productoStockId,
    required TipoIncidenciaProducto tipo,
    required int cantidadAfectada,
    required String descripcion,
    String? observaciones,
  }) async {
    return await _repository.agregarItem(
      reporteId: reporteId,
      productoStockId: productoStockId,
      tipo: tipo,
      cantidadAfectada: cantidadAfectada,
      descripcion: descripcion,
      observaciones: observaciones,
    );
  }
}
