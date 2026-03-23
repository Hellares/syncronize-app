import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/periodo_planilla.dart';
import '../../domain/entities/boleta_pago.dart';
import '../../domain/repositories/planilla_repository.dart';
import '../datasources/planilla_remote_datasource.dart';

@LazySingleton(as: PlanillaRepository)
class PlanillaRepositoryImpl implements PlanillaRepository {
  final PlanillaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PlanillaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  // =============================================================
  // PERIODOS
  // =============================================================

  @override
  Future<Resource<PeriodoPlanilla>> createPeriodo(
      Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.createPeriodo(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<List<PeriodoPlanilla>>> getPeriodos({
    Map<String, dynamic>? queryParams,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.getPeriodos(queryParams: queryParams);
      return Success(result.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<PeriodoPlanilla>> getPeriodo(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getPeriodo(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<PeriodoPlanilla>> calcularPlanilla(
      String periodoId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.calcularPlanilla(periodoId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<PeriodoPlanilla>> aprobarPeriodo(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.aprobarPeriodo(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> pagarPlanilla(
      String periodoId, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.pagarPlanilla(periodoId, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  // =============================================================
  // BOLETAS
  // =============================================================

  @override
  Future<Resource<List<BoletaPago>>> getBoletas({
    Map<String, dynamic>? queryParams,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.getBoletas(queryParams: queryParams);
      return Success(result.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<BoletaPago>> getBoleta(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getBoleta(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }

  @override
  Future<Resource<BoletaPago>> pagarBoleta(
      String boletaId, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.pagarBoleta(boletaId, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Planilla');
    }
  }
}
