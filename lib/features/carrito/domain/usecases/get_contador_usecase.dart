import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/carrito_repository.dart';

@injectable
class GetContadorUseCase {
  final CarritoRepository _repository;

  GetContadorUseCase(this._repository);

  Future<Resource<CarritoContador>> call() {
    return _repository.getContador();
  }
}
