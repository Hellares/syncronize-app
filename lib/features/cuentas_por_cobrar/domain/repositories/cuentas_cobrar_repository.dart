import '../../../../core/utils/resource.dart';
import '../entities/cuenta_por_cobrar.dart';
import '../entities/deposito_cliente.dart';
import '../entities/estado_cuenta_cliente.dart';

abstract class CuentasCobrarRepository {
  Future<Resource<List<CuentaPorCobrar>>> listar({String? estado, String? sedeId});
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

  /// Estado de cuenta de un cliente (ventas a crédito + abonos + saldo).
  Future<Resource<EstadoCuentaCliente>> getEstadoCuentaCliente({
    String? clienteId,
    String? clienteEmpresaId,
  });

  /// Propuesta de reparto de `monto` entre las ventas con deuda del cliente.
  Future<Resource<SugerenciaReparto>> sugerirReparto({
    String? clienteId,
    String? clienteEmpresaId,
    required double monto,
  });

  /// Registra un depósito del cliente (y lo reparte, si vienen líneas).
  Future<Resource<void>> registrarDeposito({
    String? clienteId,
    String? clienteEmpresaId,
    required double monto,
    required String metodoPago,
    String? referencia,
    String? fuente,
    String? bancoId,
    List<LineaReparto> lineas = const [],
  });

  /// Reparte el saldo a favor del cliente entre sus ventas.
  Future<Resource<void>> aplicarSaldoAFavor({
    String? clienteId,
    String? clienteEmpresaId,
    required List<LineaReparto> lineas,
  });
}
