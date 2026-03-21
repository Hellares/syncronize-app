import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pedido_empresa.dart';
import '../../domain/repositories/pedido_empresa_repository.dart';
import '../datasources/pedido_empresa_remote_datasource.dart';

@LazySingleton(as: PedidoEmpresaRepository)
class PedidoEmpresaRepositoryImpl implements PedidoEmpresaRepository {
  final PedidoEmpresaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PedidoEmpresaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<PedidoMarketplaceEmpresa>>> listarPedidos({
    String? estado,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.listarPedidos(
        estado: estado,
        search: search,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PedidosEmpresa');
    }
  }

  @override
  Future<Resource<PedidoMarketplaceEmpresa>> detallePedido(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.detallePedido(id);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PedidosEmpresa');
    }
  }

  @override
  Future<Resource<void>> validarPago(
    String id, {
    required String accion,
    String? motivoRechazo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.validarPago(id, accion: accion, motivoRechazo: motivoRechazo);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PedidosEmpresa');
    }
  }

  @override
  Future<Resource<void>> cambiarEstado(
    String id, {
    required String estado,
    String? codigoSeguimiento,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.cambiarEstado(id, estado: estado, codigoSeguimiento: codigoSeguimiento);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PedidosEmpresa');
    }
  }

  @override
  Future<Resource<ResumenPedidos>> getResumen() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.getResumen();
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PedidosEmpresa');
    }
  }
}
