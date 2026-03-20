import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/carrito.dart';
import '../repositories/carrito_repository.dart';

@injectable
class EliminarItemUseCase {
  final CarritoRepository _repository;

  EliminarItemUseCase(this._repository);

  Future<Resource<Carrito>> call({required String itemId}) {
    return _repository.eliminarItem(itemId: itemId);
  }
}
