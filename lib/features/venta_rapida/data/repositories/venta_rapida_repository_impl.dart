import 'package:injectable/injectable.dart';

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
      return _errorHandler.handleException(e, context: 'VentaRapida');
    }
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
