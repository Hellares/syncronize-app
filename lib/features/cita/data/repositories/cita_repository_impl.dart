import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cita.dart';
import '../../domain/entities/cliente_con_citas.dart';
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
  Future<Resource<CitasPaginadas>> findMisCitas(
      Map<String, dynamic> queryParams) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final responseData =
          await _remoteDataSource.findMisCitas(queryParams: queryParams);

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

  @override
  Future<Resource<List<ClienteConCitas>>> getClientesConCitas(
      {String? search}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.getClientesConCitas(search: search);
      final clientes = (data['clientes'] as List?)
              ?.map((e) =>
                  ClienteConCitas.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return Success(clientes);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<({List<Cita> citas, int total})>> getHistorialCliente(
    String clienteId, {
    String? clienteEmpresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.getHistorialCliente(
        clienteId,
        clienteEmpresaId: clienteEmpresaId,
      );
      final citasList = (data['citas'] as List?)
              ?.map((e) =>
                  CitaModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList() ??
          [];
      final total = (data['total'] as num?)?.toInt() ?? 0;
      return Success((citas: citasList, total: total));
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<({List<CitaItem> items, double total})>> getItems(
      String citaId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.getItems(citaId);
      final itemsList = (data['items'] as List?)
              ?.map((e) =>
                  CitaModel.parseCitaItem(e as Map<String, dynamic>))
              .toList() ??
          [];
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      return Success((items: itemsList, total: total));
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<void>> addItem(
      String citaId, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.addItem(citaId, data);
      return Success(null);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<void>> updateItem(
      String citaId, String itemId, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.updateItem(citaId, itemId, data);
      return Success(null);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<void>> removeItem(String citaId, String itemId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.removeItem(citaId, itemId);
      return Success(null);
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }
}
