import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/pedido_empresa_repository.dart';

@injectable
class ValidarPagoUseCase {
  final PedidoEmpresaRepository _repository;
  ValidarPagoUseCase(this._repository);

  Future<Resource<void>> call(
    String id, {
    required String accion,
    String? motivoRechazo,
  }) {
    return _repository.validarPago(id, accion: accion, motivoRechazo: motivoRechazo);
  }
}
