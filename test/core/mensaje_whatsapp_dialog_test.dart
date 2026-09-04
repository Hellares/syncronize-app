import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/whatsapp_apps.dart';
import 'package:syncronize/core/widgets/mensaje_whatsapp_dialog.dart';

/// Un PNG de 1×1 transparente: el adjunto de los tests tiene que ser un
/// archivo de verdad, pero su contenido no importa.
const _pngMinimo = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

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
      List<AppWhatsapp> apps = const [],
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
                  appsDisponibles: apps,
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

    testWidgets('🔴 con las DOS apps instaladas se ofrece elegir cuál abrir',
        (tester) async {
      // Un celular con dos chips tiene una cuenta en cada app: mandar el
      // mensaje del negocio por la personal es un error que se descubre
      // cuando el cliente contesta al número equivocado.
      await abrirCon(tester, directo: false, apps: AppWhatsapp.values);

      expect(find.text('Abrir con'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('WhatsApp Business'), findsOneWidget);
    });

    testWidgets('con UNA sola app no hay nada que preguntar', (tester) async {
      await abrirCon(tester, directo: false, apps: const [AppWhatsapp.normal]);

      expect(find.text('Abrir con'), findsNothing);
    });

    testWidgets('con envío directo no se pregunta: no se abre ninguna app',
        (tester) async {
      await abrirCon(tester, directo: true, apps: AppWhatsapp.values);

      expect(find.text('Abrir con'), findsNothing);
    });

    testWidgets('con vinculación se puede adjuntar', (tester) async {
      await abrirCon(tester, directo: true);

      expect(find.text('Galería'), findsOneWidget);
      expect(find.text('Cámara'), findsOneWidget);
    });
  });

  /// Compartir una ficha o un catálogo: el destinatario NO sale de una ficha
  /// de cliente —quien pregunta por un producto puede no estar registrado—,
  /// así que el número se escribe acá y el archivo ya viene armado.
  group('número escrito y archivo adjunto', () {
    late File archivo;

    setUp(() {
      archivo = File(
        '${Directory.systemTemp.path}/ficha_test_${DateTime.now().microsecondsSinceEpoch}.png',
      )..writeAsBytesSync(_pngMinimo);
    });

    tearDown(() {
      if (archivo.existsSync()) archivo.deleteSync();
    });

    Future<List<MensajeRedactado?>> abrirConNumero(
      WidgetTester tester, {
      bool directo = false,
      bool conAdjunto = true,
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
                    textoInicial: 'Hola, te comparto *EDREDÓN 2 PLAZAS*.',
                    destinatario: 'un cliente',
                    envioDirecto: directo,
                    pedirNumero: true,
                    adjunto: conAdjunto
                        ? (
                            archivo: archivo,
                            nombre: 'catalogo.pdf',
                            detalle: '6 productos · 240 KB',
                            esPdf: true,
                          )
                        : null,
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

    testWidgets('un número inválido NO cierra el cuadro', (tester) async {
      // Cerrar y avisar después obliga a reescribir el mensaje entero por un
      // dígito de menos.
      final buzon = await abrirConNumero(tester);
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.tap(find.text('Abrir WhatsApp'));
      await tester.pump();

      expect(buzon, isEmpty);
      expect(find.text('Escribí un celular válido'), findsOneWidget);
    });

    testWidgets('el celular escrito vuelve con el mensaje', (tester) async {
      final buzon = await abrirConNumero(tester);
      await tester.enterText(find.byType(TextField).first, '987 654 321');
      await tester.tap(find.text('Abrir WhatsApp'));
      await tester.pumpAndSettle();

      expect(buzon.single?.numero, '987 654 321');
      expect(buzon.single?.texto, contains('EDREDÓN'));
    });

    testWidgets('🔴 sin vinculación se avisa que el archivo NO viaja',
        (tester) async {
      // wa.me solo prellena texto. Callarlo termina con el usuario creyendo
      // que mandó el catálogo cuando solo mandó el saludo.
      await abrirConNumero(tester);

      expect(find.text('catalogo.pdf'), findsOneWidget);
      expect(
        find.textContaining('WhatsApp no acepta archivos por enlace'),
        findsOneWidget,
      );
    });

    testWidgets('con vinculación el adjunto se anuncia como enviado',
        (tester) async {
      await abrirConNumero(tester, directo: true);

      expect(find.text('6 productos · 240 KB'), findsOneWidget);
      // Un archivo por mensaje: con el adjunto ya armado no se ofrece elegir
      // otro.
      expect(find.text('Galería'), findsNothing);
      expect(find.text('Cámara'), findsNothing);
    });

    testWidgets('sin adjunto sí se puede elegir una imagen', (tester) async {
      await abrirConNumero(tester, directo: true, conAdjunto: false);

      expect(find.text('Galería'), findsOneWidget);
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
