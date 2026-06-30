import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_marketplace.dart';
import '../repositories/marketplace_repository.dart';

@injectable
class GetRecomendadosUseCase {
  final MarketplaceRepository _repository;

  GetRecomendadosUseCase(this._repository);

  Future<Resource<List<ProductoMarketplace>>> call({int limit = 12}) {
    return _repository.getRecomendados(limit: limit);
  }
}
