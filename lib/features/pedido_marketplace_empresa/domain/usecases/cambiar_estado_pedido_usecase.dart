import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/pedido_empresa_repository.dart';

@injectable
class CambiarEstadoPedidoUseCase {
  final PedidoEmpresaRepository _repository;
  CambiarEstadoPedidoUseCase(this._repository);

  Future<Resource<void>> call(
    String id, {
    required String estado,
    String? codigoSeguimiento,
  }) {
    return _repository.cambiarEstado(id, estado: estado, codigoSeguimiento: codigoSeguimiento);
  }
}
