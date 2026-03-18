import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

@lazySingleton
class MarketplaceRemoteDataSource {
  final DioClient _dioClient;

  MarketplaceRemoteDataSource(this._dioClient);

  /// GET /marketplace/productos
  Future<Map<String, dynamic>> searchProductos({
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
    return response.data as Map<String, dynamic>;
  }

  /// GET /marketplace/productos/:id
  Future<Map<String, dynamic>> getProductoDetalle(String id) async {
    final response = await _dioClient.get(
      '${ApiConstants.marketplaceProductos}/$id',
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /marketplace/categorias
  Future<List<dynamic>> getCategorias() async {
    final response = await _dioClient.get(ApiConstants.marketplaceCategorias);
    return response.data as List<dynamic>;
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
