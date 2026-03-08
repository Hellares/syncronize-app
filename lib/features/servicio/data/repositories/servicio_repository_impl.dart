import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/servicio_filtros.dart';
import '../../domain/repositories/servicio_repository.dart';
import '../datasources/servicio_remote_datasource.dart';
import '../models/servicio_model.dart';

@LazySingleton(as: ServicioRepository)
class ServicioRepositoryImpl implements ServicioRepository {
  final ServicioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ServicioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Servicio>> crear({
    required String empresaId,
    required String nombre,
    String? descripcion,
    double? precio,
    double? precioPorHora,
    int? duracionMinutos,
    double? duracionHoras,
    String? tipoServicio,
    bool? requiereReserva,
    bool? requiereDeposito,
    double? depositoPorcentaje,
    bool? visibleMarketplace,
    bool? enOferta,
    double? precioOferta,
    String? sedeId,
    String? empresaCategoriaId,
    String? unidadMedidaId,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? comisionTecnico,
    String? plantillaServicioId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'empresaId': empresaId,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (precio != null) 'precio': precio,
        if (precioPorHora != null) 'precioPorHora': precioPorHora,
        if (duracionMinutos != null) 'duracionMinutos': duracionMinutos,
        if (duracionHoras != null) 'duracionHoras': duracionHoras,
        if (tipoServicio != null) 'tipoServicio': tipoServicio,
        if (requiereReserva != null) 'requiereReserva': requiereReserva,
        if (requiereDeposito != null) 'requiereDeposito': requiereDeposito,
        if (depositoPorcentaje != null) 'depositoPorcentaje': depositoPorcentaje,
        if (visibleMarketplace != null) 'visibleMarketplace': visibleMarketplace,
        if (enOferta != null) 'enOferta': enOferta,
        if (precioOferta != null) 'precioOferta': precioOferta,
        if (sedeId != null) 'sedeId': sedeId,
        if (empresaCategoriaId != null) 'empresaCategoriaId': empresaCategoriaId,
        if (unidadMedidaId != null) 'unidadMedidaId': unidadMedidaId,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (impuestoPorcentaje != null) 'impuestoPorcentaje': impuestoPorcentaje,
        if (comisionTecnico != null) 'comisionTecnico': comisionTecnico,
        if (plantillaServicioId != null) 'plantillaServicioId': plantillaServicioId,
      };
      final result = await _remoteDataSource.crear(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Servicio');
    }
  }

  @override
  Future<Resource<ServiciosPaginados>> getServicios({
    required String empresaId,
    required ServicioFiltros filtros,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final response = await _remoteDataSource.getServicios(
        empresaId: empresaId,
        filtros: filtros,
      );

      final rawData = response['data'];
      final items = (rawData is List ? rawData : <dynamic>[])
          .map((e) => ServicioModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(ServiciosPaginados(
        data: items,
        total: response['total'] as int? ?? 0,
        page: response['page'] as int? ?? 1,
        pageSize: response['pageSize'] as int? ?? items.length,
        totalPages: response['totalPages'] as int? ?? 1,
        hasNext: response['hasNext'] as bool? ?? false,
        hasPrevious: response['hasPrevious'] as bool? ?? false,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Servicio');
    }
  }

  @override
  Future<Resource<Servicio>> getServicio({
    required String id,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getServicio(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Servicio');
    }
  }

  @override
  Future<Resource<Servicio>> actualizar({
    required String id,
    required String empresaId,
    String? nombre,
    String? descripcion,
    double? precio,
    double? precioPorHora,
    int? duracionMinutos,
    double? duracionHoras,
    String? tipoServicio,
    bool? requiereReserva,
    bool? requiereDeposito,
    double? depositoPorcentaje,
    bool? visibleMarketplace,
    bool? enOferta,
    double? precioOferta,
    String? sedeId,
    String? empresaCategoriaId,
    String? unidadMedidaId,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? comisionTecnico,
    String? plantillaServicioId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (precio != null) 'precio': precio,
        if (precioPorHora != null) 'precioPorHora': precioPorHora,
        if (duracionMinutos != null) 'duracionMinutos': duracionMinutos,
        if (duracionHoras != null) 'duracionHoras': duracionHoras,
        if (tipoServicio != null) 'tipoServicio': tipoServicio,
        if (requiereReserva != null) 'requiereReserva': requiereReserva,
        if (requiereDeposito != null) 'requiereDeposito': requiereDeposito,
        if (depositoPorcentaje != null) 'depositoPorcentaje': depositoPorcentaje,
        if (visibleMarketplace != null) 'visibleMarketplace': visibleMarketplace,
        if (enOferta != null) 'enOferta': enOferta,
        if (precioOferta != null) 'precioOferta': precioOferta,
        if (sedeId != null) 'sedeId': sedeId,
        if (empresaCategoriaId != null) 'empresaCategoriaId': empresaCategoriaId,
        if (unidadMedidaId != null) 'unidadMedidaId': unidadMedidaId,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (impuestoPorcentaje != null) 'impuestoPorcentaje': impuestoPorcentaje,
        if (comisionTecnico != null) 'comisionTecnico': comisionTecnico,
        if (plantillaServicioId != null) 'plantillaServicioId': plantillaServicioId,
      };
      final result = await _remoteDataSource.actualizar(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Servicio');
    }
  }

  @override
  Future<Resource<void>> eliminar({
    required String id,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.eliminar(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Servicio');
    }
  }
}
