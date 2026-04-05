import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/vinculacion.dart';
import '../../domain/repositories/vinculacion_repository.dart';
import '../datasources/vinculacion_remote_datasource.dart';
import '../models/vinculacion_model.dart';

@LazySingleton(as: VinculacionRepository)
class VinculacionRepositoryImpl implements VinculacionRepository {
  final VinculacionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  VinculacionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<EmpresaVinculable?>> checkRuc({
    required String ruc,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.checkRuc(ruc);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<VinculacionEmpresa>> crear({
    String? clienteEmpresaId,
    String? ruc,
    String? mensaje,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        if (clienteEmpresaId != null) 'clienteEmpresaId': clienteEmpresaId,
        if (ruc != null) 'ruc': ruc,
        if (mensaje != null) 'mensaje': mensaje,
      };
      final result = await _remoteDataSource.crear(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<VinculacionesPaginadas>> listar({
    required String empresaId,
    String? tipo,
    String? estado,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (tipo != null) 'tipo': tipo,
        if (estado != null) 'estado': estado,
      };
      final response =
          await _remoteDataSource.listar(queryParams: queryParams);
      final rawData = response['data'];
      final items = (rawData is List ? rawData : <dynamic>[])
          .map((e) => VinculacionEmpresaModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
      final meta = response['meta'] as Map<String, dynamic>? ?? {};
      return Success(VinculacionesPaginadas(
        data: items,
        total: meta['total'] as int? ?? 0,
        page: meta['page'] as int? ?? page,
        totalPages: meta['totalPages'] as int? ?? 1,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<VinculacionEmpresa>> getById({
    required String id,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getById(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<List<VinculacionEmpresa>>> getPendientes() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getPendientes();
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<VinculacionEmpresa>> responder({
    required String id,
    required bool aceptar,
    String? motivoRechazo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'aceptar': aceptar,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
      };
      final result = await _remoteDataSource.responder(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<VinculacionEmpresa>> cancelar({
    required String id,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.cancelar(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }

  @override
  Future<Resource<VinculacionEmpresa>> desvincular({
    required String id,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.desvincular(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Vinculacion');
    }
  }
}
