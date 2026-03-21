import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pedido_empresa.dart';
import '../repositories/pedido_empresa_repository.dart';

@injectable
class GetPedidosEmpresaUseCase {
  final PedidoEmpresaRepository _repository;
  GetPedidosEmpresaUseCase(this._repository);

  Future<Resource<List<PedidoMarketplaceEmpresa>>> call({
    String? estado,
    String? search,
  }) {
    return _repository.listarPedidos(estado: estado, search: search);
  }
}
