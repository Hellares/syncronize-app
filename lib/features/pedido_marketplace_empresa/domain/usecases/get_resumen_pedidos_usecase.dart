import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pedido_empresa.dart';
import '../repositories/pedido_empresa_repository.dart';

@injectable
class GetResumenPedidosUseCase {
  final PedidoEmpresaRepository _repository;
  GetResumenPedidosUseCase(this._repository);

  Future<Resource<ResumenPedidos>> call() {
    return _repository.getResumen();
  }
}
