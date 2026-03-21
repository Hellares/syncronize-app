import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/flujo_proyectado_model.dart';

@lazySingleton
class FlujoProyectadoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/flujo-proyectado';

  FlujoProyectadoRemoteDataSource(this._dioClient);

  Future<List<PeriodoFlujoModel>> getProyeccion({int? meses}) async {
    final queryParams = <String, dynamic>{};
    if (meses != null) queryParams['meses'] = meses;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => PeriodoFlujoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
