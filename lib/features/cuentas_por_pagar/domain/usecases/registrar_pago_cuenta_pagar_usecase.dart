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
    String? fuente,
    String? bancoId,
    /// TC del dia del pago. Obligatorio si la fuente y la deuda no comparten
    /// moneda (una factura en dolares pagada desde una caja en soles).
    double? tipoCambio,
    /// Lo que este pago CANCELA de la deuda, en la moneda de la COMPRA.
    /// `monto` sigue siendo lo que sale de la fuente.
    double? montoAplicado,
  }) {
    return _repository.registrarPago(
      compraId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
      bancoDestino: bancoDestino,
      cuentaDestino: cuentaDestino,
      comprobanteUrl: comprobanteUrl,
      fuente: fuente,
      bancoId: bancoId,
      tipoCambio: tipoCambio,
      montoAplicado: montoAplicado,
    );
  }
}
