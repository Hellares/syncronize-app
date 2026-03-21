import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/empresa_banco.dart';
import '../../domain/repositories/empresa_banco_repository.dart';
import '../datasources/empresa_banco_remote_datasource.dart';

@LazySingleton(as: EmpresaBancoRepository)
class EmpresaBancoRepositoryImpl implements EmpresaBancoRepository {
  final EmpresaBancoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  EmpresaBancoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<EmpresaBanco>>> listar() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cuentas = await _remoteDataSource.listar();
      return Success(cuentas.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }

  @override
  Future<Resource<EmpresaBanco>> crear({
    required String nombreBanco,
    required String tipoCuenta,
    required String numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
    double? saldoActual,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cuenta = await _remoteDataSource.crear(
        nombreBanco: nombreBanco,
        tipoCuenta: tipoCuenta,
        numeroCuenta: numeroCuenta,
        cci: cci,
        moneda: moneda,
        titular: titular,
        esPrincipal: esPrincipal,
        saldoActual: saldoActual,
      );
      return Success(cuenta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }

  @override
  Future<Resource<EmpresaBanco>> actualizar({
    required String id,
    String? nombreBanco,
    String? tipoCuenta,
    String? numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cuenta = await _remoteDataSource.actualizar(
        id: id,
        nombreBanco: nombreBanco,
        tipoCuenta: tipoCuenta,
        numeroCuenta: numeroCuenta,
        cci: cci,
        moneda: moneda,
        titular: titular,
        esPrincipal: esPrincipal,
      );
      return Success(cuenta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }

  @override
  Future<Resource<void>> eliminar({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.eliminar(id: id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }

  @override
  Future<Resource<EmpresaBanco>> marcarPrincipal({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cuenta = await _remoteDataSource.marcarPrincipal(id: id);
      return Success(cuenta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }

  @override
  Future<Resource<EmpresaBanco>> actualizarSaldo({
    required String id,
    required double saldo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cuenta = await _remoteDataSource.actualizarSaldo(id: id, saldo: saldo);
      return Success(cuenta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }

  @override
  Future<Resource<ConciliacionBancaria>> getConciliacion({
    required String cuentaId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final conciliacion = await _remoteDataSource.getConciliacion(
        cuentaId: cuentaId,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Success(conciliacion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'EmpresaBanco');
    }
  }
}
