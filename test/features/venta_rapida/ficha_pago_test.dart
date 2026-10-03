import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/venta_rapida/presentation/widgets/ficha_pago.dart';

/// Las fichas de la rejilla de pagos del cobro.
///
/// 🔴 Test de MONTAJE: `flutter analyze` no ve el layout. Se montan de a dos
/// por fila, como en la página, en un teléfono de 360 px (12 de margen por
/// lado y 8 entre fichas: ~164 px cada una); se prueba también más angosto.
void main() {
  late List<TextEditingController> ctrls;
  late List<FocusNode> focos;

  setUp(() {
    ctrls = List.generate(2, (_) => TextEditingController());
    focos = List.generate(2, (_) => FocusNode());
  });
  tearDown(() {
    for (final c in ctrls) {
      c.dispose();
    }
    for (final f in focos) {
      f.dispose();
    }
  });

  Future<void> montar(
    WidgetTester tester, {
    double ancho = 360,
    String monto = '1,250.00',
    VoidCallback? onQuitar,
    VoidCallback? onAgregar,
  }) async {
    ctrls[0].text = monto;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: ancho,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: FichaPago(
                        label: 'Transferencia',
                        icono: Icons.account_balance,
                        controller: ctrls[0],
                        focusNode: focos[0],
                        seleccionada: true,
                        onQuitar: onQuitar,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FichaPago(
                        label: 'Yape',
                        // El SVG real no hace falta para medir: mismo alto.
                        logo: const SizedBox(width: 20, height: 24),
                        controller: ctrls[1],
                        focusNode: focos[1],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: FichaAgregarPago(onTap: onAgregar ?? () {})),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox.shrink()),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('dos por fila entran en 360 px con un monto de miles y ✕',
      (tester) async {
    await montar(tester, onQuitar: () {});
    expect(tester.takeException(), isNull);
    expect(find.text('1,250.00'), findsOneWidget);
    expect(tester.getSize(find.byType(FichaPago).first).height, FichaPago.alto);
  });

  testWidgets('y en 320 px tampoco se desborda', (tester) async {
    await montar(tester, ancho: 320, onQuitar: () {});
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar la ficha le da el foco a su monto', (tester) async {
    await montar(tester);
    await tester.tap(find.byType(FichaPago).last);
    await tester.pump();
    expect(focos[1].hasFocus, isTrue);
  });

  testWidgets('la ✕ solo aparece si se puede quitar, y quita', (tester) async {
    var quitadas = 0;
    await montar(tester, onQuitar: () => quitadas++);
    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(quitadas, 1);

    await montar(tester);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('el N° op. va al lado del logo, entra en 320 px y toma su foco',
      (tester) async {
    final ref = TextEditingController(text: '482913');
    final refFoco = FocusNode();
    final monto = TextEditingController(text: '1,250.00');
    final montoFoco = FocusNode();
    addTearDown(ref.dispose);
    addTearDown(refFoco.dispose);
    addTearDown(monto.dispose);
    addTearDown(montoFoco.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            // 320 px de teléfono: (320 - 24 - 8) / 2.
            width: 144,
            child: FichaPago(
              label: 'Yape',
              logo: const SizedBox(width: 20, height: 24),
              controller: monto,
              focusNode: montoFoco,
              refController: ref,
              refFocusNode: refFoco,
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('482913'), findsOneWidget);
    await tester.tap(find.text('Op.'));
    await tester.pump();
    expect(refFoco.hasFocus, isTrue);
    expect(montoFoco.hasFocus, isFalse);
  });

  testWidgets('"Otro método" dispara su acción', (tester) async {
    var abierto = false;
    await montar(tester, onAgregar: () => abierto = true);
    await tester.tap(find.text('Otro método'));
    expect(abierto, isTrue);
  });
}
