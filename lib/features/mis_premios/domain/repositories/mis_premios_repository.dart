import '../../../../core/utils/resource.dart';
import '../entities/premio_cliente.dart';

abstract class MisPremiosRepository {
  Future<Resource<List<PremioCliente>>> getMisPremios();
  Future<Resource<PremioCliente>> getMiPremio(String id);

  /// El ganador indica su agencia de recojo (solo antes del despacho).
  Future<Resource<void>> elegirAgencia({
    required String premioId,
    required String agenciaNombre,
    String? destinoDepartamento,
    String? destinoProvincia,
    String? agenciaDireccion,
  });
}
