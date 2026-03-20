import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pedido_marketplace.dart';
import '../repositories/mis_pedidos_repository.dart';

@injectable
class GetMisPedidosUseCase {
  final MisPedidosRepository _repository;

  GetMisPedidosUseCase(this._repository);

  Future<Resource<List<PedidoMarketplace>>> call({
    EstadoPedidoMarketplace? estado,
  }) {
    return _repository.getMisPedidos(estado: estado);
  }
}
