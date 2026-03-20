import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/carrito.dart';
import '../../domain/repositories/carrito_repository.dart';
import '../datasources/carrito_remote_datasource.dart';

@LazySingleton(as: CarritoRepository)
class CarritoRepositoryImpl implements CarritoRepository {
  final CarritoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CarritoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Carrito>> getCarrito() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getCarrito();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Carrito');
    }
  }

  @override
  Future<Resource<Carrito>> agregarItem({
    required String productoId,
    String? varianteId,
    int cantidad = 1,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.agregarItem(
        productoId: productoId,
        varianteId: varianteId,
        cantidad: cantidad,
      );
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Carrito');
    }
  }

  @override
  Future<Resource<Carrito>> actualizarCantidad({
    required String itemId,
    required int cantidad,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.actualizarCantidad(
        itemId: itemId,
        cantidad: cantidad,
      );
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Carrito');
    }
  }

  @override
  Future<Resource<Carrito>> eliminarItem({required String itemId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.eliminarItem(itemId: itemId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Carrito');
    }
  }

  @override
  Future<Resource<Carrito>> vaciarCarrito() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.vaciarCarrito();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Carrito');
    }
  }

  @override
  Future<Resource<CarritoContador>> getContador() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getContador();
      return Success(CarritoContador(
        totalItems: result.totalItems,
        totalCantidad: result.totalCantidad,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Carrito');
    }
  }
}
