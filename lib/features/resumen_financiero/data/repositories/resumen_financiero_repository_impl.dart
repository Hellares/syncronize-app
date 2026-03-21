import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/resumen_financiero.dart';
import '../../domain/repositories/resumen_financiero_repository.dart';
import '../datasources/resumen_financiero_remote_datasource.dart';

@LazySingleton(as: ResumenFinancieroRepository)
class ResumenFinancieroRepositoryImpl implements ResumenFinancieroRepository {
  final ResumenFinancieroRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ResumenFinancieroRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ResumenFinanciero>> getResumen({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getResumen(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ResumenFinanciero');
    }
  }

  @override
  Future<Resource<GraficoDiario>> getGraficoDiario({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getGraficoDiario(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ResumenFinanciero');
    }
  }

  @override
  Future<Resource<List<int>>> exportLibroContable({
    required int mes,
    required int anio,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.exportLibroContable(
        mes: mes,
        anio: anio,
        onReceiveProgress: onReceiveProgress,
      );
      return Success(data);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ExportLibroContable');
    }
  }

  @override
  Future<Resource<List<int>>> exportCuentasCobrar({
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.exportCuentasCobrar(onReceiveProgress: onReceiveProgress);
      return Success(data);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ExportCuentasCobrar');
    }
  }

  @override
  Future<Resource<List<int>>> exportCuentasPagar({
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.exportCuentasPagar(onReceiveProgress: onReceiveProgress);
      return Success(data);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ExportCuentasPagar');
    }
  }
}
