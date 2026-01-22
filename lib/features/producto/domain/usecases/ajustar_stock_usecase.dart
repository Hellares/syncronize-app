import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_stock.dart';
import '../entities/movimiento_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para ajustar el stock (entrada o salida)
@injectable
class AjustarStockUseCase {
  final ProductoStockRepository _repository;

  AjustarStockUseCase(this._repository);

  Future<Resource<ProductoStock>> call({
    required String stockId,
    required String empresaId,
    required TipoMovimientoStock tipo,
    required int cantidad,
    String? motivo,
    String? observaciones,
    String? tipoDocumento,
    String? numeroDocumento,
  }) async {
    return await _repository.ajustarStock(
      stockId: stockId,
      empresaId: empresaId,
      tipo: tipo,
      cantidad: cantidad,
      motivo: motivo,
      observaciones: observaciones,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
    );
  }
}
