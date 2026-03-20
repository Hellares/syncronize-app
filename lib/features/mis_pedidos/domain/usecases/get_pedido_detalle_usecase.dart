import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pedido_marketplace.dart';
import '../repositories/mis_pedidos_repository.dart';

@injectable
class GetPedidoDetalleUseCase {
  final MisPedidosRepository _repository;

  GetPedidoDetalleUseCase(this._repository);

  Future<Resource<PedidoMarketplace>> call(String id) {
    return _repository.getMiPedidoDetalle(id);
  }
}
