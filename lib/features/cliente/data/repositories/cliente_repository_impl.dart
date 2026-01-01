import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_filtros.dart';
import '../../domain/entities/registro_cliente_response.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/cliente_remote_datasource.dart';
import '../models/cliente_model.dart';

@LazySingleton(as: ClienteRepository)
class ClienteRepositoryImpl implements ClienteRepository {
  final ClienteRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ClienteRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<RegistroClienteResponse>> registrarCliente({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await _remoteDataSource.registrarCliente(data);
      return Success(result.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<ClientesPaginados>> getClientes({
    required String empresaId,
    required ClienteFiltros filtros,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final responseData = await _remoteDataSource.getClientes(
        empresaId: empresaId,
        filtros: filtros,
      );

      // Parsear los clientes del campo 'data'
      final List<dynamic> clientesJson = responseData['data'] as List;
      final clientes = clientesJson
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Parsear la metadata de paginación
      final meta = responseData['meta'] as Map<String, dynamic>;

      final paginado = ClientesPaginados(
        data: clientes,
        total: meta['total'] as int,
        page: meta['page'] as int,
        totalPages: meta['totalPages'] as int,
        hasNext: meta['hasNext'] as bool,
        hasPrev: meta['hasPrevious'] as bool,
      );

      return Success(paginado);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Cliente>> getCliente({
    required String empresaId,
    required String clienteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cliente = await _remoteDataSource.getCliente(
        clienteId: clienteId,
        empresaId: empresaId,
      );
      return Success(cliente.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Cliente>> updateCliente({
    required String empresaId,
    required String clienteId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cliente = await _remoteDataSource.actualizarCliente(
        clienteId: clienteId,
        empresaId: empresaId,
        data: data,
      );
      return Success(cliente.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> deleteCliente({
    required String empresaId,
    required String clienteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarCliente(
        clienteId: clienteId,
        empresaId: empresaId,
      );
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}
