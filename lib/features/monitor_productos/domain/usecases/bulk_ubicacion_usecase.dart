import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/monitor_productos_repository.dart';

@injectable
class BulkUbicacionUseCase {
  final MonitorProductosRepository _repository;
  BulkUbicacionUseCase(this._repository);

  Future<Resource<void>> call(List<String> ids, String ubicacion) {
    return _repository.bulkUbicacion(ids, ubicacion);
  }
}
