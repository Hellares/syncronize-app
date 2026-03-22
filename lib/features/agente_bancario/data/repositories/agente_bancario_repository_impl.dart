import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/agente_bancario.dart';
import '../../domain/repositories/agente_bancario_repository.dart';
import '../datasources/agente_bancario_remote_datasource.dart';

@LazySingleton(as: AgenteBancarioRepository)
class AgenteBancarioRepositoryImpl implements AgenteBancarioRepository {
  final AgenteBancarioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  AgenteBancarioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ResumenAgentes>> getResumen({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getResumen(sedeId: sedeId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }

  @override
  Future<Resource<List<AgenteBancario>>> getAgentes({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getAgentes(sedeId: sedeId);
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }

  @override
  Future<Resource<AgenteBancario>> getDetalle(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getDetalle(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }

  @override
  Future<Resource<AgenteBancario>> crear(
      String sedeId, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.crear(sedeId, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }

  @override
  Future<Resource<OperacionAgente>> registrarOperacion(
      String agenteId, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.registrarOperacion(agenteId, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }

  @override
  Future<Resource<void>> anularOperacion(
      String agenteId, String operacionId, String motivo) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.anularOperacion(agenteId, operacionId, motivo);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }

  @override
  Future<Resource<List<OperacionAgente>>> getOperaciones(
    String agenteId, {
    String? tipo,
    String? fechaDesde,
    int? limit,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getOperaciones(
        agenteId,
        tipo: tipo,
        fechaDesde: fechaDesde,
        limit: limit,
      );
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'AgenteBancario');
    }
  }
}
