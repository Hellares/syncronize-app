import 'package:equatable/equatable.dart';
import 'venta.dart';

/// Entity que representa un pago registrado en una venta
class PagoVenta extends Equatable {
  final String id;
  final String ventaId;
  final MetodoPago metodoPago;
  final double monto;
  final String? referencia;
  final String? banco; // Entidad financiera (TARJETA/TRANSFERENCIA) — Ley 28194
  final DateTime fechaPago;

  // Pago en moneda extranjera
  final String? monedaOriginal;
  final double? montoOriginal;
  final double? tipoCambio;

  /// Cuota a la que se imputó. En un abono que cubre VARIAS cuotas el backend
  /// guarda solo la PRIMERA (`imputarEnCuotas` reparte en cascada), así que
  /// sirve como referencia, no como detalle completo.
  final String? cuotaVentaId;

  /// Desglose de la imputación (créditos con interés/mora).
  final double montoPrincipal;
  final double montoInteres;
  final double montoMora;

  /// Abono anulado: no cuenta para el saldo de la venta.
  final bool anulado;

  /// De dónde entró la plata: TESORERIA | CAJA | BANCO. Solo la setean los
  /// abonos de crédito vía CxC; los cobros POS quedan en null.
  final String? fuente;

  const PagoVenta({
    required this.id,
    required this.ventaId,
    required this.metodoPago,
    required this.monto,
    this.referencia,
    this.banco,
    required this.fechaPago,
    this.monedaOriginal,
    this.montoOriginal,
    this.tipoCambio,
    this.cuotaVentaId,
    this.montoPrincipal = 0,
    this.montoInteres = 0,
    this.montoMora = 0,
    this.anulado = false,
    this.fuente,
  });

  bool get esEnDolares => monedaOriginal == 'USD';

  /// Tiene desglose que valga la pena mostrar (crédito con interés o mora).
  bool get tieneDesglose => montoInteres > 0.005 || montoMora > 0.005;

  @override
  List<Object?> get props => [
        id, ventaId, metodoPago, monto, referencia, banco, fechaPago,
        monedaOriginal, cuotaVentaId, montoPrincipal, montoInteres, montoMora,
        anulado, fuente,
      ];
}
