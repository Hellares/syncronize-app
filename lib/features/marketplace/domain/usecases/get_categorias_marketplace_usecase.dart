import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/categoria_marketplace.dart';
import '../repositories/marketplace_repository.dart';

@injectable
class GetCategoriasMarketplaceUseCase {
  final MarketplaceRepository _repository;

  GetCategoriasMarketplaceUseCase(this._repository);

  Future<Resource<List<CategoriaMarketplace>>> call() {
    return _repository.getCategorias();
  }
}
