import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para crear stock inicial en una sede
@injectable
class CrearStockInicialUseCase {
  final ProductoStockRepository _repository;

  CrearStockInicialUseCase(this._repository);

  Future<Resource<ProductoStock>> call({
    required String empresaId,
    required String sedeId,
    String? productoId,
    String? varianteId,
    required int stockActual,
    int? stockMinimo,
    int? stockMaximo,
    String? ubicacion,
  }) async {
    return await _repository.crearStock(
      empresaId: empresaId,
      sedeId: sedeId,
      productoId: productoId,
      varianteId: varianteId,
      stockActual: stockActual,
      stockMinimo: stockMinimo,
      stockMaximo: stockMaximo,
      ubicacion: ubicacion,
    );
  }
}
