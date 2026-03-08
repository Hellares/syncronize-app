import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/componente.dart';
import '../../domain/repositories/componente_repository.dart';
import '../datasources/componente_remote_datasource.dart';
import '../models/componente_model.dart';

@LazySingleton(as: ComponenteRepository)
class ComponenteRepositoryImpl implements ComponenteRepository {
  final ComponenteRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ComponenteRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<TipoComponente>>> getTipos() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getTipos();
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'TipoComponente');
    }
  }

  @override
  Future<Resource<TipoComponente>> crearTipo({
    required String nombre,
    required String categoria,
    String? descripcion,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        'categoria': categoria,
        if (descripcion != null) 'descripcion': descripcion,
      };
      final result = await _remoteDataSource.crearTipo(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'TipoComponente');
    }
  }

  @override
  Future<Resource<List<Componente>>> getComponentes({
    String? tipoComponenteId,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final response = await _remoteDataSource.getComponentes(
        tipoComponenteId: tipoComponenteId,
        search: search,
        limit: 50,
      );
      final items = (response['data'] as List)
          .map((e) => ComponenteModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Componente');
    }
  }

  @override
  Future<Resource<Componente>> crearComponente({
    required String tipoComponenteId,
    String? marca,
    String? modelo,
    String? numeroSerie,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'tipoComponenteId': tipoComponenteId,
        if (marca != null) 'marca': marca,
        if (modelo != null) 'modelo': modelo,
        if (numeroSerie != null) 'numeroSerie': numeroSerie,
      };
      final result = await _remoteDataSource.crearComponente(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Componente');
    }
  }

  @override
  Future<Resource<Componente>> findOrCreateComponente({
    required String tipoComponenteId,
    String? marca,
    String? modelo,
    String? numeroSerie,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'tipoComponenteId': tipoComponenteId,
        if (marca != null) 'marca': marca,
        if (modelo != null) 'modelo': modelo,
        if (numeroSerie != null) 'numeroSerie': numeroSerie,
      };
      final result = await _remoteDataSource.findOrCreateComponente(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Componente');
    }
  }

  @override
  Future<Resource<List<String>>> getMarcas({
    required String tipoComponenteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getMarcas(
        tipoComponenteId: tipoComponenteId,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Componente');
    }
  }

  @override
  Future<Resource<List<String>>> getModelos({
    required String tipoComponenteId,
    required String marca,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getModelos(
        tipoComponenteId: tipoComponenteId,
        marca: marca,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Componente');
    }
  }
}
