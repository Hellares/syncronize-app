import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/venta_rapida/domain/combo_prorrateo.dart';

/// Tests del prorrateo del descuento de un combo entre sus líneas
/// (`prorratearDescuentoCombo`). Verifica las reglas que tocamos:
///  - Objetivo por regla (calculado / calculadoConDescuento / fijo).
///  - Liquidación gana sola: excluida del reparto (descuento 0).
///  - La suma de los descuentos prorrateados cuadra (último no-liq compensa).
void main() {
  LineaCombo l(double regular, {bool liq = false}) =>
      (regular: regular, enLiquidacion: liq);

  double suma(List<double> xs) => xs.fold(0.0, (s, x) => s + x);

  group('prorratearDescuentoCombo', () {
    test('lista vacía → vacío', () {
      expect(prorratearDescuentoCombo(lineas: [], tipo: 'calculado'), isEmpty);
    });

    test('CALCULADO: sin descuento (todo 0)', () {
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10)],
        tipo: 'calculado',
      );
      expect(r, [0, 0]);
    });

    test('CALCULADO_CON_DESCUENTO 10%: reparte 5 proporcional → [4, 1]', () {
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10)], // total 50, 10% → desc 5
        tipo: 'calculadoConDescuento',
        descuentoPct: 10,
      );
      expect(r, [4.0, 1.0]);
      expect(suma(r), closeTo(5, 0.0001));
    });

    test('FIJO: objetivo 45 sobre regular 50 → desc 5 proporcional', () {
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10)],
        tipo: 'fijo',
        objetivoFijo: 45,
      );
      expect(suma(r), closeTo(5, 0.0001));
      expect(r[0], closeTo(4, 0.0001));
      expect(r[1], closeTo(1, 0.0001));
    });

    test('LIQUIDACIÓN gana sola: la línea liq queda en 0 y se excluye', () {
      // A 40 (no liq), B 10 (LIQ). 10% → objetivo = 10 + 40*0.9 = 46; desc 4
      // sale TODO de A; B no recibe descuento (vende a su precio de remate).
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10, liq: true)],
        tipo: 'calculadoConDescuento',
        descuentoPct: 10,
      );
      expect(r, [4.0, 0.0]);
    });

    test('FIJO con liquidación: el descuento sale solo de las no-liq', () {
      // A 40 (no liq), B 10 (LIQ). objetivo 45, regular 50 → desc 5, todo a A.
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10, liq: true)],
        tipo: 'fijo',
        objetivoFijo: 45,
      );
      expect(r, [5.0, 0.0]);
    });

    test('TODAS en liquidación: no hay de dónde descontar → todo 0', () {
      final r = prorratearDescuentoCombo(
        lineas: [l(40, liq: true), l(10, liq: true)],
        tipo: 'calculadoConDescuento',
        descuentoPct: 10,
      );
      expect(r, [0, 0]);
    });

    test('redondeo: la última línea no-liq compensa para que la suma cuadre', () {
      // 3x10 = 30; fijo objetivo 29 → desc 1. Reparto 0.33+0.33+0.34 = 1.00
      final r = prorratearDescuentoCombo(
        lineas: [l(10), l(10), l(10)],
        tipo: 'fijo',
        objetivoFijo: 29,
      );
      expect(suma(r), closeTo(1, 0.0001));
      expect(r[0], closeTo(0.33, 0.0001));
      expect(r[1], closeTo(0.33, 0.0001));
      expect(r[2], closeTo(0.34, 0.0001)); // compensa
    });

    test('FIJO con objetivo MAYOR que el regular: no genera descuento negativo', () {
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10)],
        tipo: 'fijo',
        objetivoFijo: 60, // > 50
      );
      expect(r, [0, 0]);
    });

    test('descuento del combo nunca supera el subtotal de las no-liq', () {
      // objetivo 0 (regalado) pero hay una línea liq que no se puede descontar:
      // el descuento se capa al regular de las no-liq.
      final r = prorratearDescuentoCombo(
        lineas: [l(40), l(10, liq: true)],
        tipo: 'fijo',
        objetivoFijo: 0,
      );
      // máximo descontable = 40 (regular no-liq); B liq = 0.
      expect(r[0], closeTo(40, 0.0001));
      expect(r[1], 0);
    });
  });
}
