import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/categoria_gasto.dart';
import '../../domain/repositories/categoria_gasto_repository.dart';
import '../datasources/categoria_gasto_remote_datasource.dart';

@LazySingleton(as: CategoriaGastoRepository)
class CategoriaGastoRepositoryImpl implements CategoriaGastoRepository {
  final CategoriaGastoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CategoriaGastoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<CategoriaGasto>>> listar({String? tipo}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final models = await _remoteDataSource.listar(tipo: tipo);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CategoriaGasto');
    }
  }

  @override
  Future<Resource<CategoriaGasto>> crear({
    required String nombre,
    required String tipo,
    String? color,
    String? icono,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.crear(
        nombre: nombre,
        tipo: tipo,
        color: color,
        icono: icono,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CategoriaGasto');
    }
  }

  @override
  Future<Resource<CategoriaGasto>> actualizar({
    required String id,
    String? nombre,
    String? color,
    String? icono,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.actualizar(
        id: id,
        nombre: nombre,
        color: color,
        icono: icono,
      );
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CategoriaGasto');
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
      return _errorHandler.handleException(e, context: 'CategoriaGasto');
    }
  }
}
