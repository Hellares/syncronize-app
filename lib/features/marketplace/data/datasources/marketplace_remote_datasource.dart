import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/banner_marketplace_model.dart';
import '../models/categoria_marketplace_model.dart';
import '../models/marketplace_home_model.dart';
import '../models/producto_marketplace_model.dart';
import '../models/productos_paginados_model.dart';

@lazySingleton
class MarketplaceRemoteDataSource {
  final DioClient _dioClient;

  MarketplaceRemoteDataSource(this._dioClient);

  /// GET /marketplace/productos
  Future<ProductosPaginadosModel> searchProductos({
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
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (marcaId != null) 'marcaId': marcaId,
      if (precioMin != null) 'precioMin': precioMin,
      if (precioMax != null) 'precioMax': precioMax,
      if (departamento != null) 'departamento': departamento,
      if (orden != null) 'orden': orden,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    final response = await _dioClient.get(
      ApiConstants.marketplaceProductos,
      queryParameters: params,
    );
    return ProductosPaginadosModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /marketplace/categorias
  Future<List<CategoriaMarketplaceModel>> getCategorias() async {
    final response = await _dioClient.get(ApiConstants.marketplaceCategorias);
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((e) => CategoriaMarketplaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/home
  Future<MarketplaceHomeModel> getHome() async {
    final response = await _dioClient.get('/marketplace/home');
    return MarketplaceHomeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /marketplace/banners — slider de empresas con plan vigente (home)
  Future<List<BannerMarketplaceModel>> getBanners() async {
    final response = await _dioClient.get('/marketplace/banners');
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((e) => BannerMarketplaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/usuario/vistos
  Future<List<ProductoMarketplaceModel>> getVistos({int limit = 10}) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceUsuario}/vistos',
      queryParameters: {'limit': '$limit'},
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((e) => ProductoMarketplaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/usuario/recomendados
  Future<List<ProductoMarketplaceModel>> getRecomendados({int limit = 12}) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceUsuario}/recomendados',
      queryParameters: {'limit': '$limit'},
    );
    final data = response.data as Map<String, dynamic>;
    final recomendados = data['recomendados'] as List<dynamic>? ?? const [];
    return recomendados
        .map((e) => ProductoMarketplaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/carrito/contador
  Future<int> getCarritoContador() async {
    final response = await _dioClient.get('/marketplace/carrito/contador');
    return (response.data['totalCantidad'] as int?) ?? 0;
  }

  /// GET /marketplace/productos/:id
  Future<Map<String, dynamic>> getProductoDetalle(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceProductos}/$id',
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /marketplace/empresas/:subdominio
  Future<Map<String, dynamic>> getEmpresaPublica(String subdominio) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceEmpresas}/$subdominio',
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /marketplace/empresas/:subdominio/productos
  Future<Map<String, dynamic>> getProductosEmpresa(
    String subdominio, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceEmpresas}/$subdominio/productos',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /marketplace/empresas/:subdominio/servicios
  Future<Map<String, dynamic>> getServiciosEmpresa(
    String subdominio, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceEmpresas}/$subdominio/servicios',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }
}
