import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';

/// El sistema guarda en gramos (para que el stock entero aguante los 22 000 de
/// un saco y, más adelante, la lectura de una balanza) pero el usuario piensa
/// en kilos. Este traductor es el único lugar donde vive esa conversión.
void main() {
  const kg = UnidadPresentacion(factor: 1000, simbolo: 'kg', simboloVenta: 'g');
  const sinPresentacion =
      UnidadPresentacion(factor: 1, simbolo: null, simboloVenta: 'und');

  group('cantidades', () {
    test('un saco entero se lee en kilos', () {
      expect(kg.cantidadTexto(22000), '22 kg');
    });

    test('al vender 1.5 kg el stock baja a 20.5 kg', () {
      // 22 000 g − 1500 g = 20 500 g
      expect(kg.cantidadTexto(20500), '20.5 kg');
    });

    test('el gramo suelto no se pierde ni se rellena con ceros', () {
      expect(kg.cantidadTexto(20501), '20.501 kg');
      expect(kg.cantidadTexto(21000), '21 kg'); // no "21.000 kg"
    });

    test('sin símbolo cuando se pide sin él', () {
      expect(kg.cantidadTexto(20500, conSimbolo: false), '20.5');
    });
  });

  group('precios', () {
    test('S/0.008 el gramo son S/8.00 el kilo', () {
      expect(kg.precio(0.008), closeTo(8.0, 1e-9));
      expect(kg.precioTexto(0.008), 'S/ 8.00/kg');
    });

    test('el costo del saco vuelve al precio por kilo', () {
      // 147.99 / 22 000 = 0.006727 por gramo
      expect(kg.precioTexto(0.006727), 'S/ 6.73/kg');
    });

    test('el precio que escribe el usuario vuelve a unidad de venta', () {
      // Es la conversión que evita guardar S/8 el GRAMO, o sea S/8000 el kilo.
      expect(kg.precioAUnidadDeVenta(8.00), closeTo(0.008, 1e-9));
      expect(kg.precioAUnidadDeVenta(9.49), closeTo(0.00949, 1e-9));
    });
  });

  group('cantidad y precio van en sentidos OPUESTOS', () {
    // El bug que motivó separarlos: usar el inverso del precio para una
    // cantidad convertía 1 kg en 0.001 g, el carrito lo redondeaba a 0 y el
    // campo quedaba en cero, sin poder editarlo.
    test('la cantidad escrita se MULTIPLICA', () {
      expect(kg.cantidadAUnidadDeVenta(1), 1000);
      expect(kg.cantidadAUnidadDeVenta(1.5), 1500);
      expect(kg.cantidadAUnidadDeVenta(0.25), 250);
    });

    test('el precio escrito se DIVIDE', () {
      expect(kg.precioAUnidadDeVenta(8.00), closeTo(0.008, 1e-9));
    });

    test('ida y vuelta de la cantidad no pierde nada', () {
      expect(kg.cantidad(kg.cantidadAUnidadDeVenta(1.5)), closeTo(1.5, 1e-9));
      expect(kg.cantidadTexto(kg.cantidadAUnidadDeVenta(1.5)), '1.5 kg');
    });

    test('sin presentación ninguno de los dos toca el número', () {
      expect(sinPresentacion.cantidadAUnidadDeVenta(3), 3);
      expect(sinPresentacion.precioAUnidadDeVenta(3), 3);
    });
  });

  group('sin presentación configurada', () {
    test('no toca ningún número', () {
      expect(sinPresentacion.activa, isFalse);
      expect(sinPresentacion.cantidadTexto(22000), '22000 und');
      expect(sinPresentacion.precio(0.008), 0.008);
      expect(sinPresentacion.precioAUnidadDeVenta(8.0), 8.0);
    });

    test('un factor de 1 no agrupa nada, aunque venga con símbolo', () {
      const raro = UnidadPresentacion(factor: 1, simbolo: 'kg');
      expect(raro.activa, isFalse);
      expect(raro.cantidad(500), 500);
    });

    test('la constante `ninguna` es el caso neutro', () {
      const nada = UnidadPresentacion.ninguna();
      expect(nada.activa, isFalse);
      expect(nada.cantidadTexto(7), '7');
    });
  });

  group('costoUnitarioDesdeBulto', () {
    // RICOCAT: saco de 22 000 g a S/147.99. El usuario solo sabe el precio
    // del saco; el sistema guarda el costo por gramo.
    const kilo = UnidadPresentacion(factor: 1000, simbolo: 'kg');

    test('reparte el precio del saco entre las unidades que trae', () {
      final porGramo = costoUnitarioDesdeBulto(147.99, 22000)!;

      expect(porGramo, closeTo(0.00672681, 1e-8));
      // Y el número que se le muestra al usuario: S/6.7268 el kilo.
      expect(kilo.precio(porGramo), closeTo(6.726818, 1e-6));
    });

    test('la cuenta vuelve a dar la factura del proveedor', () {
      // La prueba que importa: costo unitario x unidades del bulto tiene que
      // reconstruir lo que se pagó, o el costo promedio queda mal para
      // siempre.
      final porGramo = costoUnitarioDesdeBulto(147.99, 22000)!;
      expect(porGramo * 22000, closeTo(147.99, 1e-9));
    });

    test('divide por el factor de COMPRA, no por el de presentación', () {
      // 147.99/1000 = 0.14799 seria el error de usar el factor equivocado:
      // un costo 22 veces mas alto que el real.
      final porGramo = costoUnitarioDesdeBulto(147.99, 22000)!;
      expect(porGramo, isNot(closeTo(0.14799, 1e-6)));
    });

    test('sin factor de compra no inventa un costo', () {
      expect(costoUnitarioDesdeBulto(147.99, null), isNull);
      expect(costoUnitarioDesdeBulto(147.99, 0), isNull);
      expect(costoUnitarioDesdeBulto(0, 22000), isNull);
    });
  });

  group('formatearNumero', () {
    test('no rellena con ceros', () {
      expect(UnidadPresentacion.formatearNumero(22), '22');
      expect(UnidadPresentacion.formatearNumero(20.5), '20.5');
    });

    test('conserva los 4 decimales del costo por kilo', () {
      // A 2 decimales mostraria 6.73, que no es el numero que se guarda.
      expect(
        UnidadPresentacion.formatearNumero(6.726818, maxDecimales: 4),
        '6.7268',
      );
    });
  });
}
