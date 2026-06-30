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
  Future<Resource<List<CuentaPorPagar>>> listar({String? estado, String? proveedorId, String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.listar(estado: estado, proveedorId: proveedorId, sedeId: sedeId);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar');
    }
  }

  @override
  Future<Resource<List<DeudaProveedor>>> getPorProveedor() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getPorProveedor();
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar.porProveedor');
    }
  }

  @override
  Future<Resource<CuentaPagarDetalle>> getDetalle(String compraId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getDetalle(compraId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar.detalle');
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

  @override
  Future<Resource<void>> registrarPago(
    String compraId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? bancoDestino,
    String? cuentaDestino,
    String? comprobanteUrl,
    String? fuente,
    String? bancoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.registrarPago(
        compraId,
        metodoPago: metodoPago,
        monto: monto,
        referencia: referencia,
        bancoDestino: bancoDestino,
        cuentaDestino: cuentaDestino,
        comprobanteUrl: comprobanteUrl,
        fuente: fuente,
        bancoId: bancoId,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar.registrarPago');
    }
  }

  @override
  Future<Resource<String>> subirComprobante(String filePath) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final url = await _remoteDataSource.subirComprobante(filePath);
      return Success(url);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar.subirComprobante');
    }
  }

  @override
  Future<Resource<String>> adjuntarComprobantePago(String pagoId, String filePath) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final url = await _remoteDataSource.adjuntarComprobantePago(pagoId, filePath);
      return Success(url);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CuentasPagar.adjuntarComprobante');
    }
  }
}
