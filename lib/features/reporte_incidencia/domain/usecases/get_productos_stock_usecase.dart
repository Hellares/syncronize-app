import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../reporte_incidencia/data/models/producto_stock_simple_model.dart';
import '../../data/repositories/productos_stock_repository.dart';

@injectable
class GetProductosStockUseCase {
  final ProductosStockRepository _repository;

  GetProductosStockUseCase(this._repository);

  Future<Resource<List<ProductoStockSimpleModel>>> call({
    required String empresaId,
    required String sedeId,
  }) async {
    return await _repository.getProductosStock(
      empresaId: empresaId,
      sedeId: sedeId,
    );
  }
}
