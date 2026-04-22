import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/sincronizacion_series.dart';
import '../repositories/monitor_facturacion_repository.dart';

@lazySingleton
class AplicarSincronizacionUseCase {
  final MonitorFacturacionRepository _repository;
  AplicarSincronizacionUseCase(this._repository);

  Future<Resource<ResultadoSincronizacion>> call({
    required String sedeId,
    required List<SeleccionSerie> selecciones,
    dynamic branchIdProveedor,
  }) {
    return _repository.aplicarSincronizacion(
      sedeId: sedeId,
      selecciones: selecciones,
      branchIdProveedor: branchIdProveedor,
    );
  }
}
