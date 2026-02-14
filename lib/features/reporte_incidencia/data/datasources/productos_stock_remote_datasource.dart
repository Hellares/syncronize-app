import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../models/producto_stock_simple_model.dart';

@injectable
class ProductosStockRemoteDatasource {
  final Dio _dio;

  ProductosStockRemoteDatasource(this._dio);

  Future<List<ProductoStockSimpleModel>> getProductosStock({
    required String empresaId,
    required String sedeId,
  }) async {
    final response = await _dio.get(
      '/producto-stock/sede/$sedeId',
      options: Options(
        headers: {
          'X-Tenant-ID': empresaId,
        },
      ),
    );

    if (response.data == null) {
      return [];
    }

    // El backend puede devolver un objeto con data o directamente una lista
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;

    if (data is! List) {
      return [];
    }

    return data
        .map((json) => ProductoStockSimpleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
