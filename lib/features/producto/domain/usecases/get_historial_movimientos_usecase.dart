import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/movimiento_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener el historial de movimientos de un stock
@injectable
class GetHistorialMovimientosUseCase {
  final ProductoStockRepository _repository;

  GetHistorialMovimientosUseCase(this._repository);

  Future<Resource<List<MovimientoStock>>> call({
    required String stockId,
    int limit = 50,
  }) async {
    return await _repository.getHistorialMovimientos(
      stockId: stockId,
      limit: limit,
    );
  }
}
