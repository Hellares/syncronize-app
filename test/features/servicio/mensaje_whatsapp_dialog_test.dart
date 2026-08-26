import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/servicio/presentation/widgets/mensaje_whatsapp_dialog.dart';

void main() {
  const inicial = 'Hola Juan! Le escribimos por su orden *OS-1* (LAPTOP HP).';

  /// Abre el diálogo y devuelve el buzón donde va a caer lo que resuelva.
  ///
  /// 🔴 Un buzón y no el Future del diálogo: dejar el Future sin await y
  /// después llamar a `enterText` rompe con `TestAsyncUtils.guardSync`, y
  /// awaitearlo colgaría el test porque el diálogo sigue abierto.
  Future<List<String?>> abrir(
    WidgetTester tester, {
    List<AtajoMensaje> atajos = const [],
  }) async {
    final buzon = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                buzon.add(await mostrarDialogoMensajeWhatsapp(
                  context,
                  textoInicial: inicial,
                  destinatario: 'Juan',
                  atajos: atajos,
                ));
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return buzon;
  }

  EditableText campo(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText).first);

  testWidgets('🔴 el cursor arranca AL FINAL del texto', (tester) async {
    // Es la razón de existir del diálogo: wa.me abre el chat con el caret en
    // el principio y no hay parámetro para moverlo.
    await abrir(tester);

    final ctrl = campo(tester).controller;
    expect(ctrl.text, inicial);
    expect(ctrl.selection.baseOffset, inicial.length);
    expect(ctrl.selection.isCollapsed, isTrue);
  });

  testWidgets('devuelve el texto editado al abrir WhatsApp', (tester) async {
    final buzon = await abrir(tester);
    await tester.enterText(find.byType(TextField), 'Mensaje corregido');
    await tester.tap(find.text('Abrir WhatsApp'));
    await tester.pumpAndSettle();

    expect(buzon.single, 'Mensaje corregido');
  });

  testWidgets('cancelar no devuelve nada', (tester) async {
    final buzon = await abrir(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(buzon.single, isNull);
  });

  testWidgets('un atajo se agrega al final y deja el cursor ahí',
      (tester) async {
    await abrir(tester, atajos: const [
      (etiqueta: 'Equipo listo', texto: 'Ya está listo para que lo retire.'),
    ]);

    await tester.tap(find.text('Equipo listo'));
    await tester.pump();

    final ctrl = campo(tester).controller;
    expect(ctrl.text, '$inicial Ya está listo para que lo retire.');
    expect(ctrl.selection.baseOffset, ctrl.text.length);
  });

  testWidgets('un mensaje vacío no abre WhatsApp', (tester) async {
    final buzon = await abrir(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Abrir WhatsApp'));
    await tester.pump();

    // El diálogo sigue abierto: nada que enviar.
    expect(find.text('Abrir WhatsApp'), findsOneWidget);
    expect(buzon, isEmpty);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(buzon.single, isNull);
  });
}
