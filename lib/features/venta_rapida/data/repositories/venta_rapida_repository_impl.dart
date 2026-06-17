import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../domain/entities/orden_cobrable.dart';
import '../../domain/repositories/venta_rapida_repository.dart';
import '../datasources/venta_rapida_remote_datasource.dart';

@LazySingleton(as: VentaRapidaRepository)
class VentaRapidaRepositoryImpl implements VentaRapidaRepository {
  final VentaRapidaRemoteDataSource _remote;
  final NetworkInfo _network;
  final ErrorHandlerService _errorHandler;

  VentaRapidaRepositoryImpl(
    this._remote,
    this._network,
    this._errorHandler,
  );

  @override
  Future<Resource<Venta>> cobrar({required Map<String, dynamic> data}) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remote.cobrar(data);
      return Success(venta.toEntity());
    } catch (e) {
      // Detección del 409 `PRECIO_DESACTUALIZADO` antes del handler
      // genérico. El error real que llega al catch es un `DioException`
      // (Dio lo re-envuelve cuando el interceptor `throw`s) con
      // `error: ServerException` adentro. Por eso desempaquetamos:
      //   - Si es DioException con error ServerException → leer esa.
      //   - Si es DioException con response 409 → leer response.data directo.
      //   - Si es ServerException directa → leer su `data`.
      final priceConflict = _extractPriceConflict(e);
      if (priceConflict != null) return priceConflict;
      return _errorHandler.handleException(e, context: 'VentaRapida');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> cobroYape(String ventaId) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = await _remote.cobroYape(ventaId);
      return Success(data);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'VentaRapida.cobroYape');
    }
  }

  @override
  Future<Resource<String>> estadoVenta(String ventaId) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final estado = await _remote.estadoVenta(ventaId);
      return Success(estado);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'VentaRapida.estadoVenta');
    }
  }

  @override
  Future<Resource<Venta>> registrarPago(
      String ventaId, Map<String, dynamic> data) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final venta = await _remote.registrarPago(ventaId, data);
      return Success(venta.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'VentaRapida.registrarPago');
    }
  }

  /// Devuelve un `Error<Venta>` con un `errorCode` estructurado si la
  /// excepción representa un 409 del backend con `code:
  /// PRECIO_DESACTUALIZADO` o `STOCK_INSUFICIENTE`. Si no es ninguno,
  /// devuelve null y el caller cae al handler genérico.
  Error<Venta>? _extractPriceConflict(Object e) {
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

    if (body == null) return null;
    final code = body['code'];
    const codigosEstructurados = {
      'PRECIO_DESACTUALIZADO',
      'STOCK_INSUFICIENTE',
      // Cobro de órdenes de servicio: el saldo cambió mientras estaba en el
      // carrito, o otra venta ya la cobró. El mensaje del backend es
      // autoexplicativo — se muestra tal cual.
      'SALDO_ORDEN_DESACTUALIZADO',
      'ORDEN_YA_COBRADA',
    };
    if (!codigosEstructurados.contains(code)) {
      return null;
    }

    final divergencias = body['divergencias'] is List
        ? List<Map<String, dynamic>>.from(
            (body['divergencias'] as List)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m)),
          )
        : <Map<String, dynamic>>[];
    // ORDEN_YA_COBRADA: ids de las órdenes afectadas para que el cubit
    // quite exactamente esas líneas del carrito.
    final ordenes = body['ordenes'] is List
        ? List<Map<String, dynamic>>.from(
            (body['ordenes'] as List)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m)),
          )
        : <Map<String, dynamic>>[];
    return Error(
      (body['message'] as String?) ??
          message ??
          (code == 'STOCK_INSUFICIENTE'
              ? 'Stock insuficiente. Ajustá el carrito.'
              : 'Los precios cambiaron. Refrescá el carrito.'),
      statusCode: 409,
      errorCode: code as String,
      details: {'divergencias': divergencias, 'ordenes': ordenes},
    );
  }

  @override
  Future<Resource<String>> obtenerClienteGenericoId() async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final id = await _remote.obtenerClienteGenericoId();
      return Success(id);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'VentaRapida');
    }
  }

  @override
  Future<Resource<ClienteResueltoRuc>> buscarClientePorRuc(String ruc) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final body = await _remote.buscarClientePorRuc(ruc);
      return Success(ClienteResueltoRuc(
        clienteEmpresaId: body['clienteEmpresaId'] as String,
        ruc: body['ruc'] as String? ?? ruc,
        razonSocial: body['razonSocial'] as String? ?? '',
        nombreComercial: body['nombreComercial'] as String?,
        direccion: body['direccion'] as String?,
        estadoContribuyente: body['estadoContribuyente'] as String?,
        condicionContribuyente: body['condicionContribuyente'] as String?,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'VentaRapida');
    }
  }

  @override
  Future<Resource<List<OrdenCobrable>>> getOrdenesCobrables({String? search}) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final list = await _remote.getOrdenesCobrables(search: search);
      return Success(list.map(OrdenCobrable.fromJson).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'VentaRapida');
    }
  }

  @override
  Future<Resource<ClienteResueltoDni>> buscarClientePorDni(String dni) async {
    if (!await _network.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final body = await _remote.buscarClientePorDni(dni);
      return Success(ClienteResueltoDni(
        clienteEmpresaId: body['clienteEmpresaId'] as String,
        personaId: body['personaId'] as String? ?? '',
        dni: body['dni'] as String? ?? dni,
        nombres: body['nombres'] as String? ?? '',
        apellidos: body['apellidos'] as String? ?? '',
        nombreCompleto: body['nombreCompleto'] as String? ?? '',
        direccion: body['direccion'] as String?,
        origen: body['origen'] as String? ?? 'INTERNO',
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'VentaRapida');
    }
  }
}
