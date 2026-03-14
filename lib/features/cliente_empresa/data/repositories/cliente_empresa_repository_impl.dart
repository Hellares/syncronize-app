import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cliente_empresa.dart';
import '../../domain/repositories/cliente_empresa_repository.dart';
import '../datasources/cliente_empresa_remote_datasource.dart';
import '../models/cliente_empresa_model.dart';

@LazySingleton(as: ClienteEmpresaRepository)
class ClienteEmpresaRepositoryImpl implements ClienteEmpresaRepository {
  final ClienteEmpresaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ClienteEmpresaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ClientesEmpresaPaginados>> getClientesEmpresa({
    required String empresaId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final response = await _remoteDataSource.getClientesEmpresa(
        empresaId: empresaId,
        search: search,
        page: page,
        limit: limit,
      );

      final rawData = response['data'];
      final items = (rawData is List ? rawData : <dynamic>[])
          .map((e) => ClienteEmpresaModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final meta = response['meta'] as Map<String, dynamic>? ?? {};
      return Success(ClientesEmpresaPaginados(
        data: items,
        total: meta['total'] as int? ?? items.length,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ClienteEmpresa');
    }
  }

  @override
  Future<Resource<ClienteEmpresaCreado>> crearClienteEmpresa({
    required String empresaId,
    required String razonSocial,
    required String numeroDocumento,
    String? nombreComercial,
    String tipoDocumento = 'RUC',
    String? email,
    String? telefono,
    String? direccion,
    String? estadoContribuyente,
    String? condicionContribuyente,
    String? ubigeo,
    String? departamento,
    String? provincia,
    String? distrito,
    List<Map<String, dynamic>>? contactos,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'razonSocial': razonSocial,
        'numeroDocumento': numeroDocumento,
        'tipoDocumento': tipoDocumento,
        if (nombreComercial != null) 'nombreComercial': nombreComercial,
        if (email != null) 'email': email,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
        if (estadoContribuyente != null) 'estadoContribuyente': estadoContribuyente,
        if (condicionContribuyente != null) 'condicionContribuyente': condicionContribuyente,
        if (ubigeo != null) 'ubigeo': ubigeo,
        if (departamento != null) 'departamento': departamento,
        if (provincia != null) 'provincia': provincia,
        if (distrito != null) 'distrito': distrito,
        if (contactos != null && contactos.isNotEmpty) 'contactos': contactos,
      };
      final rawJson = await _remoteDataSource.crearClienteEmpresaRaw(empresaId, data);
      final clienteEmpresa = ClienteEmpresaModel.fromJson(rawJson);

      EmpresaVinculableInfo? empresaVinculable;
      if (rawJson['empresaVinculable'] != null) {
        final ev = rawJson['empresaVinculable'] as Map<String, dynamic>;
        empresaVinculable = EmpresaVinculableInfo(
          id: ev['id'] as String,
          nombre: ev['nombre'] as String? ?? '',
          logo: ev['logo'] as String?,
          rubro: ev['rubro'] as String?,
        );
      }

      return Success(ClienteEmpresaCreado(
        clienteEmpresa: clienteEmpresa,
        empresaVinculable: empresaVinculable,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ClienteEmpresa');
    }
  }
}
