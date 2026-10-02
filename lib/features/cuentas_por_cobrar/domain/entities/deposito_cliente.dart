// Depósitos del cliente sin repartir y su saldo a favor.
//
// El cliente paga un monto SIN decir qué compras cancela (transfiere S/ 4,000
// contra S/ 5,000 de deuda en varias ventas). La plata entra una vez, la
// tienda la reparte entre las ventas, y lo que no alcanza para nada queda
// como saldo a favor. Mapea `GET /cuentas-por-cobrar/depositos/sugerencia`.

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
int _i(dynamic v) => v == null ? 0 : (v as num).toInt();
DateTime? _f(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

/// Cómo propone el backend repartir un monto: cuotas COMPLETAS, de la que
/// vence primero a la última. Lo que no entra en ninguna es `sobrante`.
class SugerenciaReparto {
  /// Lo que el cliente ya tenía a favor antes de este depósito.
  final double saldoAFavor;
  final double deuda;
  final double sugerido;
  final double sobrante;
  final List<VentaReparto> ventas;

  const SugerenciaReparto({
    required this.saldoAFavor,
    required this.deuda,
    required this.sugerido,
    required this.sobrante,
    required this.ventas,
  });

  factory SugerenciaReparto.fromJson(Map<String, dynamic> j) => SugerenciaReparto(
        saldoAFavor: _d(j['saldoAFavor']),
        deuda: _d(j['deuda']),
        sugerido: _d(j['sugerido']),
        sobrante: _d(j['sobrante']),
        ventas: (j['ventas'] as List<dynamic>? ?? [])
            .map((e) => VentaReparto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Una venta con deuda y cuánto se propone aplicarle.
class VentaReparto {
  final String ventaId;
  final String codigo;
  final DateTime? fechaVenta;
  final double saldo;
  final int? proximaCuotaNumero;
  final double proximaCuotaMonto;
  final DateTime? proximaCuotaVence;
  final double sugerido;

  const VentaReparto({
    required this.ventaId,
    required this.codigo,
    this.fechaVenta,
    required this.saldo,
    this.proximaCuotaNumero,
    required this.proximaCuotaMonto,
    this.proximaCuotaVence,
    required this.sugerido,
  });

  factory VentaReparto.fromJson(Map<String, dynamic> j) {
    final cuota = j['proximaCuota'] as Map<String, dynamic>? ?? const {};
    return VentaReparto(
      ventaId: j['ventaId'] as String? ?? '',
      codigo: j['codigo'] as String? ?? '',
      fechaVenta: _f(j['fechaVenta']),
      saldo: _d(j['saldo']),
      proximaCuotaNumero: cuota['numero'] != null ? _i(cuota['numero']) : null,
      proximaCuotaMonto: _d(cuota['monto']),
      proximaCuotaVence: _f(cuota['fechaVencimiento']),
      sugerido: _d(j['sugerido']),
    );
  }
}

/// Cuánto del depósito (o del saldo a favor) va a UNA venta.
class LineaReparto {
  final String ventaId;
  final double monto;
  const LineaReparto({required this.ventaId, required this.monto});

  Map<String, dynamic> toJson() => {'ventaId': ventaId, 'monto': monto};
}
