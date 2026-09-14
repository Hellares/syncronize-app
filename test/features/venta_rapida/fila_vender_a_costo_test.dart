import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/core/widgets/custom_switch.dart';
import 'package:syncronize/features/venta_rapida/presentation/widgets/fila_vender_a_costo.dart';

/// La fila de "vender a costo" de Venta Rápida.
///
/// 🔴 Test de MONTAJE: `flutter analyze` verifica tipos y no ve el layout, y
/// esta fila vive en la pantalla principal de cobro. Se monta en el MISMO árbol
/// que la página (`Padding > Column(min) > Padding > fila`), a 500 de ancho:
/// las fuentes de la app no cargan en los tests y a ancho de celular
/// reportarían desbordes que en el dispositivo no existen.
/// Se toca el `Switch` de adentro, no el `CustomSwitch`: su raíz es un
/// `Transform.scale`, y `RenderTransform` no se anota en el camino del hit
/// test — el toque llega igual, pero `tap()` avisa que "no le pegó".
final _switch = find.descendant(
  of: find.byType(CustomSwitch),
  matching: find.byType(Switch),
);

void main() {
  Future<void> montar(
    WidgetTester tester, {
    bool activo = false,
    bool cargando = false,
    int lineas = 0,
    VoidCallback? onToggle,
    VoidCallback? onVenderCompra,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 500,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FilaVenderACosto(
                      activo: activo,
                      cargando: cargando,
                      lineasACosto: lineas,
                      onToggle: onToggle ?? () {},
                      onVenderCompra: onVenderCompra ?? () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('apagado: se monta sin reventar y muestra las dos entradas', (tester) async {
    await montar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Vender a costo'), findsOneWidget);
    expect(find.text('Vender compra'), findsOneWidget);
    // Apagado no hay subtítulo.
    expect(find.textContaining('a costo', findRichText: true), findsOneWidget);
  });

  testWidgets('prendido: el subtítulo dice cuántas líneas van a costo', (tester) async {
    await montar(tester, activo: true, lineas: 3);

    expect(tester.takeException(), isNull);
    expect(find.text('Vender a costo'), findsOneWidget);
    expect(find.text('3 líneas a costo'), findsOneWidget);

    await montar(tester, activo: true, lineas: 1);
    expect(find.text('1 línea a costo'), findsOneWidget);
  });

  testWidgets('las dos piezas tienen el mismo alto', (tester) async {
    await montar(tester, activo: true, lineas: 2);

    final interruptor = tester.getSize(find.byKey(FilaVenderACosto.keyInterruptor));
    final boton = tester.getSize(find.byKey(FilaVenderACosto.keyBoton));
    expect(interruptor.height, FilaVenderACosto.alto);
    expect(boton.height, FilaVenderACosto.alto);
  });

  testWidgets('tocar el interruptor y el botón dispara cada acción', (tester) async {
    var toggles = 0;
    var ventas = 0;
    await montar(
      tester,
      onToggle: () => toggles++,
      onVenderCompra: () => ventas++,
    );

    await tester.tap(_switch);
    await tester.tap(find.text('Vender compra'));
    await tester.pump();

    expect(toggles, 1);
    expect(ventas, 1);
  });

  testWidgets('buscando costos: el interruptor no se puede tocar', (tester) async {
    var toggles = 0;
    await montar(tester, cargando: true, onToggle: () => toggles++);

    expect(tester.takeException(), isNull);
    expect(find.text('Buscando costos…'), findsOneWidget);
    await tester.tap(_switch);
    await tester.pump();
    expect(toggles, 0);
  });
}
