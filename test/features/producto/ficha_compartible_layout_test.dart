/// La ficha que se comparte se CAPTURA como imagen: un desborde no se ve como
/// la franja amarilla de una pantalla, se le manda al cliente dentro del PNG.
///
/// 🔴 `flutter analyze` no ve errores de layout. Este test los ve: si una fila
/// desborda, el pump falla.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/presentation/widgets/ficha_compartible.dart';

void main() {
  Future<void> pumpFicha(WidgetTester tester, FichaCompartible ficha) async {
    // El lienzo real: 360 de ancho y alto libre, igual que en la vista previa.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: Center(child: ficha)),
        ),
      ),
    );
  }

  testWidgets('la ficha entra sin desbordes con textos largos', (tester) async {
    await pumpFicha(
      tester,
      const FichaCompartible(
        titulo: 'EDREDÓN 2 PLAZAS CARNERITO ROSADO CON DISEÑO BORDADO Y '
            'ACABADO PREMIUM EN MICROFIBRA',
        codigo: 'EDR-2P-0001-LARGO',
        precio: 129.9,
        precioAnterior: 189.9,
        empresaNombre: 'COMERCIAL E IMPORTACIONES JAYLILAND DEL NORTE',
        empresaTelefono: '987 654 321',
        textoPie: 'Gracias por su preferencia — cambios dentro de los 7 días '
            'con boleta',
        plantillas: [],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('JAYLILAND'), findsOneWidget);
  });

  testWidgets('sin teléfono ni pie configurado tampoco desborda',
      (tester) async {
    await pumpFicha(
      tester,
      const FichaCompartible(
        titulo: 'TOALLA',
        precio: 29.9,
        empresaNombre: 'CJ MOVILS',
        plantillas: [],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Consulte disponibilidad'), findsOneWidget);
  });

  testWidgets('la rebaja muestra el porcentaje de descuento', (tester) async {
    await pumpFicha(
      tester,
      const FichaCompartible(
        titulo: 'COBERTOR',
        precio: 150,
        precioAnterior: 200,
        empresaNombre: 'JAYLILAND',
        plantillas: [],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('-25%'), findsOneWidget);
  });
}
