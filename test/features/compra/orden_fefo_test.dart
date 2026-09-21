import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/orden_fefo.dart';

/// El orden en que los lotes SALEN del estante.
///
/// Lo dibujan dos pantallas —la ficha del producto y la trazabilidad— y tiene
/// que ser el mismo que el del backend: si la pantalla dice que sale uno y el
/// sistema descuenta otro, el FEFO deja de servir para trabajar.
void main() {
  Map<String, dynamic> lote({
    String codigo = 'L1',
    int cantidad = 10,
    String? vence,
    String ingreso = '2026-01-01',
    String estado = 'ACTIVO',
  }) =>
      {
        'codigo': codigo,
        'cantidadActual': cantidad,
        'fechaVencimiento': vence,
        'fechaIngreso': ingreso,
        'estado': estado,
      };

  group('está en el estante', () {
    test('un ACTIVO con stock cuenta', () {
      expect(lotePresente(lote()), isTrue);
    });

    test('🔴 un VENCIDO con stock TAMBIÉN cuenta: sigue en el estante', () {
      // Hasta que alguien lo dé de baja, la caja está ahí y alguien la puede
      // agarrar. Esconderlo es lo que hace que aparezca "de la nada" al vender.
      expect(lotePresente(lote(estado: 'VENCIDO')), isTrue);
    });

    test('sin stock no cuenta, aunque esté activo', () {
      expect(lotePresente(lote(cantidad: 0)), isFalse);
    });
  });

  group('orden de salida', () {
    test('vence antes, sale antes', () {
      final ordenado = lotesOrdenados([
        lote(codigo: 'TARDE', vence: '2026-12-01'),
        lote(codigo: 'PRONTO', vence: '2026-02-01'),
      ]);
      expect(ordenado.first['codigo'], 'PRONTO');
    });

    test('🔴 los SIN vencimiento van al final, no al principio', () {
      // Ordenar por fecha dejando los null adelante mandaba a vender primero
      // lo que no caduca y dejaba pudrirse lo que sí.
      final ordenado = lotesOrdenados([
        lote(codigo: 'SIN-FECHA'),
        lote(codigo: 'VENCE', vence: '2026-03-01'),
      ]);
      expect(ordenado.map((l) => l['codigo']), ['VENCE', 'SIN-FECHA']);
    });

    test('entre dos sin vencimiento sale el que entró primero', () {
      final ordenado = lotesOrdenados([
        lote(codigo: 'NUEVO', ingreso: '2026-05-01'),
        lote(codigo: 'VIEJO', ingreso: '2026-01-01'),
      ]);
      expect(ordenado.first['codigo'], 'VIEJO');
    });

    test('los agotados quedan detrás de TODOS los presentes', () {
      final ordenado = lotesOrdenados([
        lote(codigo: 'AGOTADO', cantidad: 0, vence: '2026-01-01'),
        lote(codigo: 'PRESENTE', vence: '2026-12-01'),
      ]);
      // El agotado vence mucho antes, pero ya no hay nada que sacar de él.
      expect(ordenado.first['codigo'], 'PRESENTE');
      expect(ordenado.last['codigo'], 'AGOTADO');
    });
  });
}
