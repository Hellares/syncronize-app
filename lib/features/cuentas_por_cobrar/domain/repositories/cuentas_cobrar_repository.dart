import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_cobrar.dart';

abstract class CuentasCobrarRepository {
  Future<Resource<List<CuentaPorCobrar>>> listar({String? estado});
  Future<Resource<ResumenCuentasCobrar>> getResumen();

  /// Registra un abono del cliente sobre una venta a crédito.
  Future<Resource<void>> registrarAbono(
    String ventaId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? fuente,
    String? bancoId,
    String? banco,
  });

  /// Anula un abono (revierte el ingreso y recomputa las cuotas).
  Future<Resource<void>> anularAbono(String pagoId, {String? motivo});
}
