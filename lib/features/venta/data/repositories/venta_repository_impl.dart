import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/reversion_total.dart';
import '../../domain/entities/venta.dart';
import '../../domain/repositories/venta_repository.dart';
import '../datasources/venta_remote_datasource.dart';

@LazySingleton(as: VentaRepository)
class VentaRepositoryImpl implements VentaRepository {
  final VentaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  VentaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Venta>> crearVenta({
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.crearVenta(data);
      return Success(venta.toEntity());
    } catch (e) {
      return _handleVentaException(e);
    }
  }

  @override
  Future<Resource<Venta>> crearVentaDesdeCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.crearVentaDesdeCotizacion(
        cotizacionId,
        data,
      );
      return Success(venta.toEntity());
    } catch (e) {
      return _handleVentaException(e);
    }
  }

  @override
  Future<Resource<Venta>> crearYCobrar({
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.crearYCobrar(data);
      return Success(venta.toEntity());
    } catch (e) {
      return _handleVentaException(e);
    }
  }

  /// Captura excepciones de los 3 endpoints de creación de venta. Detecta
  /// específicamente el caso 409 `PRECIO_DESACTUALIZADO` (el backend rechaza
  /// la venta cuando el precio enviado difiere del actual) y lo expone con
  /// `errorCode: 'PRECIO_DESACTUALIZADO'` + `details.divergencias` para que
  /// la UI muestre un dialog con los productos afectados y el cajero pueda
  /// refrescar antes de reintentar. Cualquier otro error cae al handler
  /// genérico.
  Resource<Venta> _handleVentaException(dynamic e) {
    // El error real es un `DioException` (Dio re-envuelve cuando el
    // interceptor `throw`s) con `error: ServerException` adentro.
    // Desempaquetamos por todos los caminos posibles para capturar el
    // 409 PRECIO_DESACTUALIZADO.
    Map<String, dynamic>? body;
    String? message;

    if (e is DioException) {
      if (e.response?.statusCode == 409 && e.response?.data is Map) {
        body = Map<String, dynamic>.from(e.response!.data as Map);
      } else if (e.error is ServerException) {
        final inner = e.error as ServerException;
        if (inner.statusCode == 409 && inner.data != null) {
          body = inner.data;
          message = inner.message;
        }
      }
    } else if (e is ServerException) {
      if (e.statusCode == 409 && e.data != null) {
        body = e.data;
        message = e.message;
      }
    }

    if (body != null && body['code'] == 'PRECIO_DESACTUALIZADO') {
      final divergencias = body['divergencias'] is List
          ? List<Map<String, dynamic>>.from(
              (body['divergencias'] as List)
                  .whereType<Map>()
                  .map((m) => Map<String, dynamic>.from(m)),
            )
          : <Map<String, dynamic>>[];
      return Error(
        (body['message'] as String?) ??
            message ??
            'Los precios cambiaron. Refrescá el carrito.',
        statusCode: 409,
        errorCode: 'PRECIO_DESACTUALIZADO',
        details: {'divergencias': divergencias},
      );
    }
    return _errorHandler.handleException(e, context: 'Venta');
  }

  @override
  Future<Resource<List<Venta>>> getVentas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final ventas = await _remoteDataSource.getVentas(
        sedeId: sedeId,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        clienteId: clienteId,
        search: search,
      );
      return Success(ventas.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> getVenta({required String ventaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.getVenta(ventaId);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> actualizarVenta({
    required String ventaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.actualizarVenta(ventaId, data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> confirmarVenta({required String ventaId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.confirmarVenta(ventaId);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> procesarPago({
    required String ventaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.procesarPago(ventaId, data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> anularVenta({
    required String ventaId,
    required String autorizadoPorId,
    required String motivo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.anularVenta(
        ventaId,
        autorizadoPorId: autorizadoPorId,
        motivo: motivo,
      );
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta>> generarComprobante({
    required String ventaId,
    required String tipoComprobante,
    String? tipoDocumentoCliente,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.generarComprobante(
        ventaId,
        tipoComprobante: tipoComprobante,
        tipoDocumentoCliente: tipoDocumentoCliente,
      );
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> getResumen({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getResumen(sedeId: sedeId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<Venta?>> buscarPorCodigo({required String codigo}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remoteDataSource.buscarPorCodigo(codigo);
      return Success(venta?.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  // ── Reversión total ──

  @override
  Future<Resource<ReversionTotal>> crearReversionTotal({
    required String ventaId,
    String? motivo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final rev = await _remoteDataSource.crearReversionTotal(ventaId, motivo: motivo);
      return Success(rev);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }

  @override
  Future<Resource<ReversionTotal?>> obtenerReversionTotal({
    required String ventaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final rev = await _remoteDataSource.obtenerReversionTotal(ventaId);
      return Success(rev);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Venta');
    }
  }
}
