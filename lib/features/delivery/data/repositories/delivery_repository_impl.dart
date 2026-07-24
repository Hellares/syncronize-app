import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/delivery_local.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/delivery_remote_datasource.dart';

@LazySingleton(as: DeliveryRepository)
class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  DeliveryRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<DeliveryLocal>> solicitar(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.solicitar(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<List<DeliveryLocal>>> getDisponibles(
    String empresaId, {
    String? sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.getDisponibles(empresaId, sedeId: sedeId);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<List<DeliveryLocal>>> getMisEntregas(String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getMisEntregas(empresaId);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<DeliveryLocal>> tomar(String id, String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.tomar(id, empresaId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<DeliveryLocal>> marcarEnCamino(
      String id, String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.marcarEnCamino(id, empresaId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<DeliveryLocal>> marcarEntregado(
      String id, String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.marcarEntregado(id, empresaId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<List<DeliveryLocal>>> getExternoDisponibles() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getExternoDisponibles();
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<List<DeliveryLocal>>> getExternoMisEntregas() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getExternoMisEntregas();
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }

  @override
  Future<Resource<DeliveryLocal>> tomarExterno(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.tomarExterno(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Delivery');
    }
  }
}
