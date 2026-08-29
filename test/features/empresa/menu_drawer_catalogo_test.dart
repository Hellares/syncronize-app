import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/menu_drawer_catalogo.dart';
import 'package:syncronize/features/empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;

/// Paridad entre el árbol que ve el admin y los ítems reales del drawer.
///
/// El admin tilda checkboxes en la ficha de usuario para ocultarle ítems del
/// menú. Si el árbol y el drawer se separan pasa una de dos cosas, y las dos
/// son silenciosas:
///
///  - Un id en el árbol SIN tile → un checkbox que no hace nada. Es
///    exactamente el bug que tuvimos con los accesos rápidos: 21 casillas
///    contra 16 botones.
///  - Un tile con id que NO está en el árbol → un ítem que el admin no puede
///    ocultar aunque quiera, y sin forma de enterarse.
///
/// 🔴 Este test lee el CÓDIGO FUENTE del drawer, que es poco común. Se hizo
/// así porque el árbol de nodos se construye dentro de un método privado que
/// necesita `BuildContext` y permisos: enumerarlo desde un test exigiría
/// refactorizar el drawer solo para poder mirarlo. El escaneo es determinista
/// y corre en milisegundos.
void main() {
  final fuente =
      File('lib/features/empresa/presentation/widgets/empresa_drawer.dart')
          .readAsStringSync();

  /// Ids que el drawer declara, resueltos a su VALOR (no al nombre de la
  /// constante): `ocultableId: MenuDrawerCatalogo.invKardex` → la cadena real.
  Set<String> idsDelDrawer() {
    final nombres = RegExp(
      r'ocultableId: (MenuDrawerCatalogo|AccesosRapidosCatalogo)\.(\w+)',
    ).allMatches(fuente).map((m) => m.group(2)!).toSet();

    // El nombre de la constante se resuelve contra el árbol, que es donde
    // conviven las dos familias de ids.
    final porNombre = <String, String>{};
    final catalogo =
        File('lib/core/utils/menu_drawer_catalogo.dart').readAsStringSync();
    for (final m
        in RegExp(r"static const (\w+) =\s*'([^']+)';").allMatches(catalogo)) {
      porNombre[m.group(1)!] = m.group(2)!;
    }
    final accesos = File(
      'lib/features/empresa/presentation/widgets/accesos_rapidos_section.dart',
    ).readAsStringSync();
    for (final m
        in RegExp(r"static const (\w+) =\s*'([^']+)';").allMatches(accesos)) {
      porNombre[m.group(1)!] = m.group(2)!;
    }

    return nombres
        .map((n) => porNombre[n])
        .whereType<String>()
        .toSet();
  }

  test('🔴 todo id del árbol tiene su ítem en el drawer', () {
    final enElDrawer = idsDelDrawer();
    final sinTile =
        MenuDrawerCatalogo.todosLosIds.where((id) => !enElDrawer.contains(id));

    expect(
      sinTile,
      isEmpty,
      reason: 'Son checkboxes que el admin puede tildar y no ocultan nada',
    );
  });

  _guardiaListaCompartida();
  _paridadConElBackend();

  test('el árbol no tiene ids repetidos', () {
    final ids = MenuDrawerCatalogo.todosLosIds;
    expect(ids.length, ids.toSet().length);
  });

  test('los ids propios del menú van prefijados, para no chocar con los del dashboard', () {
    // Un choque haría que ocultar un botón del dashboard escondiera un ítem de
    // menú que no tiene nada que ver.
    final propios = RegExp(r"static const \w+ = '(menu\.[^']+)';")
        .allMatches(
            File('lib/core/utils/menu_drawer_catalogo.dart').readAsStringSync())
        .map((m) => m.group(1)!)
        .toList();

    expect(propios, isNotEmpty);
    for (final id in propios) {
      expect(id.startsWith('menu.'), isTrue, reason: id);
    }
  });
}

/// Los dos catálogos comparten una sola lista de ocultos
/// (`UsuarioSedeRol.accesosRapidosOcultos`). Eso da la paridad buscada —ocultar
/// "Cotizaciones" lo saca del dashboard y del menú— pero abre una trampa: una
/// pantalla que manipule la lista EN BLOQUE puede borrar lo que configuró la
/// otra.
///
/// 🔴 Pasó de verdad: los botones "Marcar/Desmarcar todos" de accesos rápidos
/// hacían `clear()` sobre la lista compartida, así que tocar uno borraba toda
/// la configuración del menú lateral sin ningún aviso.
void _guardiaListaCompartida() {
  test('🔴 los botones en bloque de accesos rápidos no tocan los ids del menú',
      () {
    // Se afirma en POSITIVO —que usen `removeAll` acotado al catálogo del
    // dashboard— en vez de prohibir `clear()`: en estos archivos hay `clear()`
    // legítimos (controllers, y el "aplicar configuración estándar", que SÍ
    // reemplaza todo a propósito y por eso el preset ahora define también
    // `menuOcultos`).
    for (final archivo in [
      'lib/features/usuario/presentation/pages/usuario_form_page.dart',
      'lib/features/usuario/presentation/widgets/asignar_rol_dialog.dart',
    ]) {
      final fuente = File(archivo).readAsStringSync();
      expect(
        fuente.contains('removeAll(AccesosRapidosCatalogo.items'),
        isTrue,
        reason: '$archivo: el botón "Marcar todos" tiene que sacar SOLO los ids '
            'del dashboard. Si limpia la lista entera, se lleva puesto lo '
            'configurado del menú lateral, que vive en la misma lista.',
      );
    }
  });
}

/// Paridad con el catálogo espejo del BACKEND.
///
/// `elementos-ocultables.catalog.ts` repite a mano estos mismos ids para poder
/// rechazar los que no existen. Ya nos pasó dos veces que un catálogo
/// duplicado se desincronice en silencio, así que acá se compara.
///
/// 🔴 Si el repo del backend no está al lado, el test se SALTA en vez de
/// fallar: no todos los checkouts tienen los dos. Cuando están los dos —que es
/// el caso normal de trabajo— la comparación corre.
void _paridadConElBackend() {
  test('🔴 el catálogo del backend tiene los mismos ids', () {
    final archivo = File(
      '../backend/src/auth/services/elementos-ocultables.catalog.ts',
    );
    if (!archivo.existsSync()) {
      markTestSkipped('El repo del backend no está en ../backend');
      return;
    }

    final fuente = archivo.readAsStringSync();
    final enBackend = RegExp(r"^\s*'([^']+)',", multiLine: true)
        .allMatches(fuente)
        .map((m) => m.group(1)!)
        .toSet();

    final enApp = MenuDrawerCatalogo.todosLosIds.toSet()
      ..addAll(AccesosRapidosCatalogo.items.map((e) => e.$1));

    expect(
      enApp.difference(enBackend),
      isEmpty,
      reason: 'Ids que el app manda y el backend va a rechazar con 400',
    );
    expect(
      enBackend.difference(enApp),
      isEmpty,
      reason: 'Ids que el backend acepta y ya no existen en el app',
    );
  });
}
