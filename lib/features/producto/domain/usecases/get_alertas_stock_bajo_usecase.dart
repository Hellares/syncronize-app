import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener alertas de productos con stock bajo el mínimo
@injectable
class GetAlertasStockBajoUseCase {
  final ProductoStockRepository _repository;

  GetAlertasStockBajoUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String empresaId,
    String? sedeId,
  }) async {
    return await _repository.getAlertasStockBajo(
      empresaId: empresaId,
      sedeId: sedeId,
    );
  }
}
