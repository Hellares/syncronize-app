import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/servicio/domain/entities/configuracion_campo.dart';
import 'package:syncronize/features/servicio/presentation/widgets/dynamic_form_renderer.dart';

/// Los campos compactos de la plantilla comparten fila (20-09).
///
/// El caso que lo pidió: una plantilla de estado de componentes con 5 campos
/// de texto gastaba 5 renglones del sheet de "Datos adicionales". Van de a 3
/// y lo que sobra baja, sin dejar una fila con uno solo.
///
/// 🔑 Se monta en el MISMO árbol que la pantalla real —`SingleChildScrollView`
/// > `Column`— porque `flutter analyze` no ve el layout: acá adentro hay
/// `Expanded` dentro de `Row`, que revienta si el ancho no está acotado.
void main() {
  ConfiguracionCampo campo(
    String nombre, {
    String tipo = 'TEXTO',
    bool permiteOtro = false,
  }) {
    final ahora = DateTime(2026, 9, 20);
    return ConfiguracionCampo(
      id: 'c_$nombre',
      empresaId: 'emp_1',
      nombre: nombre,
      tipoCampo: tipo,
      permiteOtro: permiteOtro,
      creadoEn: ahora,
      actualizadoEn: ahora,
    );
  }

  /// Monta el renderer como lo monta el sheet de la orden.
  Future<void> montar(
    WidgetTester tester,
    List<ConfiguracionCampo> campos, {
    double ancho = 390,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: ancho,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DynamicFormRenderer(
                    campos: campos,
                    values: const {},
                    empresaId: 'emp_1',
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  /// La y de la etiqueta de cada campo: dos campos en la misma fila la
  /// comparten. Se mira la POSICIÓN, no el ancho, porque las fuentes de la app
  /// no se cargan en los tests y medir píxeles no probaría nada.
  List<double> ys(WidgetTester tester, List<String> nombres) => nombres
      .map((n) => tester.getTopLeft(find.text(n).first).dy)
      .toList(growable: false);

  testWidgets('5 campos de texto quedan 3 + 2 y no tumban la pantalla',
      (tester) async {
    final campos = [
      campo('PANTALLA'),
      campo('TECLADO'),
      campo('BATERIA'),
      campo('CARCASA'),
      campo('PUERTOS'),
    ];
    await montar(tester, campos);

    expect(tester.takeException(), isNull);
    final y = ys(tester, const [
      'PANTALLA',
      'TECLADO',
      'BATERIA',
      'CARCASA',
      'PUERTOS',
    ]);
    // Primera fila: los tres a la misma altura.
    expect(y[0], y[1]);
    expect(y[1], y[2]);
    // Segunda fila: los dos que sobran, más abajo y entre ellos parejos.
    expect(y[3], greaterThan(y[0]));
    expect(y[3], y[4]);
  });

  testWidgets('4 campos van 2 + 2: ninguna fila queda con uno solo',
      (tester) async {
    await montar(tester, [
      campo('UNO'),
      campo('DOS'),
      campo('TRES'),
      campo('CUATRO'),
    ]);

    expect(tester.takeException(), isNull);
    final y = ys(tester, const ['UNO', 'DOS', 'TRES', 'CUATRO']);
    expect(y[0], y[1]);
    expect(y[2], greaterThan(y[0]));
    expect(y[2], y[3]);
  });

  testWidgets('un campo ancho CORTA el grupo y se queda solo en su fila',
      (tester) async {
    await montar(tester, [
      campo('UNO'),
      campo('DOS'),
      campo('DIAGNOSTICO', tipo: 'TEXTO_AREA'),
      campo('TRES'),
      campo('CUATRO'),
    ]);

    expect(tester.takeException(), isNull);
    final y = ys(tester, const ['UNO', 'DOS', 'DIAGNOSTICO', 'TRES', 'CUATRO']);
    // UNO y DOS comparten fila; el área de texto baja sola; TRES y CUATRO
    // arman su propia fila DESPUÉS, sin saltearse el orden de la plantilla.
    expect(y[0], y[1]);
    expect(y[2], greaterThan(y[0]));
    expect(y[3], greaterThan(y[2]));
    expect(y[3], y[4]);
  });

  testWidgets('un combo con "Otro" no comparte fila', (tester) async {
    await montar(tester, [
      campo('MARCA', tipo: 'OPCION_SIMPLES', permiteOtro: true),
      campo('MODELO'),
    ]);

    expect(tester.takeException(), isNull);
    final y = ys(tester, const ['MARCA', 'MODELO']);
    expect(y[1], greaterThan(y[0]));
  });

  testWidgets('en un teléfono angosto caen a 2 por fila', (tester) async {
    // 320 de pantalla − 32 de padding = 288 útiles: tres celdas darían 90 px
    // y no se leen.
    await montar(
      tester,
      [campo('UNO'), campo('DOS'), campo('TRES')],
      ancho: 320,
    );

    expect(tester.takeException(), isNull);
    final y = ys(tester, const ['UNO', 'DOS', 'TRES']);
    expect(y[0], y[1]);
    expect(y[2], greaterThan(y[0]));
  });
}
