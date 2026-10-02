import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/core/widgets/custom_switch.dart';
import 'package:syncronize/features/venta_rapida/presentation/widgets/fila_vender_a_costo.dart';

/// El interruptor de "vender por mayor" de Venta Rápida.
///
/// 🔴 Test de MONTAJE, por lo mismo que `fila_vender_a_costo_test.dart`:
/// `flutter analyze` no ve el layout. Se monta en el mismo árbol que la página,
/// DEBAJO de la fila de costo, que es como vive en pantalla.
final _switches = find.descendant(
  of: find.byType(CustomSwitch),
  matching: find.byType(Switch),
);

void main() {
  Future<void> montar(
    WidgetTester tester, {
    bool activo = false,
    int lineas = 0,
    VoidCallback? onToggle,
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
                      activo: false,
                      cargando: false,
                      lineasACosto: 0,
                      onToggle: () {},
                      onVenderCompra: () {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FilaVenderPorMayor(
                      activo: activo,
                      lineasPorMayor: lineas,
                      onToggle: onToggle ?? () {},
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

  testWidgets('apagado: se monta sin reventar, debajo de la fila de costo',
      (tester) async {
    await montar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Vender por mayor'), findsOneWidget);
    expect(find.text('Vender a costo'), findsOneWidget);
  });

  testWidgets('prendido: dice cuántas líneas van por mayor y mantiene el alto',
      (tester) async {
    await montar(tester, activo: true, lineas: 3);

    expect(tester.takeException(), isNull);
    expect(find.text('3 líneas por mayor'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(FilaVenderPorMayor.keyInterruptor)).height,
      FilaVenderACosto.alto,
    );

    await montar(tester, activo: false, lineas: 1);
    expect(find.text('1 línea por mayor'), findsOneWidget);
  });

  testWidgets('tocar el interruptor dispara la acción', (tester) async {
    var toggles = 0;
    await montar(tester, onToggle: () => toggles++);

    await tester.tap(_switches.last);
    await tester.pump();

    expect(toggles, 1);
  });
}
