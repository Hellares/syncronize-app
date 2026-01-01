import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/catalogo_preview.dart';
import '../../domain/repositories/catalogos_repository.dart';
import '../datasources/catalogos_remote_datasource.dart';

@LazySingleton(as: CatalogosRepository)
class CatalogosRepositoryImpl implements CatalogosRepository {
  final CatalogosRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final ErrorHandlerService errorHandler;

  CatalogosRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.errorHandler,
  });

  @override
  Future<Resource<CatalogoPreview>> getCatalogoPreview(String rubro) async {
    if (!await networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await remoteDataSource.getCatalogoPreview(rubro);
      final catalogoPreview = result.toEntity();
      return Success(catalogoPreview);
    } catch (e) {
      return errorHandler.handleException(
        e,
        context: 'GetCatalogoPreview',
        defaultMessage: 'Error al obtener preview de catálogos',
      );
    }
  }
}
