import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/venta.dart';
import '../../domain/repositories/venta_repository.dart';
import '../datasources/venta_remote_datasource.dart';

@LazySingleton(as: VentaRepository)
class VentaRepositoryImpl implements VentaRepository {
  final VentaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  VentaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Venta>> crearVenta({
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.crearVenta(data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> crearVentaDesdeCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.crearVentaDesdeCotizacion(
        cotizacionId,
        data,
      );
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<List<Venta>>> getVentas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final ventas = await _remoteDataSource.getVentas(
        sedeId: sedeId,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        clienteId: clienteId,
        search: search,
      );
      return Success(ventas.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> getVenta({required String ventaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.getVenta(ventaId);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> actualizarVenta({
    required String ventaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.actualizarVenta(ventaId, data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> confirmarVenta({required String ventaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.confirmarVenta(ventaId);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> procesarPago({
    required String ventaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.procesarPago(ventaId, data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> anularVenta({required String ventaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.anularVenta(ventaId);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> getResumen({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getResumen(sedeId: sedeId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }
}
