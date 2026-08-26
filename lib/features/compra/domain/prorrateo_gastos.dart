/// Reparto de los gastos de la factura (flete, movilidad) entre las líneas
/// de la compra, para PREVISUALIZARLO mientras se carga.
///
/// 🔴 Es un espejo de `CompraService.prorratearGastos` del backend, que es
/// quien reparte de verdad al confirmar la compra. Si las dos cuentas se
/// separan, el formulario promete un costo y el kardex guarda otro: cualquier
/// cambio acá tiene que ir junto con el de allá.
library;

double round2(double v) => (v * 100).round() / 100;

/// Una línea de la compra a efectos del reparto.
///
/// [total] es el total de la línea CON IGV —la misma cifra que el backend usa
/// como peso y como base del `precioCosto`—.
///
/// 🔴 [cantidad] va en unidad ATÓMICA, que es la que el backend termina
/// guardando en `CompraDetalle.cantidad`: 10 sacos con factor 50 pesan 500,
/// no 10. Pasar la cantidad de la unidad de compra reparte cualquier cosa.
///
/// [mueveStock] es false para un servicio suelto: no hay costo que subir.
typedef LineaProrrateo = ({double total, double cantidad, bool mueveStock});

/// Un gasto de la factura. Solo reparten los que tienen [prorratea]: un flete
/// sube el costo, un interés por pagar a 30 días no.
///
/// [porCantidad] es el criterio `CANTIDAD` del backend: reparte por unidades
/// en vez de por plata, que es lo que corresponde cuando lo barato es lo
/// voluminoso (el flete lo cobran por bulto, no por el valor del bulto).
typedef GastoProrrateo = ({double monto, bool prorratea, bool porCantidad});

/// Cuánto gasto le toca a cada línea, indexado por su posición en [lineas].
///
/// Las líneas que no mueven stock quedan afuera. Si NINGUNA mueve stock no se
/// reparte nada —el gasto igual suma al total de la compra—.
///
/// 🔴 Cierra EXACTO: la última línea elegible se lleva el resto del redondeo,
/// así lo repartido suma centavo a centavo el monto del gasto. Repartiendo por
/// proporción a secas, los centavos sueltos aparecerían después como margen
/// fantasma.
Map<int, double> prorratearGastos({
  required List<LineaProrrateo> lineas,
  required List<GastoProrrateo> gastos,
}) {
  final reparto = <int, double>{};
  final elegibles = lineas
      .asMap()
      .entries
      .where((e) => e.value.mueveStock)
      .toList();
  if (elegibles.isEmpty) return reparto;

  for (final gasto in gastos) {
    if (!gasto.prorratea || gasto.monto <= 0) continue;

    double peso(LineaProrrateo l) => gasto.porCantidad ? l.cantidad : l.total;
    final totalPeso =
        elegibles.fold(0.0, (sum, e) => sum + peso(e.value));
    // Todo en cero (una compra en 0, o cantidades en 0): se reparte parejo en
    // vez de dividir por cero.
    final parejo = totalPeso <= 0;

    var acumulado = 0.0;
    for (var i = 0; i < elegibles.length; i++) {
      final e = elegibles[i];
      final esUltima = i == elegibles.length - 1;
      final parte = esUltima
          ? round2(gasto.monto - acumulado)
          : round2(parejo
              ? gasto.monto / elegibles.length
              : gasto.monto * peso(e.value) / totalPeso);
      acumulado = round2(acumulado + parte);
      reparto[e.key] = round2((reparto[e.key] ?? 0) + parte);
    }
  }
  return reparto;
}
