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
}
