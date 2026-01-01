import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_repository.dart';

/// Use case para eliminar un producto (soft delete)
@injectable
class EliminarProductoUseCase {
  final ProductoRepository _repository;

  EliminarProductoUseCase(this._repository);

  Future<Resource<void>> call({
    required String productoId,
    required String empresaId,
  }) async {
    return await _repository.eliminarProducto(
      productoId: productoId,
      empresaId: empresaId,
    );
  }
}
