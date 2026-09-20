import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/opcion_dependiente.dart';

/// Campo de plantilla con selección en CASCADA (20-09).
///
/// El contrato lo fija el backend (`campo-opcion-dependiente.spec.ts`): el
/// árbol vive en `opciones` y el valor es la ruta unida por " / ". Acá se
/// fija que el app lea y escriba EXACTAMENTE lo mismo, porque una cascada
/// cargada desde la web se completa desde el celular y al revés.
void main() {
  final opciones = {
    'niveles': ['Fabricante', 'Familia', 'Modelo'],
    'arbol': [
      {
        'valor': 'QUALCOMM',
        'hijos': [
          {
            'valor': 'SNAPDRAGON',
            'hijos': [
              {'valor': '8 Gen 3'},
              {'valor': '888'},
            ],
          },
        ],
      },
      {
        'valor': 'INTEL',
        'hijos': [
          {
            'valor': 'CORE',
            'hijos': [
              {'valor': 'i5-12400'},
            ],
          },
        ],
      },
    ],
  };

  group('lectura del árbol', () {
    test('lee niveles y raíces', () {
      final a = leerArbolDependiente(opciones)!;
      expect(a.niveles, ['Fabricante', 'Familia', 'Modelo']);
      expect(a.arbol.map((n) => n.valor), ['QUALCOMM', 'INTEL']);
    });

    test('🔴 un árbol ilegible da null y NO tira', () {
      // Un campo mal configurado se avisa en pantalla; no puede voltear el
      // formulario entero de la orden.
      expect(leerArbolDependiente(null), isNull);
      expect(leerArbolDependiente(['QUALCOMM']), isNull);
      expect(leerArbolDependiente({'niveles': [], 'arbol': []}), isNull);
      expect(
        leerArbolDependiente({
          'niveles': ['A'],
          'arbol': [
            {'nombre': 'x'},
          ],
        }),
        isNull,
      );
    });
  });

  group('navegación', () {
    final a = leerArbolDependiente(opciones)!;

    test('los hijos salen de la rama elegida', () {
      expect(hijosDeRuta(a, []).map((n) => n.valor), ['QUALCOMM', 'INTEL']);
      expect(hijosDeRuta(a, ['QUALCOMM']).map((n) => n.valor), ['SNAPDRAGON']);
      expect(
        hijosDeRuta(a, ['QUALCOMM', 'SNAPDRAGON']).map((n) => n.valor),
        ['8 Gen 3', '888'],
      );
    });

    test('una rama cruzada no ofrece nada', () {
      // CORE es de Intel: pedirlo bajo Qualcomm no puede devolver modelos.
      expect(hijosDeRuta(a, ['QUALCOMM', 'CORE']), isEmpty);
    });

    test('la ruta se parte igual que en el backend', () {
      expect(partirRuta('QUALCOMM / SNAPDRAGON / 8 Gen 3'),
          ['QUALCOMM', 'SNAPDRAGON', '8 Gen 3']);
      expect(partirRuta('INTEL/CORE/i5-12400'), ['INTEL', 'CORE', 'i5-12400']);
      expect(partirRuta(null), isEmpty);
    });

    test('el separador es ASCII (esto se imprime en térmica)', () {
      expect(sepDependiente, ' / ');
      expect(sepDependiente.codeUnits.every((c) => c < 128), isTrue);
    });
  });

  group('editor: texto indentado', () {
    test('la sangría define el nivel', () {
      final arbol = textoAArbol('QUALCOMM\n  SNAPDRAGON\n    888\nINTEL');
      expect(arbol.length, 2);
      expect(arbol[0]['valor'], 'QUALCOMM');
      final flia = (arbol[0]['hijos'] as List).first as Map;
      expect(flia['valor'], 'SNAPDRAGON');
      expect(((flia['hijos'] as List).first as Map)['valor'], '888');
      // Una hoja no lleva la clave `hijos`: así queda igual que lo que manda
      // la web y el JSON no se llena de listas vacías.
      expect(arbol[1].containsKey('hijos'), isFalse);
    });

    test('ida y vuelta: texto -> árbol -> texto', () {
      const texto = 'QUALCOMM\n  SNAPDRAGON\n    8 Gen 3\n    888\nINTEL\n  CORE';
      final arbol = leerArbolDependiente({
        'niveles': ['a', 'b', 'c'],
        'arbol': textoAArbol(texto),
      })!;
      expect(arbolATexto(arbol.arbol), texto);
    });

    test('tolera tabs y líneas en blanco', () {
      final arbol = textoAArbol('QUALCOMM\n\n\tSNAPDRAGON\n');
      expect((arbol[0]['hijos'] as List).length, 1);
    });
  });
}
