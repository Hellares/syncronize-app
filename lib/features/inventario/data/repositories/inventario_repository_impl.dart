import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/inventario.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../datasources/inventario_remote_datasource.dart';

@LazySingleton(as: InventarioRepository)
class InventarioRepositoryImpl implements InventarioRepository {
  final InventarioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  InventarioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<Inventario>>> listar({
    String? sedeId,
    String? estado,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final inventarios = await _remoteDataSource.listar(
        sedeId: sedeId,
        estado: estado,
      );
      return Success(inventarios.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<Inventario>> getDetalle({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final inventario = await _remoteDataSource.getDetalle(id);
      return Success(inventario.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<Inventario>> crear({
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final inventario = await _remoteDataSource.crear(data);
      return Success(inventario.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<void>> iniciar({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.iniciar(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<void>> registrarConteo({
    required String id,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.registrarConteo(
        id: id,
        itemId: itemId,
        data: data,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<void>> finalizarConteo({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.finalizarConteo(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<void>> aprobar({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.aprobar(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<void>> aplicarAjustes({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.aplicarAjustes(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }

  @override
  Future<Resource<void>> cancelar({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.cancelar(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Inventario');
    }
  }
}
