import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/monitor_productos_repository.dart';

@injectable
class BulkPrecioIgvUseCase {
  final MonitorProductosRepository _repository;
  BulkPrecioIgvUseCase(this._repository);

  Future<Resource<void>> call(List<String> ids, bool incluyeIgv) {
    return _repository.bulkPrecioIgv(ids, incluyeIgv);
  }
}
