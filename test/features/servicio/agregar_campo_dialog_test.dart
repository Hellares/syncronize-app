import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El diálogo de "Agregar campo" no puede contar el teclado dos veces (20-09).
///
/// Con el diálogo hecho a mano el `insetPadding` le sumaba
/// `viewInsets.bottom`, pero `Dialog` YA se lo suma solo (su
/// `effectivePadding` = `viewInsets` + `insetPadding`): al abrirse el teclado
/// la caja se achicaba al doble de lo que correspondía. Ahora va con
/// `StyledDialog`, que deja ese cálculo en manos de `Dialog`.
///
/// 🔑 Lee el CÓDIGO FUENTE: la página necesita DI y blocs para montarse.
void main() {
  final fuente = File(
    'lib/features/servicio/presentation/pages/plantillas_servicio_page.dart',
  ).readAsStringSync();

  final cuerpo = RegExp(
    r'void _showAddCampoDialog\(PlantillaServicio plantilla\) \{(.*?)\n  \}',
    dotAll: true,
  ).firstMatch(fuente)?.group(1);

  // Sin los comentarios: el de arriba del diálogo NOMBRA justo lo que este
  // test prohíbe, y si no se sacan el test se falla a sí mismo.
  final codigo = (cuerpo ?? '')
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  test('_showAddCampoDialog existe y se puede leer', () {
    expect(cuerpo, isNotNull);
  });

  test('el diálogo es un StyledDialog', () {
    expect(codigo.contains('StyledDialog('), isTrue);
  });

  test('🔴 no se toca el inset con el teclado ni con la barra de navegación',
      () {
    // `Dialog` suma viewInsets por su cuenta y `showDialog` envuelve todo en
    // un SafeArea: sumarlos a mano es contar dos veces.
    expect(codigo.contains('viewInsetsOf'), isFalse,
        reason: 'el teclado ya lo suma Dialog en su effectivePadding');
    expect(codigo.contains('viewPaddingOf'), isFalse,
        reason: 'la barra de navegación ya la deja afuera el SafeArea');
    expect(codigo.contains('insetPadding'), isFalse);
  });

  test('el header y los botones quedan fuera del scroll', () {
    // En StyledDialog solo `content` scrollea; si alguien vuelve a envolver
    // todo en un SingleChildScrollView, los botones se van con el scroll.
    expect(codigo.contains('SingleChildScrollView'), isFalse);
    expect(codigo.contains('content: ['), isTrue);
    expect(codigo.contains('actions: ['), isTrue);
  });
}
