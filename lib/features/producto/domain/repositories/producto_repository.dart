import '../../../../core/utils/resource.dart';
import '../entities/producto.dart';
import '../entities/producto_filtros.dart';
import '../entities/transferencia_incidencia.dart';

/// Repository interface para operaciones relacionadas con productos
abstract class ProductoRepository {
  /// Crea un nuevo producto
  Future<Resource<Producto>> crearProducto({
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
  });

  /// Obtiene una lista paginada de productos con filtros
  Future<Resource<ProductosPaginados>> getProductos({
    required String empresaId,
    String? sedeId,
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
    double? peso,
    Map<String, dynamic>? dimensiones,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? descuentoMaximo,
    bool? visibleMarketplace,
    bool? destacado,
    int? ordenMarketplace,
    bool? tieneVariantes,
    bool? esCombo,
    String? tipoPrecioCombo,
    List<String>? imagenesIds,
    String? configuracionPrecioId,
  });

  /// Elimina un producto (soft delete)
  Future<Resource<void>> eliminarProducto({
    required String productoId,
    required String empresaId,
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

  // ========================================
  // INCIDENCIAS DE TRANSFERENCIAS
  // ========================================

  /// Recibe una transferencia con manejo detallado de incidencias
  /// Permite reportar productos dañados, faltantes, etc.
  Future<Resource<Map<String, dynamic>>> recibirTransferenciaConIncidencias({
    required String transferenciaId,
    required String empresaId,
    required Map<String, dynamic> request,
  });

  /// Lista incidencias de transferencias con filtros
  Future<Resource<List<TransferenciaIncidencia>>> listarIncidencias({
    required String empresaId,
    bool? resuelto,
    String? tipo,
    String? sedeId,
    String? transferenciaId,
  });

  /// Resuelve una incidencia tomando una acción específica
  Future<Resource<TransferenciaIncidencia>> resolverIncidencia({
    required String incidenciaId,
    required String empresaId,
    required Map<String, dynamic> request,
  });

  /// Asigna atributos a un producto base
  Future<Resource<void>> setProductoAtributos({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  });
}
