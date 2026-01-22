import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener el stock de un producto en una sede específica
@injectable
class GetStockProductoEnSedeUseCase {
  final ProductoStockRepository _repository;

  GetStockProductoEnSedeUseCase(this._repository);

  Future<Resource<ProductoStock>> call({
    required String productoId,
    required String sedeId,
  }) async {
    return await _repository.getStockProductoEnSede(
      productoId: productoId,
      sedeId: sedeId,
    );
  }
}
