import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/movimiento_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para obtener el historial de movimientos de un stock (kardex)
@injectable
class GetHistorialMovimientosUseCase {
  final ProductoStockRepository _repository;

  GetHistorialMovimientosUseCase(this._repository);

  Future<Resource<KardexData>> call({
    required String stockId,
    int limit = 100,
    String? tipo,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    return await _repository.getHistorialMovimientos(
      stockId: stockId,
      limit: limit,
      tipo: tipo,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }
}
