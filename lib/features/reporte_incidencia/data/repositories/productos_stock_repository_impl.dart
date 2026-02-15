import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../datasources/productos_stock_remote_datasource.dart';
import '../models/producto_stock_simple_model.dart';
import 'productos_stock_repository.dart';

@Injectable(as: ProductosStockRepository)
class ProductosStockRepositoryImpl implements ProductosStockRepository {
  final ProductosStockRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  ProductosStockRepositoryImpl(
    this._remoteDatasource,
    this._networkInfo,
  );

  @override
  Future<Resource<List<ProductoStockSimpleModel>>> getProductosStock({
    required String empresaId,
    required String sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final productos = await _remoteDatasource.getProductosStock(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      return Success(productos);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'PRODUCTOS_STOCK_ERROR',
      );
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }
    return error.toString();
  }
}
