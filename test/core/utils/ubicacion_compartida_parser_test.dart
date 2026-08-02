import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/ubicacion_compartida_parser.dart';

void main() {
  group('UbicacionCompartidaParser', () {
    // Chiclayo, para que los valores se parezcan a los reales.
    const lat = -6.771389;
    const lon = -79.840833;

    void esperarPunto(UbicacionCompartida? r) {
      expect(r, isNotNull, reason: 'no reconoció la ubicación');
      expect(r!.tipo, TipoUbicacionCompartida.coordenadas);
      expect(r.punto!.latitude, closeTo(lat, 0.0001));
      expect(r.punto!.longitude, closeTo(lon, 0.0001));
    }

    group('enlaces de Google Maps', () {
      test('formato que manda WhatsApp al compartir ubicación', () {
        esperarPunto(
          UbicacionCompartidaParser.parse('https://maps.google.com/?q=$lat,$lon'),
        );
      });

      test('formato api=1 con query', () {
        esperarPunto(
          UbicacionCompartidaParser.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
          ),
        );
      });

      test('URL de lugar: prefiere el marcador !3d!4d sobre la cámara @', () {
        // El @ es el centro de la cámara y está corrido a propósito.
        final r = UbicacionCompartidaParser.parse(
          'https://www.google.com/maps/place/Local/@-6.5,-79.5,17z/data=!3d$lat!4d$lon',
        );
        esperarPunto(r);
      });

      test('cae al @ cuando no hay marcador', () {
        esperarPunto(
          UbicacionCompartidaParser.parse(
            'https://www.google.com/maps/@$lat,$lon,17z',
          ),
        );
      });

      test('direcciones con destination', () {
        esperarPunto(
          UbicacionCompartidaParser.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
          ),
        );
      });
    });

    group('geo:', () {
      test('coordenadas en la ruta', () {
        esperarPunto(UbicacionCompartidaParser.parse('geo:$lat,$lon'));
      });

      test('con zoom', () {
        esperarPunto(UbicacionCompartidaParser.parse('geo:$lat,$lon?z=17'));
      });

      test('ignora el relleno 0,0 y usa el parámetro q', () {
        esperarPunto(
          UbicacionCompartidaParser.parse('geo:0,0?q=$lat,$lon(Casa%20de%20Ana)'),
        );
      });
    });

    group('enlaces acortados', () {
      test('maps.app.goo.gl queda pendiente de resolver en el backend', () {
        final r = UbicacionCompartidaParser.parse(
          'https://maps.app.goo.gl/AbCdEf123',
        );
        expect(r, isNotNull);
        expect(r!.tipo, TipoUbicacionCompartida.enlaceAcortado);
        expect(r.urlAcortada, 'https://maps.app.goo.gl/AbCdEf123');
        expect(r.punto, isNull);
      });

      test('goo.gl/maps legacy también', () {
        final r = UbicacionCompartidaParser.parse('https://goo.gl/maps/XyZ789');
        expect(r!.tipo, TipoUbicacionCompartida.enlaceAcortado);
      });

      test('goo.gl que NO es de maps no se toma por ubicación', () {
        expect(UbicacionCompartidaParser.parse('https://goo.gl/otracosa'), isNull);
      });
    });

    group('texto real de WhatsApp', () {
      test('extrae el enlace cuando viene con texto alrededor', () {
        esperarPunto(
          UbicacionCompartidaParser.parse(
            'Hola, esta es mi ubicación: https://maps.google.com/?q=$lat,$lon '
            'toca el portón azul',
          ),
        );
      });

      test('no se come el punto final de la oración', () {
        final r = UbicacionCompartidaParser.parse(
          'Mi casa es https://maps.app.goo.gl/AbCdEf123.',
        );
        expect(r!.urlAcortada, 'https://maps.app.goo.gl/AbCdEf123');
      });

      test('par de coordenadas pelado', () {
        esperarPunto(UbicacionCompartidaParser.parse('$lat, $lon'));
      });
    });

    group('descarta lo que no es ubicación', () {
      test('null y vacío', () {
        expect(UbicacionCompartidaParser.parse(null), isNull);
        expect(UbicacionCompartidaParser.parse('   '), isNull);
      });

      test('texto suelto', () {
        expect(
          UbicacionCompartidaParser.parse('¿Ya salió el pedido?'),
          isNull,
        );
      });

      test('enlace cualquiera', () {
        expect(
          UbicacionCompartidaParser.parse('https://syncronize.pe/productos'),
          isNull,
        );
      });

      test('0,0 no es un delivery válido', () {
        expect(UbicacionCompartidaParser.parse('geo:0,0'), isNull);
        expect(
          UbicacionCompartidaParser.parse('https://maps.google.com/?q=0.0,0.0'),
          isNull,
        );
      });

      test('coordenadas fuera de rango', () {
        expect(
          UbicacionCompartidaParser.parse('https://maps.google.com/?q=95.5,-79.8'),
          isNull,
        );
        expect(
          UbicacionCompartidaParser.parse('https://maps.google.com/?q=-6.7,200.5'),
          isNull,
        );
      });

      test('el zoom no se confunde con coordenadas', () {
        // Sin decimales en ambos lados, "17,5" no debe pasar por par válido.
        expect(UbicacionCompartidaParser.parse('nivel 17,5 del edificio'), isNull);
      });
    });
  });
}
