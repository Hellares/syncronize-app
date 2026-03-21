import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

@injectable
class ConfirmarPedidoUseCase {
  final CheckoutRepository _repository;
  ConfirmarPedidoUseCase(this._repository);

  Future<Resource<CheckoutResult>> call({
    required String metodoPago,
    String? direccionEnvioId,
    String? notasComprador,
    required List<Map<String, dynamic>> entregaPorEmpresa,
  }) {
    return _repository.confirmarPedido(
      metodoPago: metodoPago,
      direccionEnvioId: direccionEnvioId,
      notasComprador: notasComprador,
      entregaPorEmpresa: entregaPorEmpresa,
    );
  }
}
