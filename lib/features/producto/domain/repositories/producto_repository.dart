import '../../../../core/utils/resource.dart';
import '../entities/producto.dart';

import '../entities/producto_filtros.dart';

/// Repository interface para operaciones relacionadas con productos
abstract class ProductoRepository {
  /// Crea un nuevo producto
  Future<Resource<Producto>> crearProducto({
    required String empresaId,
    String? sedeId,
    String? unidadMedidaId,
    String? empresaCategoriaId,
    String? empresaMarcaId,
    String? sku,
    String? codigoBarras,
    required String nombre,
    String? descripcion,
    required double precio,
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
    bool? enOferta,
    bool? tieneVariantes,
    bool? esCombo,
    String? tipoPrecioCombo,
    double? precioOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
    List<String>? imagenesIds,
    String? configuracionPrecioId,
  });

  /// Obtiene una lista paginada de productos con filtros
  Future<Resource<ProductosPaginados>> getProductos({
    required String empresaId,
    required ProductoFiltros filtros,
  });

  /// Obtiene un producto por ID
  Future<Resource<Producto>> getProducto({
    required String productoId,
    required String empresaId,
  });

  /// Actualiza un producto existente
  Future<Resource<Producto>> actualizarProducto({
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
  });

  /// Elimina un producto (soft delete)
  Future<Resource<void>> eliminarProducto({
    required String productoId,
    required String empresaId,
  });

  /// Actualiza el stock de un producto
  Future<Resource<Producto>> actualizarStock({
    required String productoId,
    required String empresaId,
    required int cantidad,
    required String operacion, // 'agregar' o 'quitar'
  });

  /// Obtiene el stock total de un producto
  /// Si tiene variantes, retorna la suma de stock de todas las variantes activas
  /// Si no tiene variantes, retorna el stock del producto base
  Future<Resource<int>> getStockTotal({
    required String productoId,
    required String empresaId,
  });

  /// Obtiene productos disponibles para usar como componentes de combo
  /// Excluye combos y productos sin stock
  Future<Resource<List<Producto>>> getProductosDisponiblesParaCombo({
    required String empresaId,
  });

  /// Ajuste masivo de precios
  /// Permite incrementar o decrementar precios por porcentaje de forma masiva
  Future<Resource<Map<String, dynamic>>> ajusteMasivoPrecios({
    required String empresaId,
    required Map<String, dynamic> dto,
  });
}
