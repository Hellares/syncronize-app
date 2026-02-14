import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/precio_nivel.dart';
import '../../domain/repositories/precio_nivel_repository.dart';
import '../datasources/precio_nivel_remote_datasource.dart';
import '../models/precio_nivel_model.dart';

@LazySingleton(as: PrecioNivelRepository)
class PrecioNivelRepositoryImpl implements PrecioNivelRepository {
  final PrecioNivelRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PrecioNivelRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<PrecioNivel>> crearPrecioNivelProducto({
    required String productoId,
    required PrecioNivelDto dto,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final nivel = await _remoteDataSource.crearPrecioNivelProducto(
        productoId: productoId,
        dto: dto,
      );
      return Success(nivel);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<PrecioNivel>> crearPrecioNivelVariante({
    required String varianteId,
    required PrecioNivelDto dto,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final nivel = await _remoteDataSource.crearPrecioNivelVariante(
        varianteId: varianteId,
        dto: dto,
      );
      return Success(nivel);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<List<PrecioNivel>>> getPreciosNivelProducto({
    required String productoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final niveles = await _remoteDataSource.getPreciosNivelProducto(
        productoId: productoId,
      );
      return Success(niveles);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<List<PrecioNivel>>> getPreciosNivelVariante({
    required String varianteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final niveles = await _remoteDataSource.getPreciosNivelVariante(
        varianteId: varianteId,
      );
      return Success(niveles);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<PrecioNivel>> getPrecioNivel({
    required String nivelId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final nivel = await _remoteDataSource.getPrecioNivel(
        nivelId: nivelId,
      );
      return Success(nivel);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<PrecioNivel>> actualizarPrecioNivel({
    required String nivelId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final nivel = await _remoteDataSource.actualizarPrecioNivel(
        nivelId: nivelId,
        data: data,
      );
      return Success(nivel);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<void>> eliminarPrecioNivel({
    required String nivelId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarPrecioNivel(
        nivelId: nivelId,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<CalculoPrecioResult>> calcularPrecioProducto({
    required String productoId,
    required int cantidad,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await _remoteDataSource.calcularPrecioProducto(
        productoId: productoId,
        cantidad: cantidad,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }

  @override
  Future<Resource<CalculoPrecioResult>> calcularPrecioVariante({
    required String varianteId,
    required int cantidad,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await _remoteDataSource.calcularPrecioVariante(
        varianteId: varianteId,
        cantidad: cantidad,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PrecioNivel');
    }
  }
}
