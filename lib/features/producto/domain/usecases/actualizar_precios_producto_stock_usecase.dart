import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto_stock.dart';
import '../repositories/producto_stock_repository.dart';

/// Use case para actualizar los precios de un ProductoStock
@injectable
class ActualizarPreciosProductoStockUseCase {
  final ProductoStockRepository _repository;

  ActualizarPreciosProductoStockUseCase(this._repository);

  Future<Resource<ProductoStock>> call({
    required String productoStockId,
    required String empresaId,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    required bool enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
  }) async {
    return await _repository.actualizarPrecios(
      productoStockId: productoStockId,
      empresaId: empresaId,
      precio: precio,
      precioCosto: precioCosto,
      precioOferta: precioOferta,
      enOferta: enOferta,
      fechaInicioOferta: fechaInicioOferta,
      fechaFinOferta: fechaFinOferta,
    );
  }
}
