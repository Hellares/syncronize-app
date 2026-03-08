import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/estadisticas_servicio.dart';
import '../../domain/repositories/estadisticas_servicio_repository.dart';
import '../datasources/estadisticas_servicio_remote_datasource.dart';

@LazySingleton(as: EstadisticasServicioRepository)
class EstadisticasServicioRepositoryImpl
    implements EstadisticasServicioRepository {
  final EstadisticasServicioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  EstadisticasServicioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<EstadisticasServicio>> getEstadisticas({
    required String empresaId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('Sin conexión a internet', errorCode: 'NETWORK_ERROR');
    }

    try {
      final result = await _remoteDataSource.getEstadisticas(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e);
    }
  }
}
