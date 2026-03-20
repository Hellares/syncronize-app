import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/carrito.dart';
import '../repositories/carrito_repository.dart';

@injectable
class VaciarCarritoUseCase {
  final CarritoRepository _repository;

  VaciarCarritoUseCase(this._repository);

  Future<Resource<Carrito>> call() {
    return _repository.vaciarCarrito();
  }
}
