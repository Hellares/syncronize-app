import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/venta_rapida/presentation/widgets/cantidad_stepper.dart';

/// El `[−] 3 [+]` de la cantidad en el carrito de Venta Rápida.
///
/// 🔴 Test de MONTAJE: `flutter analyze` no ve el layout. 69 px es lo que le
/// toca a la columna de cantidad en un teléfono de 360 px (130 del nombre,
/// 50 del stock, y el resto repartido 1:2:2 entre precio, cantidad y total).
void main() {
  Future<TextEditingController> montar(
    WidgetTester tester, {
    double ancho = 69,
    String texto = '3',
    VoidCallback? onMas,
    VoidCallback? onMenos,
    bool puedeMas = true,
    bool puedeMenos = true,
    ValueChanged<String>? onChanged,
    bool granel = false,
  }) async {
    final ctrl = TextEditingController(text: texto);
    final foco = FocusNode();
    addTearDown(ctrl.dispose);
    addTearDown(foco.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: ancho,
            child: CantidadStepper(
              controller: ctrl,
              focusNode: foco,
              onChanged: onChanged ?? (_) {},
              onMas: granel ? null : (onMas ?? () {}),
              onMenos: granel ? null : (onMenos ?? () {}),
              puedeMas: puedeMas,
              puedeMenos: puedeMenos,
              decimales: granel,
            ),
          ),
        ),
      ),
    ));
    return ctrl;
  }

  testWidgets('entra en la columna de un teléfono de 360 px, aun con 999',
      (tester) async {
    await montar(tester, texto: '999');
    expect(tester.takeException(), isNull);
    expect(find.text('999'), findsOneWidget);
    expect(tester.getSize(find.byType(CantidadStepper)).width, 69);
  });

  testWidgets('el + y el − disparan su acción', (tester) async {
    var mas = 0, menos = 0;
    await montar(tester, onMas: () => mas++, onMenos: () => menos++);
    await tester.tap(find.byKey(CantidadStepper.keyMas));
    await tester.tap(find.byKey(CantidadStepper.keyMas));
    await tester.tap(find.byKey(CantidadStepper.keyMenos));
    expect(mas, 2);
    expect(menos, 1);
  });

  testWidgets('apagados en el tope no hacen nada', (tester) async {
    var mas = 0, menos = 0;
    await montar(
      tester,
      onMas: () => mas++,
      onMenos: () => menos++,
      puedeMas: false,
      puedeMenos: false,
    );
    await tester.tap(find.byKey(CantidadStepper.keyMas));
    await tester.tap(find.byKey(CantidadStepper.keyMenos));
    expect(mas, 0);
    expect(menos, 0);
  });

  testWidgets('mantener el + apretado repite', (tester) async {
    var mas = 0;
    await montar(tester, onMas: () => mas++);
    final gesto =
        await tester.startGesture(tester.getCenter(find.byKey(CantidadStepper.keyMas)));
    await tester.pump(const Duration(milliseconds: 600)); // long press
    await tester.pump(const Duration(milliseconds: 500)); // ráfaga
    await gesto.up();
    await tester.pump();
    expect(mas, greaterThan(2));
  });

  testWidgets('se puede escribir la cantidad', (tester) async {
    String? escrito;
    await montar(tester, onChanged: (v) => escrito = v);
    await tester.enterText(find.byType(TextField), '48');
    expect(escrito, '48');
  });

  testWidgets('a granel va sin botones y acepta decimales', (tester) async {
    String? escrito;
    await montar(tester, granel: true, onChanged: (v) => escrito = v);
    expect(find.byKey(CantidadStepper.keyMas), findsNothing);
    expect(find.byKey(CantidadStepper.keyMenos), findsNothing);
    await tester.enterText(find.byType(TextField), '1.5');
    expect(escrito, '1.5');
  });
}
