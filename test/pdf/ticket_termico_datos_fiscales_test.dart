import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/servicio/presentation/services/ticket_esc_pos_generator.dart';
import 'package:syncronize/features/venta/presentation/services/ticket_venta_esc_pos_generator.dart';

import 'fixtures/orden_servicio_fixture.dart';
import 'fixtures/venta_fixture.dart';

/// El ticket TÉRMICO es el papel que termina en la mano del cliente, así que
/// es la superficie donde más importa la regla: **sin facturación electrónica
/// no van RUC ni razón social**. El negocio emite una nota de venta, no un
/// documento fiscal, y ponerlos arriba la disfraza de comprobante.
///
/// Se testea sobre los BYTES ESC-POS —no sobre el PDF— porque en el PDF de
/// orden de servicio la extracción de texto no funciona con las TTF
/// embebidas, y porque estos bytes son literalmente lo que se imprime.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ruc = '20111111111';
  const razonSocial = 'INVERSIONES ROSA SAC';

  String texto(List<int> bytes) => latin1.decode(bytes, allowInvalid: true);

  group('Ticket térmico de VENTA', () {
    Future<List<int>> generar({String? conRuc, String? conRazon}) {
      return TicketVentaEscPosGenerator.generate(
        venta: VentaFixture.buildNotaVentaTicket(),
        empresaNombre: 'Bodega Dona Rosa',
        empresaRazonSocial: conRazon,
        empresaRuc: conRuc,
        empresaDireccion: 'Av. Empresa 999',
      );
    }

    test('🔴 sin facturación no imprime RUC ni razón social', () async {
      final t = texto(await generar());

      expect(t, isNot(contains(ruc)));
      expect(t, isNot(contains('RUC')));
      expect(t, isNot(contains(razonSocial)));
      // Lo que identifica al negocio se mantiene.
      expect(t, contains('Bodega Dona Rosa'));
      expect(t, contains('Av. Empresa 999'));
    });

    test('con facturación los imprime', () async {
      final t = texto(await generar(conRuc: ruc, conRazon: razonSocial));

      expect(t, contains('RUC: $ruc'));
      expect(t, contains(razonSocial));
    });
  });

  group('Ticket térmico de ORDEN DE SERVICIO', () {
    Future<List<int>> generar({String? conRuc, String? conRazon}) {
      return TicketEscPosGenerator.generarTicket(
        orden: OrdenServicioFixture.buildSimple(),
        empresaNombre: 'Taller Dona Rosa',
        empresaRazonSocial: conRazon,
        empresaRuc: conRuc,
        empresaDireccion: 'Av. Empresa 999',
      );
    }

    test('🔴 sin facturación no imprime RUC ni razón social', () async {
      final t = texto(await generar());

      expect(t, isNot(contains(ruc)));
      expect(t, isNot(contains('RUC')));
      expect(t, isNot(contains(razonSocial)));
      expect(t, contains('Taller Dona Rosa'));
      expect(t, contains('Av. Empresa 999'));
    });

    test('con facturación los imprime', () async {
      final t = texto(await generar(conRuc: ruc, conRazon: razonSocial));

      expect(t, contains('RUC: $ruc'));
      expect(t, contains(razonSocial));
    });
  });
}
