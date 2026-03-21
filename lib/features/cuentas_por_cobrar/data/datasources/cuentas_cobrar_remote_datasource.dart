import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cuenta_cobrar_model.dart';

@lazySingleton
class CuentasCobrarRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/cuentas-por-cobrar';

  CuentasCobrarRemoteDataSource(this._dioClient);

  Future<List<CuentaCobrarModel>> listar({String? estado}) async {
    final queryParams = <String, dynamic>{};
    if (estado != null) queryParams['estado'] = estado;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => CuentaCobrarModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenCuentasCobrarModel> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    return ResumenCuentasCobrarModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
