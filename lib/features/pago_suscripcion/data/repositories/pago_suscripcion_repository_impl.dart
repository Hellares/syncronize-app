import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pago_suscripcion.dart';
import '../../domain/repositories/pago_suscripcion_repository.dart';
import '../datasources/pago_suscripcion_remote_datasource.dart';

@LazySingleton(as: PagoSuscripcionRepository)
class PagoSuscripcionRepositoryImpl implements PagoSuscripcionRepository {
  final PagoSuscripcionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PagoSuscripcionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<PagoSuscripcion>> solicitarPago({
    required String planSuscripcionId,
    required String periodo,
    required String metodoPago,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.solicitarPago(
        planSuscripcionId: planSuscripcionId,
        periodo: periodo,
        metodoPago: metodoPago,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PagoSuscripcion');
    }
  }

  @override
  Future<Resource<String>> subirComprobante(String pagoId, File file) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final url = await _remoteDataSource.subirComprobante(pagoId, file);
      return Success(url);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PagoSuscripcion');
    }
  }

  @override
  Future<Resource<List<PagoSuscripcion>>> getMisPagos({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getMisPagos(
        page: page,
        pageSize: pageSize,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PagoSuscripcion');
    }
  }

  @override
  Future<Resource<PagoSuscripcion>> getPagoById(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getPagoById(id);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PagoSuscripcion');
    }
  }
}
