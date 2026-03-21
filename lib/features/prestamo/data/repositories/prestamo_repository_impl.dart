import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/prestamo.dart';
import '../../domain/repositories/prestamo_repository.dart';
import '../datasources/prestamo_remote_datasource.dart';

@LazySingleton(as: PrestamoRepository)
class PrestamoRepositoryImpl implements PrestamoRepository {
  final PrestamoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PrestamoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<Prestamo>>> listar({String? estado}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final prestamos = await _remoteDataSource.listar(estado: estado);
      return Success(prestamos.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Prestamo');
    }
  }

  @override
  Future<Resource<ResumenPrestamos>> getResumen() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final resumen = await _remoteDataSource.getResumen();
      return Success(resumen.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Prestamo');
    }
  }

  @override
  Future<Resource<Prestamo>> crear({
    required String tipo,
    required String entidadPrestamo,
    String? descripcion,
    required double montoOriginal,
    double? tasaInteres,
    String? moneda,
    int? cantidadCuotas,
    double? montoCuota,
    required String fechaDesembolso,
    String? fechaVencimiento,
    String? observaciones,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final prestamo = await _remoteDataSource.crear(
        tipo: tipo,
        entidadPrestamo: entidadPrestamo,
        descripcion: descripcion,
        montoOriginal: montoOriginal,
        tasaInteres: tasaInteres,
        moneda: moneda,
        cantidadCuotas: cantidadCuotas,
        montoCuota: montoCuota,
        fechaDesembolso: fechaDesembolso,
        fechaVencimiento: fechaVencimiento,
        observaciones: observaciones,
      );
      return Success(prestamo.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Prestamo');
    }
  }

  @override
  Future<Resource<Prestamo>> registrarPago({
    required String prestamoId,
    required String metodoPago,
    required double monto,
    String? referencia,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final prestamo = await _remoteDataSource.registrarPago(
        prestamoId: prestamoId,
        metodoPago: metodoPago,
        monto: monto,
        referencia: referencia,
      );
      return Success(prestamo.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Prestamo');
    }
  }
}
