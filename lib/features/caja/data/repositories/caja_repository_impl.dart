import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/caja.dart';
import '../../domain/entities/caja_auditoria.dart';
import '../../domain/entities/caja_monitor.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import '../../domain/entities/tesoreria.dart';
import '../../domain/repositories/caja_repository.dart';
import '../datasources/caja_remote_datasource.dart';
import '../models/caja_monitor_model.dart';

@LazySingleton(as: CajaRepository)
class CajaRepositoryImpl implements CajaRepository {
  final CajaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CajaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Caja>> abrirCaja({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
    String? sedeFacturacionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final caja = await _remoteDataSource.abrirCaja(
        sedeId: sedeId,
        montoApertura: montoApertura,
        observaciones: observaciones,
        sedeFacturacionId: sedeFacturacionId,
      );
      return Success(caja.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<Caja?>> getCajaActiva() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final caja = await _remoteDataSource.getCajaActiva();
      return Success(caja?.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<Caja>> getCajaById(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final caja = await _remoteDataSource.getCajaById(id);
      return Success(caja.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<void>> crearMovimiento({
    required String cajaId,
    required TipoMovimientoCaja tipo,
    required CategoriaMovimientoCaja categoria,
    required MetodoPago metodoPago,
    required double monto,
    String? descripcion,
    String? categoriaGastoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.crearMovimiento(
        cajaId: cajaId,
        tipo: tipo.apiValue,
        categoria: categoria.apiValue,
        metodoPago: metodoPago.apiValue,
        monto: monto,
        descripcion: descripcion,
        categoriaGastoId: categoriaGastoId,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<List<MovimientoCaja>>> getMovimientos({
    required String cajaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final movimientos = await _remoteDataSource.getMovimientos(cajaId);
      return Success(
        movimientos.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<Caja>> cerrarCaja({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final caja = await _remoteDataSource.cerrarCaja(
        cajaId: cajaId,
        conteos: conteos,
        observaciones: observaciones,
      );
      return Success(caja.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<List<Caja>>> getHistorial({
    String? sedeId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final cajas = await _remoteDataSource.getHistorial(
        sedeId: sedeId,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Success(cajas.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<ResumenCaja>> getResumen({
    required String cajaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final resumen = await _remoteDataSource.getResumen(cajaId);
      return Success(resumen.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<void>> anularMovimiento({
    required String cajaId,
    required String movimientoId,
    required String autorizadoPorId,
    required String motivo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.anularMovimiento(
        cajaId: cajaId,
        movimientoId: movimientoId,
        autorizadoPorId: autorizadoPorId,
        motivo: motivo,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<CajaMonitorData>> getMonitor({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remoteDataSource.getMonitor(sedeId: sedeId);
      return Success(CajaMonitorDataModel.fromJson(data));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<ArqueoCaja>> crearArqueo({
    required String cajaId,
    required TipoArqueoCaja tipo,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
    String? autorizadoPorId,
    String? turnoEntregadoAId,
    Map<String, int>? desgloseEfectivo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final arqueo = await _remoteDataSource.crearArqueo(
        cajaId: cajaId,
        tipoApiValue: tipo.apiValue,
        conteos: conteos,
        observaciones: observaciones,
        autorizadoPorId: autorizadoPorId,
        turnoEntregadoAId: turnoEntregadoAId,
        desgloseEfectivo: desgloseEfectivo,
      );
      return Success(arqueo);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<List<ArqueoCaja>>> getArqueos({required String cajaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final arqueos = await _remoteDataSource.getArqueos(cajaId);
      return Success(arqueos);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<CajaAuditoria>> getAuditoria({required String cajaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final auditoria = await _remoteDataSource.getAuditoria(cajaId);
      return Success(auditoria);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Caja');
    }
  }

  @override
  Future<Resource<TesoreriaResumen>> getTesoreriaResumen(String sedeId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final resumen = await _remoteDataSource.getTesoreriaResumen(sedeId);
      return Success(resumen.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tesoreria');
    }
  }

  @override
  Future<Resource<TesoreriaMovimientosPage>> getTesoreriaMovimientos({
    required String sedeId,
    required TesoreriaMovimientosFilter filter,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final page = await _remoteDataSource.getTesoreriaMovimientos(
        sedeId: sedeId,
        tipo: filter.tipo?.apiValue,
        metodoPago: filter.metodoPago?.apiValue,
        categoria: filter.categoria?.apiValue,
        fechaDesde: filter.fechaDesde,
        fechaHasta: filter.fechaHasta,
        q: filter.q,
        page: filter.page,
        pageSize: filter.pageSize,
      );
      return Success(page.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tesoreria');
    }
  }

  @override
  Future<Resource<MovimientoCaja>> crearAjusteTesoreria({
    required String sedeId,
    required TipoMovimientoCaja tipo,
    required MetodoPago metodoPago,
    required double monto,
    required String descripcion,
    String? categoriaGastoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final mov = await _remoteDataSource.crearAjusteTesoreria(
        sedeId: sedeId,
        tipo: tipo.apiValue,
        metodoPago: metodoPago.apiValue,
        monto: monto,
        descripcion: descripcion,
        categoriaGastoId: categoriaGastoId,
      );
      return Success(mov);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Tesoreria');
    }
  }
}
