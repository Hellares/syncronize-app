import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pedido_marketplace.dart';
import '../../domain/repositories/mis_pedidos_repository.dart';
import '../datasources/mis_pedidos_remote_datasource.dart';

@LazySingleton(as: MisPedidosRepository)
class MisPedidosRepositoryImpl implements MisPedidosRepository {
  final MisPedidosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  MisPedidosRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<PedidoMarketplace>>> getMisPedidos({
    EstadoPedidoMarketplace? estado,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.getMisPedidos(
        estado: estado?.apiValue,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPedidos');
    }
  }

  @override
  Future<Resource<PedidoMarketplace>> getMiPedidoDetalle(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getMiPedidoDetalle(id);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPedidos');
    }
  }

  @override
  Future<Resource<String>> subirComprobante(String pedidoId, File file) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final url = await _remoteDataSource.subirComprobante(pedidoId, file);
      return Success(url);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPedidos');
    }
  }

  @override
  Future<Resource<void>> cancelarPedido(String pedidoId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.cancelarPedido(pedidoId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPedidos');
    }
  }

  @override
  Future<Resource<void>> confirmarRecepcion(String pedidoId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.confirmarRecepcion(pedidoId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MisPedidos');
    }
  }
}
