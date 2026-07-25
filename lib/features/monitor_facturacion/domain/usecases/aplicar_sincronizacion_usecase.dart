import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/sincronizacion_series.dart';
import '../repositories/monitor_facturacion_repository.dart';

@lazySingleton
class AplicarSincronizacionUseCase {
  final MonitorFacturacionRepository _repository;
  AplicarSincronizacionUseCase(this._repository);

  Future<Resource<ResultadoSincronizacion>> call({
    String? sedeId,
    String? emisorId,
    required List<SeleccionSerie> selecciones,
    dynamic branchIdProveedor,
  }) {
    return _repository.aplicarSincronizacion(
      sedeId: sedeId,
      emisorId: emisorId,
      selecciones: selecciones,
      branchIdProveedor: branchIdProveedor,
    );
  }
}
