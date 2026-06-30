import '../../../../core/utils/resource.dart';
import '../entities/categoria_marketplace.dart';
import '../entities/marketplace_home.dart';
import '../entities/producto_marketplace.dart';
import '../entities/productos_paginados.dart';

/// Repository del catálogo público del marketplace (productos, categorías y home).
abstract class MarketplaceRepository {
  /// Búsqueda paginada de productos con filtros opcionales.
  Future<Resource<ProductosPaginados>> searchProductos({
    String? search,
    String? categoriaId,
    String? marcaId,
    double? precioMin,
    double? precioMax,
    String? departamento,
    String? orden,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
  });

  /// Categorías maestras para los chips de filtro.
  Future<Resource<List<CategoriaMarketplace>>> getCategorias();

  /// Secciones del home (ofertas, más vendido, más visto). Público, sin auth.
  Future<Resource<MarketplaceHome>> getHome();

  /// Productos vistos recientemente por el usuario autenticado.
  Future<Resource<List<ProductoMarketplace>>> getVistos({int limit = 10});

  /// Productos recomendados según el historial de navegación del usuario.
  Future<Resource<List<ProductoMarketplace>>> getRecomendados({int limit = 12});

  /// Cantidad total de items en el carrito del usuario autenticado.
  Future<Resource<int>> getCarritoContador();
}
