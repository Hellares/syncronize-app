import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_marketplace.dart';
import '../repositories/marketplace_repository.dart';

@injectable
class GetProductosVistosUseCase {
  final MarketplaceRepository _repository;

  GetProductosVistosUseCase(this._repository);

  Future<Resource<List<ProductoMarketplace>>> call({int limit = 10}) {
    return _repository.getVistos(limit: limit);
  }
}
