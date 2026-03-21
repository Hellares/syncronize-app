import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pedido_empresa.dart';
import '../repositories/pedido_empresa_repository.dart';

@injectable
class GetDetallePedidoEmpresaUseCase {
  final PedidoEmpresaRepository _repository;
  GetDetallePedidoEmpresaUseCase(this._repository);

  Future<Resource<PedidoMarketplaceEmpresa>> call(String id) {
    return _repository.detallePedido(id);
  }
}
