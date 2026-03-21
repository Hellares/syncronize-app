import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cuenta_pagar_model.dart';

@lazySingleton
class CuentasPagarRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/cuentas-por-pagar';

  CuentasPagarRemoteDataSource(this._dioClient);

  Future<List<CuentaPagarModel>> listar({String? estado}) async {
    final queryParams = <String, dynamic>{};
    if (estado != null) queryParams['estado'] = estado;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => CuentaPagarModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenCuentasPagarModel> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    return ResumenCuentasPagarModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
