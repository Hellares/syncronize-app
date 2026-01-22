import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener el stock de un producto en todas las sedes
@injectable
class GetStockTodasSedesUseCase {
  final ProductoStockRepository _repository;

  GetStockTodasSedesUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String productoId,
    required String empresaId,
    String? varianteId,
  }) async {
    return await _repository.getStockTodasSedes(
      productoId: productoId,
      empresaId: empresaId,
      varianteId: varianteId,
    );
  }
}
