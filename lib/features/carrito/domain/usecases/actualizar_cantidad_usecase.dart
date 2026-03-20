import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/carrito.dart';
import '../repositories/carrito_repository.dart';

@injectable
class ActualizarCantidadUseCase {
  final CarritoRepository _repository;

  ActualizarCantidadUseCase(this._repository);

  Future<Resource<Carrito>> call({
    required String itemId,
    required int cantidad,
  }) {
    return _repository.actualizarCantidad(
      itemId: itemId,
      cantidad: cantidad,
    );
  }
}
