import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/monitor_productos_repository.dart';

@injectable
class BulkMarketplaceUseCase {
  final MonitorProductosRepository _repository;
  BulkMarketplaceUseCase(this._repository);

  Future<Resource<void>> call(List<String> ids, bool visible) {
    return _repository.bulkMarketplace(ids, visible);
  }
}
