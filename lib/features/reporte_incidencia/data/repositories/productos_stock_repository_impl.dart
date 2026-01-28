import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../datasources/productos_stock_remote_datasource.dart';
import '../models/producto_stock_simple_model.dart';
import 'productos_stock_repository.dart';

@Injectable(as: ProductosStockRepository)
class ProductosStockRepositoryImpl implements ProductosStockRepository {
  final ProductosStockRemoteDatasource _remoteDatasource;

  ProductosStockRepositoryImpl(this._remoteDatasource);

  @override
  Future<Resource<List<ProductoStockSimpleModel>>> getProductosStock({
    required String empresaId,
    required String sedeId,
  }) async {
    try {
      final productos = await _remoteDatasource.getProductosStock(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      return Success(productos);
    } catch (e) {
      return Error(
        e.toString(),
        errorCode: 'PRODUCTOS_STOCK_ERROR',
      );
    }
  }
}
