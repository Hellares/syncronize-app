import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// Identificadores (IMEI / N° de serie / placa) agrupados POR UNIDAD.
///
/// Una unidad puede llevar más de un código: un celular dual SIM tiene dos
/// IMEI. Lo que se fija acá:
///
///  1. El cobro se bloquea si a alguna unidad le falta SU primer código; los
///     extra son opcionales y no frenan la venta.
///  2. Lo que se manda al backend sale recortado a la cantidad ACTUAL. Si se
///     cargaron tres IMEI y después se bajó la cantidad a dos, el tercero ya
///     no es de esta venta y mandarlo hacía que el backend rechazara el cobro.
///  3. Se mandan las dos formas: la agrupada (que el backend necesita para
///     saber qué par es de qué aparato) y la plana (que hace que este app
///     siga cobrando contra un backend que todavía no conozca la agrupada).
void main() {
  VentaDetalleInput linea({
    required double cantidad,
    List<List<String>> identificadores = const [],
    List<List<String>> notas = const [],
    bool requiere = true,
  }) {
    return VentaDetalleInput(
      descripcion: 'CELULAR REDMI',
      cantidad: cantidad,
      precioUnitario: 1000,
      requiereIdentificador: requiere,
      etiquetaIdentificador: 'IMEI',
      identificadores: identificadores,
      notasIdentificador: notas,
    );
  }

  group('bloqueo del cobro', () {
    test('una unidad sin ningún código bloquea', () {
      final l = linea(cantidad: 2, identificadores: [
        ['351234567890123'],
        [],
      ]);
      expect(l.identificadoresIncompletos, isTrue);
    });

    test('un código por unidad alcanza: los extra son opcionales', () {
      final l = linea(cantidad: 2, identificadores: [
        ['351234567890123'],
        ['351234567890125'],
      ]);
      expect(l.identificadoresIncompletos, isFalse);
    });

    test('el segundo IMEI vacío NO bloquea', () {
      final l = linea(cantidad: 1, identificadores: [
        ['351234567890123', ''],
      ]);
      expect(l.identificadoresIncompletos, isFalse);
    });

    test('el producto que no lo pide nunca bloquea', () {
      expect(linea(cantidad: 3, requiere: false).identificadoresIncompletos,
          isFalse);
    });
  });

  group('lo que viaja al backend', () {
    test('dual SIM: agrupado por unidad y también plano', () {
      final json = linea(cantidad: 1, identificadores: [
        ['351234567890123', '351234567890124'],
      ]).toMap();

      expect(json['identificadoresPorUnidad'], [
        ['351234567890123', '351234567890124'],
      ]);
      expect(json['identificadores'],
          ['351234567890123', '351234567890124']);
    });

    test('se recorta a la cantidad actual si bajó después de cargar', () {
      final json = linea(cantidad: 2, identificadores: [
        ['351234567890123'],
        ['351234567890124'],
        ['351234567890125'], // sobra: la cantidad bajó a 2
      ]).toMap();

      expect(json['identificadoresPorUnidad'], [
        ['351234567890123'],
        ['351234567890124'],
      ]);
      expect(json['identificadores'],
          ['351234567890123', '351234567890124']);
    });

    test('las casillas vacías y los espacios no viajan', () {
      final json = linea(cantidad: 1, identificadores: [
        ['  351234567890123  ', ''],
      ]).toMap();

      expect(json['identificadoresPorUnidad'], [
        ['351234567890123'],
      ]);
    });

    test('sin ningún código cargado no se manda la clave', () {
      final json = linea(cantidad: 2).toMap();
      expect(json.containsKey('identificadoresPorUnidad'), isFalse);
      expect(json.containsKey('identificadores'), isFalse);
    });

    test('cada código lleva SU nota, agrupada y también aplanada', () {
      final json = linea(
        cantidad: 2,
        identificadores: [
          ['351234567890123', '351234567890124'],
          ['351234567890125'],
        ],
        notas: [
          ['SIM1', 'SIM2'],
          ['BLANCO 256GB'],
        ],
      ).toMap();

      expect(json['notasIdentificadorPorUnidad'], [
        ['SIM1', 'SIM2'],
        ['BLANCO 256GB'],
      ]);
      // Aplanada queda alineada por índice con `identificadores`, que es como
      // la lee un backend que no conozca la forma agrupada.
      expect(json['notasIdentificador'], ['SIM1', 'SIM2', 'BLANCO 256GB']);
      expect(json['identificadores'], [
        '351234567890123',
        '351234567890124',
        '351234567890125',
      ]);
    });

    test('🔴 la nota se va CON su código cuando la casilla quedó vacía', () {
      final json = linea(
        cantidad: 1,
        // La casilla del medio no se llenó: su nota no puede correrse a la
        // siguiente.
        identificadores: [
          ['351234567890123', '', '351234567890125'],
        ],
        notas: [
          ['SIM1', 'HUERFANA', 'SERIE'],
        ],
      ).toMap();

      expect(json['identificadoresPorUnidad'], [
        ['351234567890123', '351234567890125'],
      ]);
      expect(json['notasIdentificadorPorUnidad'], [
        ['SIM1', 'SERIE'],
      ]);
    });

    test('sin ninguna nota, no se manda ninguna de las dos claves', () {
      final json = linea(cantidad: 1, identificadores: [
        ['351234567890123'],
      ]).toMap();

      expect(json.containsKey('notasIdentificadorPorUnidad'), isFalse);
      expect(json.containsKey('notasIdentificador'), isFalse);
    });
  });
}
