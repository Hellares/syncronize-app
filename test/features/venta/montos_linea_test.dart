import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// Los montos de una línea del carrito.
///
/// 🔴 Estas cuentas tienen que dar EXACTAMENTE lo mismo que
/// `backend/src/venta/utils/montos-linea.util.ts`. El carrito muestra y cobra
/// un monto que el servidor recalcula: si difieren en un centavo, el pago entra
/// corto y la venta queda impaga. Pasó de verdad con VTA-SED-00000806.
void main() {
  VentaDetalleInput linea({
    required double cantidad,
    required double precioUnitario,
    double descuento = 0,
    double icbper = 0,
    double porcentajeIGV = 18,
    bool precioIncluyeIgv = true,
  }) {
    return VentaDetalleInput(
      descripcion: 'X',
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      descuento: descuento,
      icbper: icbper,
      porcentajeIGV: porcentajeIGV,
      precioIncluyeIgv: precioIncluyeIgv,
    );
  }

  void cuadra(VentaDetalleInput l) {
    final suma = double.parse(
        (l.subtotal + l.igv + l.icbper).toStringAsFixed(2));
    expect(suma, l.total, reason: 'subtotal + igv + icbper debe dar el total');
  }

  group('el caso que rompió: 1237 g × 0.015 = 18.555', () {
    final l = linea(cantidad: 1237, precioUnitario: 0.015);

    test('el total redondea a centavos, igual que el backend', () {
      expect(l.total, 18.56);
    });

    test('las partes suman el total', () {
      cuadra(l);
      expect(l.subtotal, 15.72);
      expect(l.igv, 2.84);
    });
  });

  group('la venta 806 completa', () {
    final items = [
      linea(cantidad: 1237, precioUnitario: 0.015),
      linea(cantidad: 1, precioUnitario: 160),
      linea(cantidad: 1237, precioUnitario: 0.011),
    ];

    test('el total del carrito es el que el backend va a guardar', () {
      final total = items.fold<double>(0, (s, i) => s + i.total);
      // 🔴 Antes daba 192.165 y al cobrar se mandaban 192.16, contra los 192.17
      // que guardaba el backend: 0.01 pendiente y la venta nunca pasaba a
      // PAGADA.
      expect(double.parse(total.toStringAsFixed(2)), 192.17);
    });

    test('y subtotal + igv del carrito dan ese mismo total', () {
      final subtotal = items.fold<double>(0, (s, i) => s + i.subtotal);
      final igv = items.fold<double>(0, (s, i) => s + i.igv);
      expect(double.parse((subtotal + igv).toStringAsFixed(2)), 192.17);
    });
  });

  group('no rompe lo que ya andaba', () {
    test('precio redondo con IGV incluido', () {
      final l = linea(cantidad: 1, precioUnitario: 160);
      expect(l.subtotal, 135.59);
      expect(l.igv, 24.41);
      expect(l.total, 160);
      cuadra(l);
    });

    test('precio SIN IGV: el total lo suma', () {
      final l = linea(
          cantidad: 2, precioUnitario: 50, precioIncluyeIgv: false);
      expect(l.subtotal, 100);
      expect(l.igv, 18);
      expect(l.total, 118);
      cuadra(l);
    });

    test('con descuento', () {
      final l = linea(cantidad: 3, precioUnitario: 10, descuento: 5);
      expect(l.total, 25);
      cuadra(l);
    });

    test('el ICBPER se suma al total sin pasar por el IGV', () {
      final l = linea(cantidad: 2, precioUnitario: 5, icbper: 0.6);
      expect(l.total, 10.6);
      cuadra(l);
    });

    test('exonerado (0%)', () {
      final l = linea(cantidad: 3, precioUnitario: 7.5, porcentajeIGV: 0);
      expect(l.subtotal, 22.5);
      expect(l.igv, 0);
      expect(l.total, 22.5);
      cuadra(l);
    });
  });

  /// 🔑 La que de verdad protege: pesar produce estos números todo el tiempo y
  /// no se pueden enumerar a mano. Mismo barrido que el spec del backend, así
  /// que si los dos lados divergen, uno de los dos falla.
  test('cuadra para CUALQUIER peso y precio (barrido)', () {
    for (var gramos = 1; gramos <= 3000; gramos += 7) {
      for (final precioKilo in [7.0, 8.5, 11.0, 15.0, 19.9, 23.33]) {
        final l = linea(
          cantidad: gramos.toDouble(),
          precioUnitario: precioKilo / 1000,
        );
        final suma =
            double.parse((l.subtotal + l.igv + l.icbper).toStringAsFixed(2));
        expect(suma, l.total, reason: '$gramos g a $precioKilo/kg');
      }
    }
  });
}
