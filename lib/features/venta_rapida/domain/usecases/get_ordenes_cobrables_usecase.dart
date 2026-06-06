import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/orden_cobrable.dart';
import '../repositories/venta_rapida_repository.dart';

/// Lista las órdenes de servicio cobrables desde Venta Rápida:
/// REPARADO/LISTO_ENTREGA con saldo pendiente > 0 y sin venta vinculada.
/// `search` filtra por código, cliente (nombre/doc) o equipo.
@lazySingleton
class GetOrdenesCobrablesUseCase {
  final VentaRapidaRepository _repository;

  GetOrdenesCobrablesUseCase(this._repository);

  Future<Resource<List<OrdenCobrable>>> call({String? search}) {
    return _repository.getOrdenesCobrables(search: search);
  }
}
