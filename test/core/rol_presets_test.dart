import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/granular_permissions_catalog.dart';
import 'package:syncronize/core/utils/menu_drawer_catalogo.dart';
import 'package:syncronize/core/utils/rol_presets.dart';
import 'package:syncronize/features/empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;

/// Los presets por rol.
///
/// Lo que se fija acá es que no vuelvan a ensuciarse. El preset anterior del
/// VENDEDOR le ocultaba Facturación, Configuración y Caja Chica: tres pantallas
/// que su rol no le mostraba de todos modos. Eran líneas que no hacían nada y
/// daban la impresión de un control que no existía.
///
/// 🔴 Y sobre todo: todo id listado tiene que EXISTIR. Con la validación del
/// backend ya activa, un id fuera de catálogo hace fallar con 400 el alta del
/// usuario — o sea que un typo acá rompe una pantalla de administración.
void main() {
  final idsDashboard = AccesosRapidosCatalogo.items.map((e) => e.$1).toSet();
  final idsMenu = MenuDrawerCatalogo.todosLosIds.toSet();
  final idsGranulares =
      kGranularPermissionsCatalog.map((p) => p.id).toSet();

  test('🔴 todo id de un preset existe en su catálogo', () {
    kRolPresets.forEach((rol, preset) {
      for (final id in preset.accesosRapidosOcultos) {
        expect(idsDashboard.contains(id), isTrue,
            reason: '$rol: "$id" no está en el catálogo del dashboard');
      }
      for (final id in preset.menuOcultos) {
        expect(idsMenu.contains(id), isTrue,
            reason: '$rol: "$id" no está en el catálogo del menú');
      }
      for (final id in preset.permisosEspeciales) {
        expect(idsGranulares.contains(id), isTrue,
            reason: '$rol: "$id" no es un permiso granular válido');
      }
    });
  });

  test('un preset no repite el mismo id dos veces', () {
    kRolPresets.forEach((rol, preset) {
      final todos = [
        ...preset.accesosRapidosOcultos,
        ...preset.menuOcultos,
      ];
      expect(todos.length, todos.toSet().length, reason: rol);
    });
  });

  test('el CAJERO abre y cierra caja; el resto no, salvo que se lo den', () {
    expect(kRolPresets['CAJERO']!.puedeAbrirCaja, isTrue);
    expect(kRolPresets['CAJERO']!.puedeCerrarCaja, isTrue);
    expect(kRolPresets['VENDEDOR']!.puedeAbrirCaja, isFalse);
    expect(kRolPresets['CONTADOR']!.puedeAbrirCaja, isFalse);
  });

  test('el CONTADOR no arranca con las pantallas de vender', () {
    final ocultos = kRolPresets['CONTADOR']!.accesosRapidosOcultos;
    expect(ocultos, contains(AccesosRapidosCatalogo.ventaRapida));
    expect(ocultos, contains(AccesosRapidosCatalogo.ventaAvanzada));
    expect(ocultos, contains(AccesosRapidosCatalogo.colaPos));
  });

  test('un rol sin preset devuelve uno vacío, no revienta', () {
    final p = presetParaRol('ROL_QUE_NO_EXISTE');
    expect(p.accesosRapidosOcultos, isEmpty);
    expect(p.menuOcultos, isEmpty);
    expect(p.permisosEspeciales, isEmpty);
  });
}
