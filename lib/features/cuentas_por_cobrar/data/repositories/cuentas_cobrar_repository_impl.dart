import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cuenta_por_cobrar.dart';
import '../../domain/entities/estado_cuenta_cliente.dart';
import '../../domain/repositories/cuentas_cobrar_repository.dart';
import '../datasources/cuentas_cobrar_remote_datasource.dart';

@LazySingleton(as: CuentasCobrarRepository)
class CuentasCobrarRepositoryImpl implements CuentasCobrarRepository {
  final CuentasCobrarRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CuentasCobrarRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<CuentaPorCobrar>>> listar({String? estado}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.listar(estado: estado);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasCobrar');
    }
  }

  @override
  Future<Resource<ResumenCuentasCobrar>> getResumen() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getResumen();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasCobrar');
    }
  }

  @override
  Future<Resource<void>> registrarAbono(
    String ventaId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? fuente,
    String? bancoId,
    String? banco,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.registrarAbono(
        ventaId,
        metodoPago: metodoPago,
        monto: monto,
        referencia: referencia,
        fuente: fuente,
        bancoId: bancoId,
        banco: banco,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasCobrar.registrarAbono');
    }
  }

  @override
  Future<Resource<void>> anularAbono(String pagoId, {String? motivo}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.anularAbono(pagoId, motivo: motivo);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasCobrar.anularAbono');
    }
  }

  @override
  Future<Resource<EstadoCuentaCliente>> getEstadoCuentaCliente({
    String? clienteId,
    String? clienteEmpresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getEstadoCuentaCliente(
        clienteId: clienteId,
        clienteEmpresaId: clienteEmpresaId,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasCobrar.estadoCuenta');
    }
  }
}
