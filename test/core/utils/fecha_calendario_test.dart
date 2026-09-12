import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/fecha_calendario.dart';

/// Un vencimiento es un DÍA, no un instante.
///
/// 🔴 El bug que esto fija: el backend guarda la medianoche UTC del día del
/// envase, y en Lima (UTC−5) ese instante es la tarde del día ANTERIOR.
/// Leerlo con `.toLocal()` o compararlo contra `DateTime.now()` corría todo
/// un día.
void main() {
  group('fecha de calendario (vencimientos)', () {
    // Como lo manda el backend: medianoche UTC del 01/10/2026.
    final vence = DateTime.parse('2026-10-01T00:00:00.000Z');

    test('el día se lee de los campos UTC, no de la hora local', () {
      expect(diaCalendario(vence), '2026-10-01');
      expect(formatearDiaEnvase(vence), '01/10/26');
      expect(formatearDiaEnvase(vence, anioCompleto: true), '01/10/2026');
      // Aunque el DateTime venga en local (parseado sin zona y convertido).
      expect(diaCalendario(vence.toLocal()), '2026-10-01');
    });

    test('desde el ISO crudo, sin parsear a instante', () {
      expect(formatearDiaEnvaseIso('2026-10-01T00:00:00.000Z'), '01/10/26');
      expect(formatearDiaEnvaseIso('2026-10-01'), '01/10/26');
      expect(formatearDiaEnvaseIso(null), '');
      expect(formatearDiaEnvaseIso('x'), '');
    });

    test('lo que se manda al elegir un día es yyyy-MM-dd, sin hora', () {
      expect(diaParaEnviar(DateTime(2026, 10, 1, 15, 30)), '2026-10-01');
      expect(diaParaEnviar(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('el propio día del envase todavía no está vencido', () {
      final hoy = DateTime.now();
      final hoyUtc = DateTime.utc(hoy.year, hoy.month, hoy.day);
      expect(diasParaVencer(hoyUtc), 0);
      expect(estaVencido(hoyUtc), isFalse);

      final ayer = hoyUtc.subtract(const Duration(days: 1));
      expect(diasParaVencer(ayer), -1);
      expect(estaVencido(ayer), isTrue);

      final en30 = hoyUtc.add(const Duration(days: 30));
      expect(diasParaVencer(en30), 30);
      expect(estaVencido(en30), isFalse);
    });

    test('sin fecha no vence', () {
      expect(diasParaVencer(null), isNull);
      expect(estaVencido(null), isFalse);
      expect(diasParaVencerIso(null), isNull);
    });

    test('el ISO crudo da los mismos días que el DateTime', () {
      final hoy = DateTime.now();
      final hoyUtc = DateTime.utc(hoy.year, hoy.month, hoy.day);
      final en7 = hoyUtc.add(const Duration(days: 7));
      expect(diasParaVencerIso(en7.toIso8601String()), diasParaVencer(en7));
      expect(diasParaVencerIso(en7.toIso8601String()), 7);
    });
  });
}
