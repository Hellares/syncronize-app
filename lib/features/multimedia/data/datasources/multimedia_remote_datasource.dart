import '../../../../core/network/dio_client.dart';
import '../models/archivo_empresa_model.dart';

class MultimediaRemoteDataSource {
  final DioClient _dioClient;

  MultimediaRemoteDataSource(this._dioClient);

  Future<({List<ArchivoEmpresaModel> data, int total, int totalPages})> getArchivos({
    required String empresaId,
    String? tipoArchivo,
    String? entidadTipo,
    int page = 1,
    int limit = 50,
    String orderBy = 'recientes',
  }) async {
    final params = <String, String>{
      'empresaId': empresaId,
      'page': '$page',
      'limit': '$limit',
      'orderBy': orderBy,
    };
    if (tipoArchivo != null) params['tipoArchivo'] = tipoArchivo;
    if (entidadTipo != null) params['entidadTipo'] = entidadTipo;

    final response = await _dioClient.get(
      '/storage/galeria',
      queryParameters: params,
    );

    final json = response.data as Map<String, dynamic>;
    final data = (json['data'] as List)
        .map((item) => ArchivoEmpresaModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return (
      data: data,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  Future<GaleriaStatsModel> getStats(String empresaId) async {
    final response = await _dioClient.get(
      '/storage/galeria/stats',
      queryParameters: {'empresaId': empresaId},
    );
    return GaleriaStatsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteArchivo(String archivoId, String empresaId) async {
    await _dioClient.delete(
      '/storage/$archivoId',
      queryParameters: {'empresaId': empresaId},
    );
  }
}
