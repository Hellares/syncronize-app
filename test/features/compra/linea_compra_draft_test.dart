import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/entities/linea_compra_draft.dart';

/// La matemática de una línea de compra: convertir el saco a unidades, ver a
/// cuánto queda el costo del producto después de recibir, y avisar si con eso
/// se pasaría a vender bajo costo.
void main() {
  LineaCompraDraft linea({
    int cantidad = 1,
    double? precio,
    bool usaUnidadCompra = false,
    double? factorCompra,
    String? unidadCompraSimbolo,
    double? costoActual,
    double? precioVentaActual,
    int? stockActual,
    double? nuevoPrecioVenta,
    double? factorPresentacion,
  }) =>
      LineaCompraDraft(
        productoId: 'p1',
        descripcion: 'ARROZ',
        unidadVentaSimbolo: 'g',
        unidadPresentacionSimbolo: factorPresentacion != null ? 'kg' : null,
        cantidad: cantidad,
        precioUnitario: precio,
        usaUnidadCompra: usaUnidadCompra,
        factorCompra: factorCompra,
        unidadCompraSimbolo: unidadCompraSimbolo,
        costoActualSede: costoActual,
        precioVentaActualSede: precioVentaActual,
        stockActualSede: stockActual,
        nuevoPrecioVenta: nuevoPrecioVenta,
        factorPresentacion: factorPresentacion,
      );

  group('unidad de compra', () {
    test('el saco se convierte a unidades para comparar contra el costo', () {
      final l = linea(
        cantidad: 3,
        precio: 100,
        usaUnidadCompra: true,
        factorCompra: 50,
        unidadCompraSimbolo: 'SACO',
      );

      expect(l.cantidadAtomica, 150);
      expect(l.precioAtomico, 2);
    });

    test('sin el toggle prendido no convierte nada', () {
      final l = linea(
        cantidad: 3,
        precio: 100,
        factorCompra: 50,
        unidadCompraSimbolo: 'SACO',
      );

      expect(l.cantidadAtomica, 3);
      expect(l.precioAtomico, 100);
    });

    test('un producto sin empaque configurado no soporta unidad de compra', () {
      // Con el toggle prendido pero sin factor/símbolo, convertir dividiría
      // por 1 y mentiría diciendo que la línea viene en sacos.
      final l = linea(cantidad: 2, precio: 8, usaUnidadCompra: true);

      expect(l.soportaUnidadCompra, isFalse);
      expect(l.cantidadAtomica, 2);
      expect(l.precioAtomico, 8);
    });
  });

  group('costo proyectado', () {
    test('sin stock previo, el costo pasa a ser el de esta compra', () {
      final l = linea(cantidad: 5, precio: 4, costoActual: 9, stockActual: 0);

      expect(l.costoProyectado, 4);
    });

    test('con stock previo es el promedio ponderado', () {
      // 10 unidades a S/2 + 10 que entran a S/4 = S/3.
      final l = linea(cantidad: 10, precio: 4, costoActual: 2, stockActual: 10);

      expect(l.costoProyectado, 3);
    });

    test('el saco se pondera por unidades, no por sacos', () {
      // 50 unidades a S/1 + 1 saco de 50 a S/150 (S/3 la unidad) = S/2.
      final l = linea(
        cantidad: 1,
        precio: 150,
        usaUnidadCompra: true,
        factorCompra: 50,
        unidadCompraSimbolo: 'SACO',
        costoActual: 1,
        stockActual: 50,
      );

      expect(l.costoProyectado, 2);
    });

    test('sin precio cargado todavía, se queda en el costo actual', () {
      final l = linea(cantidad: 5, costoActual: 3, stockActual: 10);

      expect(l.costoProyectado, 3);
    });
  });

  group('sugerencias de precio de venta', () {
    test('mantener margen lo calcula sobre el costo NUEVO', () {
      // Vende a S/4 con costo S/2 → 100% de margen. Costo nuevo S/3 → S/6.
      final l = linea(
        cantidad: 10,
        precio: 4,
        costoActual: 2,
        precioVentaActual: 4,
        stockActual: 10,
      );

      expect(l.margenActualPct, 100);
      expect(l.precioVentaMantenerMargen, 6);
    });

    test('+10% siempre cubre el costo nuevo', () {
      final l = linea(cantidad: 10, precio: 4, costoActual: 2, stockActual: 10);

      expect(l.precioVentaMas10, closeTo(3.3, 1e-9));
    });

    test('sin precio de venta actual no hay margen que mantener', () {
      final l = linea(cantidad: 1, precio: 4, costoActual: 2, stockActual: 0);

      expect(l.margenActualPct, isNull);
      expect(l.precioVentaMantenerMargen, isNull);
      // El +10% sí sale: no necesita saber a cuánto se vendía.
      expect(l.precioVentaMas10, closeTo(4.4, 1e-9));
    });
  });

  group('vender bajo costo', () {
    test('avisa cuando el costo nuevo supera el precio de venta', () {
      // Se vendía a S/2.50 con costo S/2; entra mercadería a S/4 y el costo
      // proyectado queda en S/3.
      final l = linea(
        cantidad: 10,
        precio: 4,
        costoActual: 2,
        precioVentaActual: 2.5,
        stockActual: 10,
      );

      expect(l.costoProyectado, 3);
      expect(l.costoSuperaVenta, isTrue);
    });

    test('mira el costo PROYECTADO, no solo el de esta línea', () {
      // La línea entra cara (S/4 > S/3.50) pero es poca cantidad contra un
      // stock grande y barato, así que el costo del producto queda por debajo
      // de la venta y no hay pérdida.
      final l = linea(
        cantidad: 1,
        precio: 4,
        costoActual: 1,
        precioVentaActual: 3.5,
        stockActual: 100,
      );

      expect(l.costoSuperaVenta, isFalse);
    });

    test('el nuevo precio de venta apaga el aviso', () {
      final base = linea(
        cantidad: 10,
        precio: 4,
        costoActual: 2,
        precioVentaActual: 2.5,
        stockActual: 10,
      );

      expect(base.copyWith(nuevoPrecioVenta: 3.5).costoSuperaVenta, isFalse);
      expect(base.copyWith(nuevoPrecioVenta: 2.9).costoSuperaVenta, isTrue);
    });

    test('sin precio de compra no hay nada que avisar', () {
      final l = linea(cantidad: 3, costoActual: 2, precioVentaActual: 1);

      expect(l.costoSuperaVenta, isFalse);
    });

    test('sin precio de venta conocido tampoco se inventa un aviso', () {
      final l = linea(cantidad: 3, precio: 99, costoActual: 2, stockActual: 0);

      expect(l.costoSuperaVenta, isFalse);
    });
  });

  group('un granel se compra en KILOS', () {
    // El producto se guarda en gramos para que el stock aguante los 22 000 de
    // un saco, pero nadie compra "15000 g a S/0.008".
    final granel = linea(
      cantidad: 15000,
      precio: 0.008,
      factorPresentacion: 1000,
      costoActual: 0.008,
    );

    test('los campos se muestran en kilos, no en gramos', () {
      expect(granel.cantidadCarga, 15);
      expect(granel.precioCarga, closeTo(8, 1e-9));
      expect(granel.factorCarga, 1000);
    });

    test('lo escrito en kilos se guarda en gramos', () {
      final l = granel.conCarga(
        cantidad: 20,
        precio: 9,
        usaUnidadCompra: false,
      );

      expect(l.cantidad, 20000);
      expect(l.precioUnitario, closeTo(0.009, 1e-9));
      // La plata es la misma se mire como se mire.
      expect(l.subtotal, closeTo(180, 1e-6));
    });

    test('el costo por unidad NO se redondea a centavos', () {
      // S/6.7268 el kilo son S/0.0067268 el gramo. A dos decimales queda 0.01
      // —un 48% de más— multiplicado por cada gramo del saco.
      final l = granel.conCarga(
        cantidad: 22,
        precio: 6.7268,
        usaUnidadCompra: false,
      );

      expect(l.precioUnitario, closeTo(0.006727, 1e-9));
      expect(l.precioUnitario, isNot(0.01));
    });

    test('ida y vuelta por los campos no mueve la línea', () {
      final l = granel.conCarga(
        cantidad: granel.cantidadCarga,
        precio: granel.precioCarga,
        usaUnidadCompra: false,
      );

      expect(l.cantidad, granel.cantidad);
      expect(l.precioUnitario, closeTo(granel.precioUnitario!, 1e-9));
    });

    test('sin presentación configurada nada cambia', () {
      final simple = linea(cantidad: 7, precio: 3.5);

      expect(simple.factorCarga, 1);
      expect(simple.cantidadCarga, 7);
      expect(simple.precioCarga, 3.5);
      expect(
        simple.conCarga(cantidad: 9, precio: 4, usaUnidadCompra: false).cantidad,
        9,
      );
    });

    test('con el saco prendido manda el saco, no el kilo', () {
      final saco = linea(
        cantidad: 2,
        precio: 150,
        usaUnidadCompra: true,
        factorCompra: 22000,
        unidadCompraSimbolo: 'SACO',
        factorPresentacion: 1000,
      );

      expect(saco.factorCarga, 22000);
      expect(saco.simboloCarga, 'SACO');
      expect(saco.cantidadCarga, 2);
      expect(saco.cantidadAtomica, 44000);
    });
  });

  group('conCarga resuelve la unidad para el backend', () {
    final base = linea(
      factorCompra: 50,
      unidadCompraSimbolo: 'SACO',
      costoActual: 1,
    );

    test('sacos enteros viajan como sacos', () {
      final l =
          base.conCarga(cantidad: 3, precio: 150, usaUnidadCompra: true);

      expect(l.cantidad, 3);
      expect(l.precioUnitario, 150);
      expect(l.usaUnidadCompra, isTrue);
    });

    test('media unidad de compra se APLANA a unidad atómica', () {
      // El backend valida `cantidad` con @IsInt: 1.5 sacos no pasa. Se manda
      // el equivalente exacto en unidades, con su costo por unidad.
      final l =
          base.conCarga(cantidad: 1.5, precio: 150, usaUnidadCompra: true);

      expect(l.cantidad, 75);
      expect(l.precioUnitario, 3);
      expect(l.usaUnidadCompra, isFalse);
      // Aplanada o no, la línea vale lo mismo.
      expect(l.subtotal, closeTo(225, 1e-9));
    });

    test('el empaque override se usa para aplanar', () {
      // El saco vino con 40 en vez de 50.
      final l = base.conCarga(
        cantidad: 2.5,
        precio: 100,
        usaUnidadCompra: true,
        factor: 40,
      );

      expect(l.cantidad, 100);
      expect(l.precioUnitario, 2.5);
      expect(l.factorCompra, 40);
    });

    test('sin unidad de compra redondea la cantidad y no toca el precio', () {
      final l = base.conCarga(cantidad: 7, precio: 2.4, usaUnidadCompra: false);

      expect(l.cantidad, 7);
      expect(l.precioUnitario, 2.4);
      expect(l.usaUnidadCompra, isFalse);
    });
  });
}
