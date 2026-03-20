import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/carrito.dart';
import '../repositories/carrito_repository.dart';

@injectable
class GetCarritoUseCase {
  final CarritoRepository _repository;

  GetCarritoUseCase(this._repository);

  Future<Resource<Carrito>> call() {
    return _repository.getCarrito();
  }
}
