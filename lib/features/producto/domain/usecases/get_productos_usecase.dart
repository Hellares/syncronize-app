import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_filtros.dart';
import '../repositories/producto_repository.dart';

/// Use case para obtener lista paginada de productos con filtros
@injectable
class GetProductosUseCase {
  final ProductoRepository _repository;

  GetProductosUseCase(this._repository);

  Future<Resource<ProductosPaginados>> call({
    required String empresaId,
    required ProductoFiltros filtros,
  }) async {
    return await _repository.getProductos(
      empresaId: empresaId,
      filtros: filtros,
    );
  }
}
