import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/mis_pedidos_repository.dart';

@injectable
class ConfirmarRecepcionUseCase {
  final MisPedidosRepository _repository;

  ConfirmarRecepcionUseCase(this._repository);

  Future<Resource<void>> call(String pedidoId) {
    return _repository.confirmarRecepcion(pedidoId);
  }
}
