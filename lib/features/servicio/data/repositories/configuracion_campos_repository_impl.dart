import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_campo.dart';
import '../../domain/repositories/configuracion_campos_repository.dart';
import '../datasources/configuracion_campos_remote_datasource.dart';

@LazySingleton(as: ConfiguracionCamposRepository)
class ConfiguracionCamposRepositoryImpl implements ConfiguracionCamposRepository {
  final ConfiguracionCamposRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ConfiguracionCamposRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<ConfiguracionCampo>>> getAll({
    String? categoria,
    bool? activo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getAll(
        categoria: categoria,
        activo: activo,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionCampos');
    }
  }

  @override
  Future<Resource<ConfiguracionCampo>> getOne(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getOne(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionCampos');
    }
  }

  @override
  Future<Resource<ConfiguracionCampo>> create({
    required String nombre,
    required String tipoCampo,
    String? categoria,
    String? descripcion,
    String? placeholder,
    bool? esRequerido,
    String? defaultValue,
    dynamic opciones,
    bool? permiteOtro,
    int? orden,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        'tipoCampo': tipoCampo,
        if (categoria != null) 'categoria': categoria,
        if (descripcion != null) 'descripcion': descripcion,
        if (placeholder != null) 'placeholder': placeholder,
        if (esRequerido != null) 'esRequerido': esRequerido,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (opciones != null) 'opciones': opciones,
        if (permiteOtro != null) 'permiteOtro': permiteOtro,
        if (orden != null) 'orden': orden,
      };
      final result = await _remoteDataSource.create(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionCampos');
    }
  }

  @override
  Future<Resource<ConfiguracionCampo>> update({
    required String id,
    String? nombre,
    String? tipoCampo,
    String? categoria,
    String? descripcion,
    String? placeholder,
    bool? esRequerido,
    String? defaultValue,
    dynamic opciones,
    bool? permiteOtro,
    int? orden,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        if (nombre != null) 'nombre': nombre,
        if (tipoCampo != null) 'tipoCampo': tipoCampo,
        if (categoria != null) 'categoria': categoria,
        if (descripcion != null) 'descripcion': descripcion,
        if (placeholder != null) 'placeholder': placeholder,
        if (esRequerido != null) 'esRequerido': esRequerido,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (opciones != null) 'opciones': opciones,
        if (permiteOtro != null) 'permiteOtro': permiteOtro,
        if (orden != null) 'orden': orden,
      };
      final result = await _remoteDataSource.update(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionCampos');
    }
  }

  @override
  Future<Resource<void>> delete(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.delete(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionCampos');
    }
  }

  @override
  Future<Resource<List<ConfiguracionCampo>>> reorder(List<String> orderedIds) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.reorder(orderedIds);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionCampos');
    }
  }
}
