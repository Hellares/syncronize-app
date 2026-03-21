import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/flujo_proyectado.dart';
import '../../domain/repositories/flujo_proyectado_repository.dart';
import '../datasources/flujo_proyectado_remote_datasource.dart';

@LazySingleton(as: FlujoProyectadoRepository)
class FlujoProyectadoRepositoryImpl implements FlujoProyectadoRepository {
  final FlujoProyectadoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  FlujoProyectadoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<PeriodoFlujo>>> getProyeccion({int? meses}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getProyeccion(meses: meses);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'FlujoProyectado');
    }
  }
}
