import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/empresa_context_model.dart';
import '../models/empresa_list_item_model.dart';
import '../models/personalizacion_empresa_model.dart';

/// Data source remoto para operaciones de empresa
@lazySingleton
class EmpresaRemoteDataSource {
  final DioClient _dioClient;

  EmpresaRemoteDataSource(this._dioClient);

  /// Obtiene la lista de empresas del usuario
  ///
  /// GET /api/empresas
  Future<List<EmpresaListItemModel>> getUserEmpresas() async {
    final response = await _dioClient.get(ApiConstants.empresas);

    if (response.data is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    return (response.data as List)
        .map((json) => EmpresaListItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el contexto completo de una empresa desde el backend
  ///
  /// GET /api/empresas/:empresaId/context
  Future<EmpresaContextModel> getEmpresaContext(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/context',
    );

    return EmpresaContextModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cambia la empresa activa (switch tenant)
  ///
  /// POST /api/auth/switch-tenant
  Future<void> switchEmpresa({
    required String empresaId,
    String? subdominioEmpresa,
  }) async {
    await _dioClient.post(
      '/auth/switch-tenant',
      data: {
        'empresaId': empresaId,
        if (subdominioEmpresa != null) 'subdominioEmpresa': subdominioEmpresa,
      },
    );
  }

  /// Obtiene la personalización de la empresa
  ///
  /// GET /api/empresas/:empresaId/personalizacion
  Future<PersonalizacionEmpresaModel> getPersonalizacion(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/$empresaId/personalizacion',
    );

    return PersonalizacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza la personalización de la empresa
  ///
  /// PUT /api/empresas/:empresaId/personalizacion
  Future<PersonalizacionEmpresaModel> updatePersonalizacion({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.empresas}/$empresaId/personalizacion',
      data: data,
    );

    return PersonalizacionEmpresaModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
