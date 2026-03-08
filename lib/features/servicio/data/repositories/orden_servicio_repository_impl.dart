import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/orden_servicio.dart';
import '../../domain/entities/servicio_filtros.dart';
import '../../domain/repositories/orden_servicio_repository.dart';
import '../datasources/orden_servicio_remote_datasource.dart';
import '../models/orden_servicio_model.dart';

@LazySingleton(as: OrdenServicioRepository)
class OrdenServicioRepositoryImpl implements OrdenServicioRepository {
  final OrdenServicioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  OrdenServicioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<OrdenServicio>> crear({
    required String empresaId,
    required String clienteId,
    required String tipoServicio,
    String? tecnicoId,
    String? sedeId,
    String? prioridad,
    String? descripcionProblema,
    dynamic sintomas,
    String? tipoEquipo,
    String? marcaEquipo,
    String? numeroSerie,
    String? modeloEquipoId,
    dynamic accesorios,
    String? condicionEquipo,
    String? notas,
    String? servicioId,
    Map<String, dynamic>? datosPersonalizados,
    bool? incluirAvisoMantenimiento,
    DateTime? fechaAvisoPersonalizado,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'empresaId': empresaId,
        'clienteId': clienteId,
        'tipoServicio': tipoServicio,
        if (tecnicoId != null) 'tecnicoId': tecnicoId,
        if (sedeId != null) 'sedeId': sedeId,
        if (prioridad != null) 'prioridad': prioridad,
        if (descripcionProblema != null) 'descripcionProblema': descripcionProblema,
        if (sintomas != null) 'sintomas': sintomas,
        if (tipoEquipo != null) 'tipoEquipo': tipoEquipo,
        if (marcaEquipo != null) 'marcaEquipo': marcaEquipo,
        if (numeroSerie != null) 'numeroSerie': numeroSerie,
        if (modeloEquipoId != null) 'modeloEquipoId': modeloEquipoId,
        if (accesorios != null) 'accesorios': accesorios,
        if (condicionEquipo != null) 'condicionEquipo': condicionEquipo,
        if (notas != null) 'notas': notas,
        if (servicioId != null) 'servicioId': servicioId,
        if (datosPersonalizados != null) 'datosPersonalizados': datosPersonalizados,
        if (incluirAvisoMantenimiento != null) 'incluirAvisoMantenimiento': incluirAvisoMantenimiento,
        if (fechaAvisoPersonalizado != null) 'fechaAvisoPersonalizado': fechaAvisoPersonalizado.toIso8601String(),
      };
      final result = await _remoteDataSource.crear(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<OrdenesServicioPaginadas>> getOrdenes({
    required String empresaId,
    required OrdenServicioFiltros filtros,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final response = await _remoteDataSource.getOrdenes(
        empresaId: empresaId,
        filtros: filtros,
      );

      final rawData = response['data'];
      final items = (rawData is List ? rawData : <dynamic>[])
          .map((e) => OrdenServicioModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final meta = response['meta'] as Map<String, dynamic>? ?? {};
      return Success(OrdenesServicioPaginadas(
        data: items,
        total: meta['total'] as int? ?? 0,
        hasNext: meta['hasNext'] as bool? ?? false,
        nextCursor: meta['nextCursor'] as String?,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<OrdenServicio>> getOrden({
    required String id,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getOrden(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<OrdenServicio>> actualizar({
    required String id,
    required String empresaId,
    String? tipoServicio,
    String? prioridad,
    String? descripcionProblema,
    dynamic sintomas,
    String? tipoEquipo,
    String? marcaEquipo,
    String? numeroSerie,
    String? condicionEquipo,
    String? notas,
    double? costoTotal,
    double? adelanto,
    double? descuento,
    String? metodoPagoAdelanto,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        if (tipoServicio != null) 'tipoServicio': tipoServicio,
        if (prioridad != null) 'prioridad': prioridad,
        if (descripcionProblema != null) 'descripcionProblema': descripcionProblema,
        if (sintomas != null) 'sintomas': sintomas,
        if (tipoEquipo != null) 'tipoEquipo': tipoEquipo,
        if (marcaEquipo != null) 'marcaEquipo': marcaEquipo,
        if (numeroSerie != null) 'numeroSerie': numeroSerie,
        if (condicionEquipo != null) 'condicionEquipo': condicionEquipo,
        if (notas != null) 'notas': notas,
        if (costoTotal != null) 'costoTotal': costoTotal,
        if (adelanto != null) 'adelanto': adelanto,
        if (descuento != null) 'descuento': descuento,
        if (metodoPagoAdelanto != null) 'metodoPagoAdelanto': metodoPagoAdelanto,
      };
      final result = await _remoteDataSource.actualizar(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<OrdenServicio>> transitionEstado({
    required String id,
    required String empresaId,
    required String nuevoEstado,
    String? notas,
    dynamic diagnostico,
    bool comunicarCliente = false,
    String? motivoReingreso,
    double? costoTotal,
    double? adelanto,
    double? descuento,
    String? metodoPagoAdelanto,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'nuevoEstado': nuevoEstado,
        if (notas != null) 'notas': notas,
        if (diagnostico != null) 'diagnostico': diagnostico,
        if (comunicarCliente) 'comunicarCliente': true,
        if (motivoReingreso != null) 'motivoReingreso': motivoReingreso,
        if (costoTotal != null) 'costoTotal': costoTotal,
        if (adelanto != null) 'adelanto': adelanto,
        if (descuento != null) 'descuento': descuento,
        if (metodoPagoAdelanto != null) 'metodoPagoAdelanto': metodoPagoAdelanto,
      };
      final result = await _remoteDataSource.transitionEstado(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<OrdenServicio>> assignTecnico({
    required String id,
    required String empresaId,
    required String tecnicoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.assignTecnico(id, tecnicoId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<OrdenComponente>> addComponente({
    required String ordenId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.addComponente(ordenId, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<List<OrdenComponente>>> getComponentes({
    required String ordenId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getComponentes(ordenId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<void>> removeComponente({
    required String ordenId,
    required String componenteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.removeComponente(ordenId, componenteId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }

  @override
  Future<Resource<List<HistorialOrdenServicio>>> getHistorial({
    required String ordenId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getHistorial(ordenId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'OrdenServicio');
    }
  }
}
