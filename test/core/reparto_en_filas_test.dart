import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/reparto_en_filas.dart';

/// Campos compactos del sheet de "Datos adicionales" en filas (20-09).
///
/// Lo que pidió el user: "máximo 3 en una row, y 2 si no hay para poner 3".
/// El caso que lo originó son 5 campos de estado de componentes que ocupaban
/// 5 renglones; tienen que quedar 3 + 2.
void main() {
  group('repartirEnFilas con máximo 3', () {
    test('hasta 3 campos van todos en una sola fila', () {
      expect(repartirEnFilas(1, 3), [1]);
      expect(repartirEnFilas(2, 3), [2]);
      expect(repartirEnFilas(3, 3), [3]);
    });

    test('5 campos quedan 3 + 2 (el caso del user)', () {
      expect(repartirEnFilas(5, 3), [3, 2]);
    });

    test('nunca deja una fila con UNO si se puede repartir', () {
      // 4 -> [3, 1] sería lo obvio partiendo de a 3, y es justo lo que no
      // se quiere: el cuarto control queda huérfano.
      expect(repartirEnFilas(4, 3), [2, 2]);
      expect(repartirEnFilas(7, 3), [3, 2, 2]);
      expect(repartirEnFilas(10, 3), [3, 3, 2, 2]);
    });

    test('las filas llenas van arriba', () {
      expect(repartirEnFilas(8, 3), [3, 3, 2]);
      expect(repartirEnFilas(11, 3), [3, 3, 3, 2]);
    });

    test('con múltiplos exactos todas las filas van llenas', () {
      expect(repartirEnFilas(6, 3), [3, 3]);
      expect(repartirEnFilas(9, 3), [3, 3, 3]);
    });
  });

  group('teléfono angosto: máximo 2', () {
    test('reparte de a dos', () {
      expect(repartirEnFilas(4, 2), [2, 2]);
      expect(repartirEnFilas(6, 2), [2, 2, 2]);
    });

    test('con 3 la fila de uno es inevitable', () {
      expect(repartirEnFilas(3, 2), [2, 1]);
    });
  });

  group('bordes', () {
    test('sin campos no hay filas', () {
      expect(repartirEnFilas(0, 3), isEmpty);
      expect(repartirEnFilas(-1, 3), isEmpty);
    });

    test('un máximo inválido cae en una columna, no revienta', () {
      expect(repartirEnFilas(3, 0), [1, 1, 1]);
      expect(repartirEnFilas(2, -5), [1, 1]);
    });

    test('la suma del reparto es siempre la cantidad', () {
      for (var n = 1; n <= 40; n++) {
        for (final maximo in [1, 2, 3]) {
          final filas = repartirEnFilas(n, maximo);
          expect(filas.fold<int>(0, (a, b) => a + b), n,
              reason: 'n=$n maximo=$maximo');
          expect(filas.every((f) => f >= 1 && f <= maximo), isTrue,
              reason: 'n=$n maximo=$maximo dio $filas');
        }
      }
    });
  });
}
