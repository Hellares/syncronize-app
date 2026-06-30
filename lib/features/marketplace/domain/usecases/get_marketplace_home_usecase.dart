import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/marketplace_home.dart';
import '../repositories/marketplace_repository.dart';

@injectable
class GetMarketplaceHomeUseCase {
  final MarketplaceRepository _repository;

  GetMarketplaceHomeUseCase(this._repository);

  Future<Resource<MarketplaceHome>> call() {
    return _repository.getHome();
  }
}
