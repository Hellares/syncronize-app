import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/libro_contable.dart';
import '../../domain/repositories/libro_contable_repository.dart';
import '../datasources/libro_contable_remote_datasource.dart';

@LazySingleton(as: LibroContableRepository)
class LibroContableRepositoryImpl implements LibroContableRepository {
  final LibroContableRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  LibroContableRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<LibroContable>> getLibro({
    required int mes,
    required int anio,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getLibro(mes: mes, anio: anio);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'LibroContable');
    }
  }
}
