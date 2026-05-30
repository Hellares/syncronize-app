/// Una línea de combo para el prorrateo: su valor regular (precioUnitario ×
/// cantidad) y si está en liquidación.
typedef LineaCombo = ({double regular, bool enLiquidacion});

/// Prorratea el descuento de un combo entre sus líneas según la regla de
/// pricing, devolviendo el descuento del COMBO por línea (paralelo a
/// [lineas]). El descuento manual del cajero se apila aparte por el caller.
///
/// Reglas:
/// - Objetivo de precio del combo:
///   - `calculado`: suma de componentes (sin descuento).
///   - `calculadoConDescuento`: las líneas en liquidación a precio pleno y el
///     resto con el % del combo → `regularLiq + regularNoLiq·(1−%)`.
///   - `fijo`: [objetivoFijo] (en su defecto, la suma → sin descuento).
/// - **Liquidación gana sola**: las líneas en liquidación quedan con descuento
///   0 (venden a precio de remate) y se EXCLUYEN del reparto; el descuento del
///   combo se reparte solo entre las líneas sin liquidación, proporcional a su
///   valor regular. La última línea sin liquidación compensa el redondeo para
///   que la suma cuadre.
List<double> prorratearDescuentoCombo({
  required List<LineaCombo> lineas,
  required String tipo,
  double descuentoPct = 0,
  double? objetivoFijo,
}) {
  if (lineas.isEmpty) return const [];

  final regularTotal = lineas.fold<double>(0, (s, l) => s + l.regular);
  final regularNoLiq = lineas
      .where((l) => !l.enLiquidacion)
      .fold<double>(0, (s, l) => s + l.regular);
  final regularLiq = regularTotal - regularNoLiq;

  double objetivo;
  switch (tipo) {
    case 'calculadoConDescuento':
      objetivo = regularLiq + regularNoLiq * (1 - descuentoPct / 100);
      break;
    case 'fijo':
      objetivo = objetivoFijo ?? regularTotal;
      break;
    default: // calculado
      objetivo = regularTotal;
  }
  objetivo = objetivo.clamp(0, regularTotal).toDouble();
  // El descuento solo puede salir de las líneas sin liquidación.
  final descuentoTotal =
      (regularTotal - objetivo).clamp(0, regularNoLiq).toDouble();
  final ultimoNoLiq = lineas.lastIndexWhere((l) => !l.enLiquidacion);

  var acumulado = 0.0;
  final out = <double>[];
  for (var i = 0; i < lineas.length; i++) {
    final l = lineas[i];
    double descCombo;
    if (l.enLiquidacion) {
      descCombo = 0;
    } else if (i == ultimoNoLiq) {
      descCombo = descuentoTotal - acumulado;
    } else if (regularNoLiq > 0) {
      descCombo = (descuentoTotal * (l.regular / regularNoLiq) * 100).round() /
          100.0;
    } else {
      descCombo = 0;
    }
    if (descCombo < 0) descCombo = 0;
    acumulado += descCombo;
    out.add(descCombo);
  }
  return out;
}
