import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
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

  /// Devuelve un `Error<Venta>` con `errorCode: PRECIO_DESACTUALIZADO` y
  /// las divergencias si la excepción dada representa un 409 del backend.
  /// Si no es ese caso, devuelve null y el caller cae al handler genérico.
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

    if (body == null || body['code'] != 'PRECIO_DESACTUALIZADO') return null;

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
