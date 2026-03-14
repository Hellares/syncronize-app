import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cliente_empresa_model.dart';

@lazySingleton
class ClienteEmpresaRemoteDataSource {
  final DioClient _dioClient;

  ClienteEmpresaRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> getClientesEmpresa({
    required String empresaId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId${ApiConstants.clientesEmpresa}',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ClienteEmpresaModel> getClienteEmpresa(
    String empresaId,
    String id,
  ) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId${ApiConstants.clientesEmpresa}/$id',
    );
    return ClienteEmpresaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClienteEmpresaModel> crearClienteEmpresa(
    String empresaId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId${ApiConstants.clientesEmpresa}',
      data: data,
    );
    return ClienteEmpresaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClienteEmpresaContactoModel> agregarContacto(
    String empresaId,
    String clienteEmpresaId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId${ApiConstants.clientesEmpresa}/$clienteEmpresaId/contactos',
      data: data,
    );
    return ClienteEmpresaContactoModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
