import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/unidad_medida_model.dart';

/// Data source remoto para operaciones de unidades de medida
@lazySingleton
class UnidadMedidaRemoteDataSource {
  final DioClient _dioClient;

  UnidadMedidaRemoteDataSource(this._dioClient);

  /// Obtiene todas las unidades de medida maestras (catálogo SUNAT)
  ///
  /// GET /api/catalogos/unidades-maestras
  Future<List<UnidadMedidaMaestraModel>> getUnidadesMaestras({
    String? categoria,
    bool soloPopulares = false,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (categoria != null) queryParameters['categoria'] = categoria;
    if (soloPopulares) queryParameters['soloPopulares'] = 'true';

    final response = await _dioClient.get(
      '/catalogos/unidades-maestras',
      queryParameters: queryParameters,
    );

    if (response.data is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    return (response.data as List)
        .map((json) => UnidadMedidaMaestraModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene las unidades de medida activadas para una empresa
  ///
  /// GET /api/catalogos/unidades/empresa/:empresaId
  Future<List<EmpresaUnidadMedidaModel>> getUnidadesEmpresa(String empresaId) async {
    final response = await _dioClient.get(
      '/catalogos/unidades/empresa/$empresaId',
    );

    if (response.data is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    return (response.data as List)
        .map((json) => EmpresaUnidadMedidaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Activa una unidad de medida para una empresa
  ///
  /// POST /api/catalogos/unidades/activar
  Future<EmpresaUnidadMedidaModel> activarUnidad({
    required String empresaId,
    String? unidadMaestraId,
    String? nombrePersonalizado,
    String? simboloPersonalizado,
    String? codigoPersonalizado,
    String? descripcion,
    String? nombreLocal,
    String? simboloLocal,
    int? orden,
  }) async {
    final data = <String, dynamic>{
      'empresaId': empresaId,
    };

    if (unidadMaestraId != null) data['unidadMaestraId'] = unidadMaestraId;
    if (nombrePersonalizado != null) data['nombrePersonalizado'] = nombrePersonalizado;
    if (simboloPersonalizado != null) data['simboloPersonalizado'] = simboloPersonalizado;
    if (codigoPersonalizado != null) data['codigoPersonalizado'] = codigoPersonalizado;
    if (descripcion != null) data['descripcion'] = descripcion;
    if (nombreLocal != null) data['nombreLocal'] = nombreLocal;
    if (simboloLocal != null) data['simboloLocal'] = simboloLocal;
    if (orden != null) data['orden'] = orden;

    final response = await _dioClient.post(
      '/catalogos/unidades/activar',
      data: data,
    );

    return EmpresaUnidadMedidaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Desactiva una unidad de medida de una empresa
  ///
  /// DELETE /api/catalogos/unidades/empresa/:empresaId/:unidadId
  Future<void> desactivarUnidad({
    required String empresaId,
    required String unidadId,
  }) async {
    await _dioClient.delete(
      '/catalogos/unidades/empresa/$empresaId/$unidadId',
    );
  }

  /// Activa las unidades de medida populares para una empresa
  ///
  /// POST /api/catalogos/unidades/activar-populares
  Future<List<EmpresaUnidadMedidaModel>> activarUnidadesPopulares(String empresaId) async {
    final response = await _dioClient.post(
      '/catalogos/unidades/activar-populares',
      data: {'empresaId': empresaId},
    );

    // El backend devuelve un objeto con estructura { unidades: [...], total: N }
    final data = response.data as Map<String, dynamic>;
    final unidades = data['unidades'] as List;

    return unidades
        .map((json) => EmpresaUnidadMedidaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
