import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/menu_drawer_catalogo.dart';
import 'package:syncronize/features/empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;
import 'package:syncronize/features/usuario/data/models/permisos_por_rol_model.dart';

/// La ficha de usuario ofrece solo los accesos y opciones de menú que el rol
/// puede ver, con los permisos que calcula el backend.
///
/// Caso 19-09 (beta): a una técnica se le dejó marcada "Venta Rápida" —que su
/// rol no ve— y desmarcadas "Órdenes de Servicio", "Servicios" y "Productos".
/// Terminó sin ningún acceso rápido y sin Órdenes en el menú.
void main() {
  // Forma de `GET /usuarios/permisos-por-rol` (recortada a lo que importa).
  final modelo = PermisosPorRolModel.fromJson({
    'roles': {
      'TECNICO': {
        'canViewProducts': false,
        'canViewServices': true,
        'canManageServices': true,
        'canViewClients': true,
        'canManageOrders': true,
        'canManageVentas': false,
        'canViewCaja': false,
      },
      'CAJERO': {
        'canViewProducts': true,
        'canManageVentas': true,
        'canViewVentas': true,
        'canViewCaja': true,
        'canManageCaja': true,
        'canManageInvoices': true,
      },
    },
    'granulares': {
      'caja.abrir': ['canViewCaja', 'canManageCaja', 'canAbrirCaja'],
      'devolucion.crear': ['canManageDevoluciones'],
      'cotizacion.crear': [
        'canViewProducts',
        'canViewCotizaciones',
        'canManageCotizaciones',
      ],
    },
  });

  List<String> accesosDe(String rol, [List<String> especiales = const []]) {
    final p = modelo.paraUsuario(rol, especiales)!;
    return AccesosRapidosCatalogo.items
        .map((e) => e.$1)
        .where((id) => AccesosRapidosCatalogo.puedeVer(id, p))
        .toList();
  }

  List<String> menuDe(String rol) {
    final p = modelo.paraUsuario(rol, const [])!;
    return MenuDrawerCatalogo.todosLosIds
        .where((id) => MenuDrawerCatalogo.puedeVer(id, p))
        .toList();
  }

  test('🔴 al TECNICO se le ofrecen Servicios y Órdenes, y no Venta Rápida', () {
    expect(accesosDe('TECNICO'), [
      AccesosRapidosCatalogo.servicios,
      AccesosRapidosCatalogo.ordenesServicio,
    ]);
  });

  test('🔴 con "Crear cotizaciones" se le suman Cotizaciones y Productos', () {
    final accesos = accesosDe('TECNICO', ['cotizacion.crear']);
    expect(accesos, contains(AccesosRapidosCatalogo.cotizaciones));
    expect(accesos, contains(AccesosRapidosCatalogo.productos));
    // Sigue sin vender.
    expect(accesos, isNot(contains(AccesosRapidosCatalogo.ventaRapida)));
  });

  test('🔴 en el menú, al TECNICO se le ofrece Servicios y nada de caja o ventas',
      () {
    final menu = menuDe('TECNICO');
    expect(menu, contains(AccesosRapidosCatalogo.ordenesServicio));
    expect(menu, contains(MenuDrawerCatalogo.serviciosCitas));
    expect(menu, isNot(contains(AccesosRapidosCatalogo.caja)));
    expect(menu, isNot(contains(AccesosRapidosCatalogo.ventaRapida)));
    // Inventario es de quien gestiona productos.
    expect(menu, isNot(contains(MenuDrawerCatalogo.invKardex)));
  });

  test('un permiso especial suma lo suyo: con "Abrir caja" aparece Caja', () {
    expect(accesosDe('TECNICO'), isNot(contains(AccesosRapidosCatalogo.caja)));
    expect(
      accesosDe('TECNICO', ['caja.abrir']),
      contains(AccesosRapidosCatalogo.caja),
    );
  });

  test('el CAJERO ve Venta Rápida y Caja', () {
    expect(accesosDe('CAJERO'), contains(AccesosRapidosCatalogo.ventaRapida));
    expect(accesosDe('CAJERO'), contains(AccesosRapidosCatalogo.caja));
  });

  test('un rol que el backend no conoce da null: la ficha ofrece todo', () {
    expect(modelo.paraUsuario('ROL_NUEVO', const []), isNull);
  });

  test('🔴 todo acceso rápido y todo ítem del menú tiene su regla', () {
    // Un id sin regla se considera visible para cualquiera: sería una casilla
    // que se ofrece a todos los roles.
    for (final (id, _) in AccesosRapidosCatalogo.items) {
      expect(AccesosRapidosCatalogo.reglas.containsKey(id), isTrue, reason: id);
    }
    for (final id in MenuDrawerCatalogo.todosLosIds) {
      expect(MenuDrawerCatalogo.reglas.containsKey(id), isTrue, reason: id);
    }
  });
}
