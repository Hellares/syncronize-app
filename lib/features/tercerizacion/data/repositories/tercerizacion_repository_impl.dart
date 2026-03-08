import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/directorio_empresa.dart';
import '../../domain/entities/tercerizacion.dart';
import '../../domain/repositories/tercerizacion_repository.dart';
import '../datasources/tercerizacion_remote_datasource.dart';
import '../models/directorio_empresa_model.dart';
import '../models/tercerizacion_model.dart';

@LazySingleton(as: TercerizacionRepository)
class TercerizacionRepositoryImpl implements TercerizacionRepository {
  final TercerizacionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  TercerizacionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<DirectorioPaginado>> buscarEmpresas({
    required String empresaId,
    String? search,
    String? tipoServicio,
    String? departamento,
    String? distrito,
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
        if (search != null && search.isNotEmpty) 'search': search,
        if (tipoServicio != null) 'tipoServicio': tipoServicio,
        if (departamento != null) 'departamento': departamento,
        if (distrito != null) 'distrito': distrito,
      };
      final response =
          await _remoteDataSource.buscarEmpresas(queryParams: queryParams);
      final rawData = response['data'];
      final items = (rawData is List ? rawData : <dynamic>[])
          .map((e) =>
              DirectorioEmpresaModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = response['meta'] as Map<String, dynamic>? ?? {};
      return Success(DirectorioPaginado(
        data: items,
        total: meta['total'] as int? ?? 0,
        page: meta['page'] as int? ?? page,
        totalPages: meta['totalPages'] as int? ?? 1,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<TercerizacionServicio>> crear({
    required String empresaDestinoId,
    required String ordenOrigenId,
    String? notasOrigen,
    String? descripcionProblema,
    List<String>? sintomas,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'empresaDestinoId': empresaDestinoId,
        'ordenOrigenId': ordenOrigenId,
        if (notasOrigen != null) 'notasOrigen': notasOrigen,
        if (descripcionProblema != null) 'descripcionProblema': descripcionProblema,
        if (sintomas != null && sintomas.isNotEmpty) 'sintomas': sintomas,
      };
      final result = await _remoteDataSource.crear(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<TercerizacionesPaginadas>> listar({
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
          .map((e) => TercerizacionServicioModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
      final meta = response['meta'] as Map<String, dynamic>? ?? {};
      return Success(TercerizacionesPaginadas(
        data: items,
        total: meta['total'] as int? ?? 0,
        page: meta['page'] as int? ?? page,
        totalPages: meta['totalPages'] as int? ?? 1,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<TercerizacionServicio>> getById({
    required String id,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getById(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<List<TercerizacionServicio>>> getPendientes() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getPendientes();
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<TercerizacionServicio>> responder({
    required String id,
    required bool aceptar,
    String? motivoRechazo,
    String? notasDestino,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'aceptar': aceptar,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
        if (notasDestino != null) 'notasDestino': notasDestino,
      };
      final result = await _remoteDataSource.responder(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<TercerizacionServicio>> completar({
    required String id,
    required double precioB2B,
    String? metodoPagoB2B,
    String? notasDestino,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'precioB2B': precioB2B,
        if (metodoPagoB2B != null) 'metodoPagoB2B': metodoPagoB2B,
        if (notasDestino != null) 'notasDestino': notasDestino,
      };
      final result = await _remoteDataSource.completar(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }

  @override
  Future<Resource<TercerizacionServicio>> cancelar({
    required String id,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.cancelar(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tercerizacion');
    }
  }
}
