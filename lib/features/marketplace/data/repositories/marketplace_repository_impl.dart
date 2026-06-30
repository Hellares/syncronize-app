import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/categoria_marketplace.dart';
import '../../domain/entities/marketplace_home.dart';
import '../../domain/entities/producto_marketplace.dart';
import '../../domain/entities/productos_paginados.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_datasource.dart';

@LazySingleton(as: MarketplaceRepository)
class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  MarketplaceRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
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
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.searchProductos(
        search: search,
        categoriaId: categoriaId,
        marcaId: marcaId,
        precioMin: precioMin,
        precioMax: precioMax,
        departamento: departamento,
        orden: orden,
        lat: lat,
        lng: lng,
        page: page,
        limit: limit,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Marketplace');
    }
  }

  @override
  Future<Resource<List<CategoriaMarketplace>>> getCategorias() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getCategorias();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Marketplace');
    }
  }

  @override
  Future<Resource<MarketplaceHome>> getHome() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getHome();
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Marketplace');
    }
  }

  @override
  Future<Resource<List<ProductoMarketplace>>> getVistos({int limit = 10}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getVistos(limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Marketplace');
    }
  }

  @override
  Future<Resource<List<ProductoMarketplace>>> getRecomendados({
    int limit = 12,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getRecomendados(limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Marketplace');
    }
  }

  @override
  Future<Resource<int>> getCarritoContador() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final total = await _remoteDataSource.getCarritoContador();
      return Success(total);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Marketplace');
    }
  }
}
