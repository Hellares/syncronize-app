import '../../../../core/utils/resource.dart';
import '../models/producto_stock_simple_model.dart';

abstract class ProductosStockRepository {
  Future<Resource<List<ProductoStockSimpleModel>>> getProductosStock({
    required String empresaId,
    required String sedeId,
  });
}
