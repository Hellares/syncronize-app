import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/comprobante_item.dart';
import '../repositories/monitor_facturacion_repository.dart';

@lazySingleton
class ListarComprobantesUseCase {
  final MonitorFacturacionRepository _repository;
  ListarComprobantesUseCase(this._repository);

  Future<Resource<({List<ComprobanteItem> data, int total, int totalPages})>> call({
    String? tipo,
    String? sunatStatus,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.listar(
      tipo: tipo,
      sunatStatus: sunatStatus,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      busqueda: busqueda,
      page: page,
      limit: limit,
    );
  }
}
