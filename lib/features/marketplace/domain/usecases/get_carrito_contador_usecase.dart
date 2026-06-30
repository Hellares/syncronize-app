import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/marketplace_repository.dart';

@injectable
class GetCarritoContadorUseCase {
  final MarketplaceRepository _repository;

  GetCarritoContadorUseCase(this._repository);

  Future<Resource<int>> call() {
    return _repository.getCarritoContador();
  }
}
