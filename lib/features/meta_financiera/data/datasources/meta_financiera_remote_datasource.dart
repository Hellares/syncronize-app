import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/meta_financiera_model.dart';

@lazySingleton
class MetaFinancieraRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/metas-financieras';

  MetaFinancieraRemoteDataSource(this._dioClient);

  Future<List<MetaFinancieraModel>> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => MetaFinancieraModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MetaFinancieraModel> crear({
    required String tipo,
    required String nombre,
    required double montoMeta,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _dioClient.post(_basePath, data: {
      'tipo': tipo,
      'nombre': nombre,
      'montoMeta': montoMeta,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
    });
    return MetaFinancieraModel.fromJson(response.data as Map<String, dynamic>);
  }
}
