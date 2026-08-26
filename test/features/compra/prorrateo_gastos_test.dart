import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/prorrateo_gastos.dart';

/// Los mismos casos que `CompraService.prorratearGastos` tiene en su spec.
/// Si acá pasa algo distinto que allá, el formulario le promete al usuario un
/// costo que el kardex no va a guardar.
void main() {
  LineaProrrateo linea(double total,
          {double cantidad = 1, bool mueveStock = true}) =>
      (total: total, cantidad: cantidad, mueveStock: mueveStock);
  GastoProrrateo gasto(double monto,
          {bool prorratea = true, bool porCantidad = false}) =>
      (monto: monto, prorratea: prorratea, porCantidad: porCantidad);

  group('prorratearGastos — espejo del backend', () {
    test('reparte POR VALOR: el ítem caro absorbe más flete', () {
      final r = prorratearGastos(
        lineas: [linea(600), linea(300)],
        gastos: [gasto(50)],
      );

      expect(r[0], 33.33);
      expect(r[1], 16.67);
      expect(r[0]! + r[1]!, 50);
    });

    test('🔴 el costo por unidad del ejemplo del usuario: 63.33 y 15.83', () {
      // 10 u a S/60 (600) y 20 u a S/15 (300), con S/50 de movilidad.
      final r = prorratearGastos(
        lineas: [linea(600), linea(300)],
        gastos: [gasto(50)],
      );

      expect(((600 + r[0]!) / 10 * 100).round() / 100, 63.33);
      expect(((300 + r[1]!) / 20 * 100).round() / 100, 15.83);
    });

    test('cierra EXACTO aunque el reparto no sea divisible', () {
      final r = prorratearGastos(
        lineas: [linea(100), linea(100), linea(100)],
        gastos: [gasto(10)],
      );

      // 3.33 + 3.33 + 3.34: la última se lleva el resto del redondeo.
      expect(r.values.fold<double>(0, (s, v) => s + v), 10);
      expect(r[2], 3.34);
    });

    test('ignora los gastos con prorratea=false', () {
      final r = prorratearGastos(
        lineas: [linea(600), linea(300)],
        gastos: [gasto(50, prorratea: false)],
      );

      expect(r, isEmpty);
    });

    test('deja afuera las líneas que no mueven stock', () {
      final r = prorratearGastos(
        lineas: [linea(600), linea(300, mueveStock: false)],
        gastos: [gasto(50)],
      );

      expect(r[0], 50);
      expect(r.containsKey(1), isFalse);
    });

    test('sin líneas con stock no explota ni reparte', () {
      final r = prorratearGastos(
        lineas: [linea(600, mueveStock: false)],
        gastos: [gasto(50)],
      );

      expect(r, isEmpty);
    });

    test('compra en cero: reparte parejo en vez de dividir por cero', () {
      final r = prorratearGastos(
        lineas: [linea(0), linea(0)],
        gastos: [gasto(10)],
      );

      expect(r[0], 5);
      expect(r[1], 5);
    });

    test('varios gastos se acumulan sobre la misma línea', () {
      final r = prorratearGastos(
        lineas: [linea(600), linea(300)],
        gastos: [gasto(50), gasto(30)],
      );

      // 33.33 + 20 y 16.67 + 10, cada gasto cerrando exacto por su cuenta.
      expect(r[0], 53.33);
      expect(r[1], 26.67);
      expect(r[0]! + r[1]!, 80);
    });

    test('por CANTIDAD reparte por unidades, no por plata', () {
      // Lo barato es lo voluminoso: 100 unidades de S/1 y 1 de S/500.
      final r = prorratearGastos(
        lineas: [linea(100, cantidad: 100), linea(500, cantidad: 1)],
        gastos: [gasto(20, porCantidad: true)],
      );

      // Por cantidad, el bulto se lleva casi todo el flete...
      expect(r[0], 19.80);
      expect(r[1], 0.20);

      // ...al revés de lo que haría el criterio por valor.
      final porValor = prorratearGastos(
        lineas: [linea(100, cantidad: 100), linea(500, cantidad: 1)],
        gastos: [gasto(20)],
      );
      expect(porValor[0], 3.33);
      expect(porValor[1], 16.67);
    });

    test('🔴 por CANTIDAD la cantidad va en unidad ATÓMICA', () {
      // 10 sacos de 50 = 500 unidades atómicas, contra 20 sueltas. Pasando
      // "10" en vez de "500" el reparto se daría vuelta.
      final r = prorratearGastos(
        lineas: [linea(600, cantidad: 500), linea(300, cantidad: 20)],
        gastos: [gasto(52, porCantidad: true)],
      );

      expect(r[0], 50.00);
      expect(r[1], 2.00);
    });

    test('por CANTIDAD con todas las cantidades en cero reparte parejo', () {
      final r = prorratearGastos(
        lineas: [linea(600, cantidad: 0), linea(300, cantidad: 0)],
        gastos: [gasto(10, porCantidad: true)],
      );

      expect(r[0], 5);
      expect(r[1], 5);
    });

    test('un gasto en cero no mueve nada', () {
      final r = prorratearGastos(
        lineas: [linea(600)],
        gastos: [gasto(0)],
      );

      expect(r, isEmpty);
    });
  });
}
