import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/cuentas_pagar_repository.dart';

@injectable
class RegistrarPagoCuentaPagarUseCase {
  final CuentasPagarRepository _repository;
  RegistrarPagoCuentaPagarUseCase(this._repository);

  Future<Resource<void>> call(
    String compraId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? bancoDestino,
    String? cuentaDestino,
    String? comprobanteUrl,
  }) {
    return _repository.registrarPago(
      compraId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
      bancoDestino: bancoDestino,
      cuentaDestino: cuentaDestino,
      comprobanteUrl: comprobanteUrl,
    );
  }
}
