import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

/// Use case para actualizar un producto existente
@injectable
class ActualizarProductoUseCase {
  final ProductoRepository _repository;

  ActualizarProductoUseCase(this._repository);

  Future<Resource<Producto>> call({
    required String productoId,
    required String empresaId,
    String? sedeId,
    String? unidadMedidaId,
    String? empresaCategoriaId,
    String? empresaMarcaId,
    String? sku,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    double? precio,
    double? precioCosto,
    int? stock,
    int? stockMinimo,
    double? peso,
    Map<String, dynamic>? dimensiones,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? descuentoMaximo,
    bool? visibleMarketplace,
    bool? destacado,
    int? ordenMarketplace,
    bool? enOferta,
    bool? tieneVariantes,
    bool? esCombo,
    String? tipoPrecioCombo,
    double? precioOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
    List<String>? imagenesIds,
    String? configuracionPrecioId,
  }) async {
    return await _repository.actualizarProducto(
      productoId: productoId,
      empresaId: empresaId,
      sedeId: sedeId,
      unidadMedidaId: unidadMedidaId,
      empresaCategoriaId: empresaCategoriaId,
      empresaMarcaId: empresaMarcaId,
      sku: sku,
      codigoBarras: codigoBarras,
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      precioCosto: precioCosto,
      stock: stock,
      stockMinimo: stockMinimo,
      peso: peso,
      dimensiones: dimensiones,
      videoUrl: videoUrl,
      impuestoPorcentaje: impuestoPorcentaje,
      descuentoMaximo: descuentoMaximo,
      visibleMarketplace: visibleMarketplace,
      destacado: destacado,
      ordenMarketplace: ordenMarketplace,
      enOferta: enOferta,
      tieneVariantes: tieneVariantes,
      esCombo: esCombo,
      tipoPrecioCombo: tipoPrecioCombo,
      precioOferta: precioOferta,
      fechaInicioOferta: fechaInicioOferta,
      fechaFinOferta: fechaFinOferta,
      imagenesIds: imagenesIds,
      configuracionPrecioId: configuracionPrecioId,
    );
  }
}
