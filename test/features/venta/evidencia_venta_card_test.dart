import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/venta/presentation/widgets/evidencia_venta_card.dart';

/// Fotos de la venta en la pantalla de cobro.
///
/// 🔴 Test de MONTAJE: `flutter analyze` no ve el layout, y el cobro es un
/// scroll — se monta en el mismo árbol (`SingleChildScrollView > Column >
/// Padding`). Sin `ventaId` el widget no toca la red al montarse, así que no
/// hace falta el locator. A 500 de ancho: las fuentes de la app no cargan en
/// los tests.
void main() {
  const leyenda = 'Cómo se vendió y cómo se entrega. Uso interno.';

  Future<void> montar(WidgetTester tester, {required bool compacto}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 10, 2),
                  child: EvidenciaVentaCard(
                    compacto: compacto,
                    onIdsChange: (_) {},
                    onSubiendoChange: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('compacto (cobro): solo la leyenda y el botón, sin tarjeta ni título', (tester) async {
    await montar(tester, compacto: true);

    expect(tester.takeException(), isNull);
    expect(find.text(leyenda), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(find.text('Fotos de la venta'), findsNothing);
    expect(find.textContaining('Sin fotos'), findsNothing);
    // La tarjeta era un Container con borde: en compacto no hay ninguno.
    expect(
      find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border != null),
      findsNothing,
    );
  });

  testWidgets('compacto ocupa menos alto que la tarjeta completa', (tester) async {
    await montar(tester, compacto: false);
    final alto = tester.getSize(find.byType(EvidenciaVentaCard)).height;

    await montar(tester, compacto: true);
    final altoCompacto = tester.getSize(find.byType(EvidenciaVentaCard)).height;

    expect(altoCompacto, lessThan(alto));
  });

  testWidgets('la tarjeta completa (detalle de la venta) no cambia', (tester) async {
    await montar(tester, compacto: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Fotos de la venta'), findsOneWidget);
    expect(find.text(leyenda), findsOneWidget);
    expect(find.text('Sin fotos. Sirven de respaldo ante un reclamo.'), findsOneWidget);
  });
}
