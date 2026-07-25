import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/sincronizacion_series.dart';
import '../repositories/monitor_facturacion_repository.dart';

@lazySingleton
class PreviewSincronizacionUseCase {
  final MonitorFacturacionRepository _repository;
  PreviewSincronizacionUseCase(this._repository);

  Future<Resource<SincronizacionPreview>> call({String? sedeId, String? emisorId}) {
    return _repository.previewSincronizacion(sedeId: sedeId, emisorId: emisorId);
  }
}
