import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `_emit` no puede repintar un sheet que ya se fue (20-09).
///
/// Crash real en el celular: elegir un servicio del catálogo en el cuerpo de
/// la pantalla tiraba `setState() called after dispose()` sobre el
/// `StatefulBuilder` de un sheet cerrado. El setter de ese sheet es un `State`
/// que la pantalla NO controla, así que hay que preguntar por su contexto
/// antes de usarlo.
///
/// 🔑 Lee el CÓDIGO FUENTE, como los otros tests de esta pantalla: son 5800
/// líneas que necesitan contexto y blocs para montarse.
void main() {
  final fuente = File(
    'lib/features/servicio/presentation/pages/orden_servicio_form_page.dart',
  ).readAsStringSync();

  final cuerpoEmit = RegExp(r'void _emit\(\[VoidCallback\? fn\]\) \{(.*?)\n  \}',
          dotAll: true)
      .firstMatch(fuente)
      ?.group(1);

  test('_emit existe y se puede leer', () {
    expect(cuerpoEmit, isNotNull);
  });

  test('🔴 el setState del sheet va detrás de un mounted', () {
    final posGuarda = cuerpoEmit!.indexOf('_sheetCtx?.mounted');
    final posLlamada = cuerpoEmit.indexOf('_sheetSetState?.call');
    expect(posGuarda, greaterThanOrEqualTo(0),
        reason: 'sin la guarda vuelve el setState() called after dispose()');
    expect(posLlamada, greaterThan(posGuarda),
        reason: 'la guarda tiene que estar ANTES de usar el setter');
  });

  test('el setState de la pantalla también pregunta por mounted', () {
    // Los callbacks del dropdown corren en un post-frame: pueden caer después
    // de que la pantalla se cerró.
    expect(cuerpoEmit!.contains('if (mounted)'), isTrue);
  });

  test('el contexto del sheet se guarda y se limpia con su setter', () {
    // Si se guarda pero no se limpia, la guarda mira un contexto viejo.
    expect(fuente.contains('_sheetCtx = ctx;'), isTrue);
    expect(fuente.contains('_sheetCtx = null;'), isTrue);
  });
}
