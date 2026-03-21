import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja_chica.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import '../../domain/entities/rendicion_caja_chica.dart';
import '../../domain/repositories/caja_chica_repository.dart';
import '../datasources/caja_chica_remote_datasource.dart';

@LazySingleton(as: CajaChicaRepository)
class CajaChicaRepositoryImpl implements CajaChicaRepository {
  final CajaChicaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CajaChicaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<CajaChica>> crearCajaChica({
    required String sedeId,
    required String nombre,
    required double fondoFijo,
    double? umbralAlerta,
    required String responsableId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cajaChica = await _remoteDataSource.crearCajaChica(
        sedeId: sedeId,
        nombre: nombre,
        fondoFijo: fondoFijo,
        umbralAlerta: umbralAlerta,
        responsableId: responsableId,
      );
      return Success(cajaChica.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<List<CajaChica>>> listarCajasChicas({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cajas = await _remoteDataSource.listarCajasChicas(sedeId: sedeId);
      return Success(cajas.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<CajaChica>> getCajaChica({required String id}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cajaChica = await _remoteDataSource.getCajaChica(id);
      return Success(cajaChica.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<void>> actualizarEstado({
    required String id,
    required String estado,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.actualizarEstado(id: id, estado: estado);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<GastoCajaChica>> registrarGasto({
    required String cajaChicaId,
    required double monto,
    required String descripcion,
    required String categoriaGastoId,
    String? comprobanteUrl,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final gasto = await _remoteDataSource.registrarGasto(
        cajaChicaId: cajaChicaId,
        monto: monto,
        descripcion: descripcion,
        categoriaGastoId: categoriaGastoId,
        comprobanteUrl: comprobanteUrl,
      );
      return Success(gasto.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<List<GastoCajaChica>>> listarGastos({
    required String cajaChicaId,
    bool? pendientes,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final gastos = await _remoteDataSource.listarGastos(
        cajaChicaId: cajaChicaId,
        pendientes: pendientes,
      );
      return Success(gastos.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<RendicionCajaChica>> crearRendicion({
    required String cajaChicaId,
    required List<String> gastoIds,
    String? observaciones,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final rendicion = await _remoteDataSource.crearRendicion(
        cajaChicaId: cajaChicaId,
        gastoIds: gastoIds,
        observaciones: observaciones,
      );
      return Success(rendicion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<List<RendicionCajaChica>>> listarRendiciones({
    String? cajaChicaId,
    String? estado,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final rendiciones = await _remoteDataSource.listarRendiciones(
        cajaChicaId: cajaChicaId,
        estado: estado,
      );
      return Success(rendiciones.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<RendicionCajaChica>> getRendicion({
    required String rendicionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final rendicion = await _remoteDataSource.getRendicion(rendicionId);
      return Success(rendicion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<void>> aprobarRendicion({
    required String rendicionId,
    String? observaciones,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.aprobarRendicion(
        rendicionId: rendicionId,
        observaciones: observaciones,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }

  @override
  Future<Resource<void>> rechazarRendicion({
    required String rendicionId,
    required String observaciones,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.rechazarRendicion(
        rendicionId: rendicionId,
        observaciones: observaciones,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CajaChica');
    }
  }
}
