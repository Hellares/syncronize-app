import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/configuracion_facturacion.dart';
import '../models/configuracion_facturacion_model.dart';

@lazySingleton
class ConfiguracionFacturacionRemoteDataSource {
  final DioClient _dioClient;
  static const _basePath = '/sunat/configuracion';

  ConfiguracionFacturacionRemoteDataSource(this._dioClient);

  Future<ConfiguracionFacturacionModel> getConfiguracion() async {
    final response = await _dioClient.get(_basePath);
    return ConfiguracionFacturacionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ConfiguracionFacturacionModel> updateConfiguracion(
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(_basePath, data: data);
    return ConfiguracionFacturacionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ResultadoProbarConexionModel> probarConexion({
    required ProveedorFacturacion proveedorActivo,
    required String proveedorRuta,
    required String proveedorToken,
    Map<String, dynamic>? proveedorConfig,
  }) async {
    final body = <String, dynamic>{
      'proveedorActivo': proveedorActivo.value,
      'proveedorRuta': proveedorRuta,
      'proveedorToken': proveedorToken,
      if (proveedorConfig != null) 'proveedorConfig': proveedorConfig,
    };
    final response = await _dioClient.post('$_basePath/probar', data: body);
    return ResultadoProbarConexionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
