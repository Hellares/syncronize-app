import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_pagar.dart';

abstract class CuentasPagarRepository {
  Future<Resource<List<CuentaPorPagar>>> listar({String? estado});
  Future<Resource<ResumenCuentasPagar>> getResumen();

  /// Registra un pago a proveedor sobre una compra (CxP).
  Future<Resource<void>> registrarPago(
    String compraId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? bancoDestino,
    String? cuentaDestino,
  });
}
