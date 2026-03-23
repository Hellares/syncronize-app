/// Calculadora de cuotas que replica exactamente la lógica del backend
/// (venta.service.ts → generarCuotas)
///
/// IMPORTANTE: Si se modifica la lógica en el backend, actualizar aquí también.
/// El backend es la fuente de verdad — esta función es solo para preview en UI.
class CuotaCalculator {
  CuotaCalculator._();

  /// Calcula el preview de cuotas para mostrar en UI.
  ///
  /// Replica exactamente la lógica de backend/src/venta/venta.service.ts → generarCuotas()
  /// - [montoCredito]: monto base del crédito (sin interés)
  /// - [numeroCuotas]: cantidad de cuotas
  /// - [porcentajeInteres]: % de interés sobre el montoCredito (ej: 5.0 = 5%)
  /// - [plazoDias]: plazo total en días (default: numeroCuotas * 30)
  /// - [fechaBase]: fecha desde la cual calcular vencimientos
  static List<CuotaPreview> calcular({
    required double montoCredito,
    required int numeroCuotas,
    double porcentajeInteres = 0,
    int? plazoDias,
    DateTime? fechaBase,
  }) {
    if (montoCredito <= 0 || numeroCuotas <= 0) return [];

    final fecha = fechaBase ?? DateTime.now();
    final plazo = plazoDias ?? (numeroCuotas * 30);

    // Misma fórmula que backend
    final montoInteresTotal = _round2(montoCredito * (porcentajeInteres / 100));
    final totalConInteres = montoCredito + montoInteresTotal;

    final intervaloDias = plazo ~/ numeroCuotas;
    final montoCuota = (totalConInteres / numeroCuotas * 100).floor() / 100;
    final resto = _round2(totalConInteres - montoCuota * numeroCuotas);

    // Interés distribuido proporcionalmente
    final interesPorCuota = numeroCuotas > 0
        ? (montoInteresTotal / numeroCuotas * 100).floor() / 100
        : 0.0;
    final restoInteres = _round2(montoInteresTotal - interesPorCuota * numeroCuotas);

    return List.generate(numeroCuotas, (i) {
      final numero = i + 1;
      final esUltima = numero == numeroCuotas;
      final monto = esUltima ? montoCuota + resto : montoCuota;
      final interesCuota = esUltima ? interesPorCuota + restoInteres : interesPorCuota;
      final principalCuota = _round2(monto - interesCuota);

      final fechaVencimiento = fecha.add(Duration(days: intervaloDias * numero));

      return CuotaPreview(
        numero: numero,
        monto: monto,
        montoPrincipal: principalCuota,
        montoInteres: interesCuota,
        fechaVencimiento: fechaVencimiento,
      );
    });
  }

  /// Calcula el monto total de interés
  static double calcularInteres(double montoCredito, double porcentajeInteres) {
    return _round2(montoCredito * (porcentajeInteres / 100));
  }

  /// Calcula el total con interés
  static double calcularTotalConInteres(double montoCredito, double porcentajeInteres) {
    return montoCredito + calcularInteres(montoCredito, porcentajeInteres);
  }

  static double _round2(double value) {
    return (value * 100).round() / 100;
  }
}

/// Representación de una cuota para preview en UI
class CuotaPreview {
  final int numero;
  final double monto;
  final double montoPrincipal;
  final double montoInteres;
  final DateTime fechaVencimiento;

  const CuotaPreview({
    required this.numero,
    required this.monto,
    required this.montoPrincipal,
    required this.montoInteres,
    required this.fechaVencimiento,
  });
}
