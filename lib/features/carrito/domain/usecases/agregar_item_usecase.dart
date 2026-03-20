import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/carrito.dart';
import '../repositories/carrito_repository.dart';

@injectable
class AgregarItemUseCase {
  final CarritoRepository _repository;

  AgregarItemUseCase(this._repository);

  Future<Resource<Carrito>> call({
    required String productoId,
    String? varianteId,
    int cantidad = 1,
  }) {
    return _repository.agregarItem(
      productoId: productoId,
      varianteId: varianteId,
      cantidad: cantidad,
    );
  }
}
