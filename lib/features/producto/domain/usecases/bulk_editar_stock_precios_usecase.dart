import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/bulk_editar_stock_precios.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para la edición masiva de stock y precios de una sede.
/// El backend aplica todo en una transacción, generando kardex por
/// cada ajuste de stock e historial por cada cambio de precio.
@injectable
class BulkEditarStockPreciosUseCase {
  final ProductoStockRepository _repository;

  BulkEditarStockPreciosUseCase(this._repository);

  Future<Resource<BulkEditarResumen>> call({
    required String sedeId,
    required String empresaId,
    required List<BulkEditarItem> items,
    String? motivo,
  }) async {
    final conCambios = items.where((i) => i.tieneCambios).toList();
    if (conCambios.isEmpty) {
      return Error('No hay cambios que aplicar', errorCode: 'SIN_CAMBIOS');
    }

    return await _repository.bulkEditarStockPrecios(
      sedeId: sedeId,
      empresaId: empresaId,
      items: conCambios,
      motivo: motivo,
    );
  }
}
