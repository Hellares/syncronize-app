import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/role_navigation_helper.dart';

/// Dónde aterriza cada rol al entrar.
void main() {
  test('🔴 el TECNICO cae en el dashboard, no en Órdenes', () {
    // Caía en /empresa/ordenes y ahí el menú le quedaba con tres ítems,
    // porque los permisos llegan con el contexto de la empresa. Desde el
    // dashboard entra a Órdenes con todo cargado.
    expect(
      RoleNavigationHelper.getRouteForRole('TECNICO'),
      '/empresa/dashboard',
    );
  });

  test('los roles con pantalla propia siguen cayendo en la suya', () {
    expect(RoleNavigationHelper.getRouteForRole('CLIENTE'), '/empresa/cliente');
    expect(
      RoleNavigationHelper.getRouteForRole('CONTADOR'),
      '/empresa/ventas/analytics',
    );
    expect(
      RoleNavigationHelper.getRouteForRole('REPARTIDOR'),
      '/empresa/delivery',
    );
  });

  test('sin rol, o con uno desconocido, al dashboard', () {
    expect(RoleNavigationHelper.getRouteForRole(null), '/empresa/dashboard');
    expect(
      RoleNavigationHelper.getRouteForRole('ROL_NUEVO'),
      '/empresa/dashboard',
    );
  });

  /// 🔴 El contexto trae los permisos, y de ahí salen el menú y los accesos.
  /// Lo cargaba SOLO el dashboard, así que cualquier rol que aterrizara en
  /// otra pantalla entraba con el menú vacío. Se lee el código fuente porque
  /// montar el login pide bloc, storage y red.
  test('🔴 quien manda a la empresa carga antes el contexto', () {
    for (final archivo in [
      'lib/features/auth/presentation/pages/login_page.dart',
      'lib/features/empresa/presentation/pages/empresa_selection_page.dart',
      'lib/features/empresa/presentation/widgets/empresa_switch_bottom_sheet.dart',
    ]) {
      final fuente = File(archivo).readAsStringSync();
      expect(
        fuente.contains('loadEmpresaContext'),
        isTrue,
        reason: '$archivo navega a la empresa sin cargar el contexto: el '
            'usuario entra con el menú incompleto',
      );
    }
  });
}
