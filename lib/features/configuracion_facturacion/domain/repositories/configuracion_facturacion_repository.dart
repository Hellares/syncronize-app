import '../../../../core/utils/resource.dart';
import '../entities/configuracion_facturacion.dart';

abstract class ConfiguracionFacturacionRepository {
  Future<Resource<ConfiguracionFacturacion>> getConfiguracion();

  Future<Resource<ConfiguracionFacturacion>> updateConfiguracion(
    Map<String, dynamic> data,
  );

  Future<Resource<ResultadoProbarConexion>> probarConexion({
    required ProveedorFacturacion proveedorActivo,
    required String proveedorRuta,
    required String proveedorToken,
    Map<String, dynamic>? proveedorConfig,
  });
}
