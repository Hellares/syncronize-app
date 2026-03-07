import 'package:injectable/injectable.dart';
import '../../../../core/utils/cursor_page.dart';
import '../../../../core/utils/resource.dart';
import '../entities/precio_historial_sede.dart';
import '../repositories/producto_stock_repository.dart';

@injectable
class GetHistorialPreciosGlobalUseCase {
  final ProductoStockRepository _repository;

  GetHistorialPreciosGlobalUseCase(this._repository);

  Future<Resource<CursorPage<PrecioHistorialSede>>> call({
    required String empresaId,
    String? sedeId,
    String? productoId,
    String? fechaInicio,
    String? fechaFin,
    String? tipoCambio,
    String? search,
    String? cursor,
    int limit = 50,
  }) async {
    return await _repository.getHistorialPreciosGlobal(
      empresaId: empresaId,
      sedeId: sedeId,
      productoId: productoId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipoCambio: tipoCambio,
      search: search,
      cursor: cursor,
      limit: limit,
    );
  }
}

@injectable
class ExportHistorialPreciosUseCase {
  final ProductoStockRepository _repository;

  ExportHistorialPreciosUseCase(this._repository);

  Future<Resource<List<int>>> call({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    String? productoId,
    String? tipoCambio,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _repository.exportHistorialPrecios(
      empresaId: empresaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      sedeId: sedeId,
      productoId: productoId,
      tipoCambio: tipoCambio,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
