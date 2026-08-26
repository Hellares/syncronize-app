import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/widgets/mensaje_whatsapp_dialog.dart';

void main() {
  const inicial = 'Hola Juan! Le escribimos por su orden *OS-1* (LAPTOP HP).';

  /// Abre el diálogo y devuelve el buzón donde va a caer lo que resuelva.
  ///
  /// 🔴 Un buzón y no el Future del diálogo: dejar el Future sin await y
  /// después llamar a `enterText` rompe con `TestAsyncUtils.guardSync`, y
  /// awaitearlo colgaría el test porque el diálogo sigue abierto.
  Future<List<MensajeRedactado?>> abrir(
    WidgetTester tester, {
    List<AtajoMensaje> atajos = const [],
  }) async {
    final buzon = <MensajeRedactado?>[];
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

    expect(buzon.single?.texto, 'Mensaje corregido');
    expect(buzon.single?.imagen, isNull);
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

  group('modo de envío', () {
    Future<void> abrirCon(
      WidgetTester tester, {
      required bool directo,
      String? numeroEmpresa,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => mostrarDialogoMensajeWhatsapp(
                  context,
                  textoInicial: inicial,
                  destinatario: 'Juan',
                  envioDirecto: directo,
                  numeroEmpresa: numeroEmpresa,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('sin vinculación anuncia que abre WhatsApp', (tester) async {
      await abrirCon(tester, directo: false);

      expect(find.text('Abrir WhatsApp'), findsOneWidget);
      expect(find.text('Se abre WhatsApp con el texto ya escrito'),
          findsOneWidget);
      expect(find.text('Enviar'), findsNothing);
    });

    testWidgets('🔴 con vinculación anuncia que sale desde el sistema',
        (tester) async {
      // El usuario tiene que saber ANTES de escribir si el mensaje se va solo
      // o si todavía le falta darle enviar en WhatsApp.
      await abrirCon(tester, directo: true, numeroEmpresa: '51901168935');

      expect(find.text('Enviar'), findsOneWidget);
      expect(find.text('Se envía desde el WhatsApp de la empresa'),
          findsOneWidget);
      expect(find.textContaining('51901168935'), findsOneWidget);
      expect(find.text('Abrir WhatsApp'), findsNothing);
    });

    testWidgets('sin número de empresa el aviso igual se muestra',
        (tester) async {
      await abrirCon(tester, directo: true);

      expect(find.text('Enviar'), findsOneWidget);
      expect(
        find.text('Sale del WhatsApp de la empresa sin salir de la app'),
        findsOneWidget,
      );
    });

    // 🔴 Dos tests y no uno con los dos casos: un segundo `pumpWidget` sobre
    // el mismo árbol REUSA el Navigator, así que el primer diálogo sigue
    // arriba y el tap siguiente pega en su barrier en vez de abrir otro.
    testWidgets('🔴 sin vinculación NO se ofrece adjuntar', (tester) async {
      // wa.me no acepta archivos: ofrecer el botón sería mentir.
      await abrirCon(tester, directo: false);

      expect(find.text('Galería'), findsNothing);
      expect(find.text('Cámara'), findsNothing);
    });

    testWidgets('con vinculación se puede adjuntar', (tester) async {
      await abrirCon(tester, directo: true);

      expect(find.text('Galería'), findsOneWidget);
      expect(find.text('Cámara'), findsOneWidget);
    });
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
