import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/empresa/data/models/empresa_permissions_model.dart';

/// Qué le ofrece la orden de servicio al técnico (19-09).
///
/// El backend ya rechaza asignar técnico y la plata de la orden; esto fija
/// que el app tampoco se lo ofrezca, que es la otra mitad: un botón que
/// siempre termina en 403 es peor que no tenerlo.
void main() {
  group('permisos nuevos en el contexto', () {
    test('se leen del backend', () {
      final p = EmpresaPermissionsModel.fromJson({
        'canManageOrders': true,
        'canAsignarTecnico': true,
        'canGestionarCostosOrden': true,
      });
      expect(p.canAsignarTecnico, isTrue);
      expect(p.canGestionarCostosOrden, isTrue);
    });

    test('🔴 un backend que todavía no los manda NO los concede', () {
      // El app se publica después del backend, pero al revés tampoco puede
      // abrirle al técnico lo que no le corresponde.
      final p = EmpresaPermissionsModel.fromJson({'canManageOrders': true});
      expect(p.canAsignarTecnico, isFalse);
      expect(p.canGestionarCostosOrden, isFalse);
    });
  });

  /// 🔴 Lee el CÓDIGO FUENTE de la pantalla, como el test del drawer: son
  /// 5800 líneas que necesitan contexto, blocs y una orden cargada para
  /// montarse. Lo que se fija es que las tres piezas sigan detrás de su
  /// permiso; si alguien las saca, el técnico vuelve a ver botones que el
  /// backend le rechaza.
  group('la pantalla de detalle esconde lo que no es suyo', () {
    final fuente = File(
      'lib/features/servicio/presentation/pages/orden_servicio_detail_page.dart',
    ).readAsStringSync();

    test('la tarjeta de costos va detrás del permiso', () {
      expect(
        fuente.contains('if (_puedeCostosOrden) ...['),
        isTrue,
        reason: 'El resumen de costos tiene que depender del permiso',
      );
    });

    test('el diálogo de cambio de estado no ofrece costos sin permiso', () {
      expect(fuente.contains('final showCostos = _puedeCostosOrden &&'), isTrue);
    });

    test('🔴 Cobrar tampoco se le ofrece: cobra la caja', () {
      // Se le veía en REPARADO y LISTO_ENTREGA. Lleva a Venta Rápida, que el
      // técnico no puede usar, y el cobro es de quien maneja la plata.
      expect(
        fuente.contains('final showCobrar = _puedeCostosOrden &&'),
        isTrue,
        reason: 'El botón Cobrar tiene que depender del permiso de costos',
      );
    });

    test('asignar técnico va detrás del permiso', () {
      expect(fuente.contains('if (_puedeAsignarTecnico)'), isTrue);
    });

    test('los permisos salen del contexto de empresa, no de un rol a mano', () {
      expect(
        fuente.contains('_permisos?.canAsignarTecnico ?? false'),
        isTrue,
      );
      expect(
        fuente.contains('_permisos?.canGestionarCostosOrden ?? false'),
        isTrue,
      );
    });
  });
}
