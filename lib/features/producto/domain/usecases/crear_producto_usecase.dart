import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

/// Use case para crear un nuevo producto
@injectable
class CrearProductoUseCase {
  final ProductoRepository _repository;

  CrearProductoUseCase(this._repository);

  Future<Resource<Producto>> call({
    required String empresaId,
    List<String>? sedesIds,
    String? unidadMedidaId,
    String? empresaCategoriaId,
    String? empresaMarcaId,
    String? sku,
    String? codigoBarras,
    required String nombre,
    String? descripcion,
    double? peso,
    Map<String, dynamic>? dimensiones,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? descuentoMaximo,
    bool? visibleMarketplace,
    bool? destacado,
    bool? tieneVariantes,
    bool? esCombo,
    String? tipoPrecioCombo,
    List<String>? imagenesIds,
    String? configuracionPrecioId,
  }) async {
    return await _repository.crearProducto(
      empresaId: empresaId,
      sedesIds: sedesIds,
      unidadMedidaId: unidadMedidaId,
      empresaCategoriaId: empresaCategoriaId,
      empresaMarcaId: empresaMarcaId,
      sku: sku,
      codigoBarras: codigoBarras,
      nombre: nombre,
      descripcion: descripcion,
      peso: peso,
      dimensiones: dimensiones,
      videoUrl: videoUrl,
      impuestoPorcentaje: impuestoPorcentaje,
      descuentoMaximo: descuentoMaximo,
      visibleMarketplace: visibleMarketplace,
      destacado: destacado,
      tieneVariantes: tieneVariantes,
      esCombo: esCombo,
      tipoPrecioCombo: tipoPrecioCombo,
      imagenesIds: imagenesIds,
      configuracionPrecioId: configuracionPrecioId,
    );
  }
}
