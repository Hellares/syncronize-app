import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/monitor_productos.dart';
import '../repositories/monitor_productos_repository.dart';

@injectable
class GetMonitorProductosUseCase {
  final MonitorProductosRepository _repository;
  GetMonitorProductosUseCase(this._repository);

  Future<Resource<MonitorProductos>> call({String? sedeId}) {
    return _repository.getMonitor(sedeId: sedeId);
  }
}
