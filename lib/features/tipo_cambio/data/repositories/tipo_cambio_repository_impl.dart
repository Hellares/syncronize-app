import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/tipo_cambio.dart';
import '../../domain/repositories/tipo_cambio_repository.dart';
import '../datasources/tipo_cambio_remote_datasource.dart';

@LazySingleton(as: TipoCambioRepository)
class TipoCambioRepositoryImpl implements TipoCambioRepository {
  final TipoCambioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  TipoCambioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<TipoCambio>> getHoy() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getHoy();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'TipoCambio');
    }
  }

  @override
  Future<Resource<List<TipoCambio>>> getHistorial({
    String? fechaDesde,
    String? fechaHasta,
    int? limit,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getHistorial(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        limit: limit,
      );
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'TipoCambio');
    }
  }

  @override
  Future<Resource<TipoCambio>> registrarManual({
    required double compra,
    required double venta,
    required String fecha,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.registrarManual(
        compra: compra,
        venta: venta,
        fecha: fecha,
      );
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'TipoCambio');
    }
  }

  @override
  Future<Resource<ConfiguracionMoneda>> getConfiguracion() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getConfiguracion();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'TipoCambio');
    }
  }
}
