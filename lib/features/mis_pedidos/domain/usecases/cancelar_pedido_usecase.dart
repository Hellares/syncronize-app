import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/mis_pedidos_repository.dart';

@injectable
class CancelarPedidoUseCase {
  final MisPedidosRepository _repository;

  CancelarPedidoUseCase(this._repository);

  Future<Resource<void>> call(String pedidoId) {
    return _repository.cancelarPedido(pedidoId);
  }
}
