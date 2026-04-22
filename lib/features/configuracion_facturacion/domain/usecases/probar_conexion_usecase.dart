import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_facturacion.dart';
import '../repositories/configuracion_facturacion_repository.dart';

@lazySingleton
class ProbarConexionUseCase {
  final ConfiguracionFacturacionRepository _repository;

  ProbarConexionUseCase(this._repository);

  Future<Resource<ResultadoProbarConexion>> call({
    required ProveedorFacturacion proveedorActivo,
    required String proveedorRuta,
    required String proveedorToken,
    Map<String, dynamic>? proveedorConfig,
  }) {
    return _repository.probarConexion(
      proveedorActivo: proveedorActivo,
      proveedorRuta: proveedorRuta,
      proveedorToken: proveedorToken,
      proveedorConfig: proveedorConfig,
    );
  }
}
