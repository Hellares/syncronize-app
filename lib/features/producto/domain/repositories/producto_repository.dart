import '../../../../core/utils/resource.dart';
import '../entities/bulk_upload_result.dart';
import '../entities/producto.dart';
import '../entities/producto_filtros.dart';
import '../entities/regla_compatibilidad.dart';
import '../entities/resultado_compatibilidad.dart';
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
    String? tipoAfectacionIgv,
    bool? aplicaIcbper,
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
    String? tipoAfectacionIgv,
    bool? aplicaIcbper,
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

  // ========================================
  // COMPATIBILIDAD
  // ========================================

  /// Obtiene las reglas de compatibilidad de la empresa
  Future<Resource<List<ReglaCompatibilidad>>> getReglasCompatibilidad({
    String? categoriaId,
  });

  /// Crea una regla de compatibilidad
  Future<Resource<ReglaCompatibilidad>> createReglaCompatibilidad(
      Map<String, dynamic> data);

  /// Actualiza una regla de compatibilidad
  Future<Resource<ReglaCompatibilidad>> updateReglaCompatibilidad(
      String id, Map<String, dynamic> data);

  /// Elimina una regla de compatibilidad (soft delete)
  Future<Resource<void>> deleteReglaCompatibilidad(String id);

  /// Valida la compatibilidad entre productos
  Future<Resource<ResultadoCompatibilidad>> validarCompatibilidad(
      List<Map<String, String?>> productos);

  // ========================================
  // CARGA MASIVA DE PRODUCTOS
  // ========================================

  /// Descarga la plantilla Excel para carga masiva de productos
  Future<Resource<List<int>>> downloadBulkUploadTemplate();

  /// Sube archivo Excel para carga masiva de productos
  Future<Resource<BulkUploadResult>> bulkUploadProductos({
    required String filePath,
    required String fileName,
    List<String>? sedesIds,
  });
}
