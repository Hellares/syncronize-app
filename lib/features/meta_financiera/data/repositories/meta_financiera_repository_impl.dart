import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/meta_financiera.dart';
import '../../domain/repositories/meta_financiera_repository.dart';
import '../datasources/meta_financiera_remote_datasource.dart';

@LazySingleton(as: MetaFinancieraRepository)
class MetaFinancieraRepositoryImpl implements MetaFinancieraRepository {
  final MetaFinancieraRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  MetaFinancieraRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<MetaFinanciera>>> getResumen() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getResumen();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MetaFinanciera');
    }
  }

  @override
  Future<Resource<MetaFinanciera>> crear({
    required String tipo,
    required String nombre,
    required double montoMeta,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.crear(
        tipo: tipo,
        nombre: nombre,
        montoMeta: montoMeta,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MetaFinanciera');
    }
  }
}
