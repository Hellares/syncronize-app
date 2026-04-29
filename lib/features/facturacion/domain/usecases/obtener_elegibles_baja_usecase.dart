import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/comprobante_elegible_baja.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class ObtenerElegiblesBajaUseCase {
  final FacturacionRepository _repository;
  ObtenerElegiblesBajaUseCase(this._repository);

  Future<Resource<List<ComprobanteElegibleBaja>>> call({
    required String sedeId,
    required String fechaReferencia,
  }) {
    return _repository.obtenerElegiblesBaja(
      sedeId: sedeId,
      fechaReferencia: fechaReferencia,
    );
  }
}
