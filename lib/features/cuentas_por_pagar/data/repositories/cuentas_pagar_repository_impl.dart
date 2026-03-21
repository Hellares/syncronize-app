import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../../domain/repositories/cuentas_pagar_repository.dart';
import '../datasources/cuentas_pagar_remote_datasource.dart';

@LazySingleton(as: CuentasPagarRepository)
class CuentasPagarRepositoryImpl implements CuentasPagarRepository {
  final CuentasPagarRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CuentasPagarRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<CuentaPorPagar>>> listar({String? estado}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.listar(estado: estado);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar');
    }
  }

  @override
  Future<Resource<ResumenCuentasPagar>> getResumen() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getResumen();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar');
    }
  }
}
