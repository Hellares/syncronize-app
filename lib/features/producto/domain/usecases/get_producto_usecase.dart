import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

/// Use case para obtener un producto por ID
@injectable
class GetProductoUseCase {
  final ProductoRepository _repository;

  GetProductoUseCase(this._repository);

  Future<Resource<Producto>> call({
    required String productoId,
    required String empresaId,
  }) async {
    return await _repository.getProducto(
      productoId: productoId,
      empresaId: empresaId,
    );
  }
}
