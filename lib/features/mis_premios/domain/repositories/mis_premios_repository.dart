import '../../../../core/utils/resource.dart';
import '../entities/premio_cliente.dart';

abstract class MisPremiosRepository {
  Future<Resource<List<PremioCliente>>> getMisPremios();
  Future<Resource<PremioCliente>> getMiPremio(String id);
}
