import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cita.dart';
import '../../domain/entities/slot_disponibilidad.dart';
import '../../domain/repositories/cita_repository.dart';
import '../datasources/cita_remote_datasource.dart';
import '../models/cita_model.dart';

@LazySingleton(as: CitaRepository)
class CitaRepositoryImpl implements CitaRepository {
  final CitaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  CitaRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Resource<DisponibilidadResponse>> getDisponibilidad({
    required String fecha,
    required String sedeId,
    required String servicioId,
    String? tecnicoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getDisponibilidad(
        fecha: fecha,
        sedeId: sedeId,
        servicioId: servicioId,
        tecnicoId: tecnicoId,
      );
      return Success(result);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<List<TecnicoDisponible>>> getTecnicosDisponibles({
    required String fecha,
    required String horaInicio,
    required String sedeId,
    required String servicioId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getTecnicosDisponibles(
        fecha: fecha,
        horaInicio: horaInicio,
        sedeId: sedeId,
        servicioId: servicioId,
      );
      return Success(result);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<Cita>> create(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.create(data);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<CitasPaginadas>> findAll(
      Map<String, dynamic> queryParams) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final responseData =
          await _remoteDataSource.findAll(queryParams: queryParams);

      final List<dynamic> citasJson = responseData['data'] as List;
      final citas = citasJson
          .map((e) => CitaModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(CitasPaginadas(
        data: citas,
        total: responseData['total'] as int,
        page: responseData['page'] as int,
        limit: responseData['limit'] as int,
        totalPages: responseData['totalPages'] as int,
      ));
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<Cita>> findOne(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.findOne(id);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<Cita>> update(String id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.update(id, data);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> transitionEstado(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.transitionEstado(id, data);
      return Success(result);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }
}
