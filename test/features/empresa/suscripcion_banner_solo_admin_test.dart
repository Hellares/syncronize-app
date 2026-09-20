import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Renovar el plan es del admin.
///
/// Al técnico le aparecía "Tu plan venció hace 6 días" con un botón de pago
/// que no le corresponde: no puede renovar nada y no es su problema.
///
/// 🔴 Se lee el código fuente del dashboard porque montarlo pide contexto de
/// empresa, varios cubits y red.
void main() {
  test('🔴 el banner de suscripción vencida va detrás de esAdmin', () {
    final fuente = File(
      'lib/features/empresa/presentation/pages/empresa_dashboard_page.dart',
    ).readAsStringSync();

    expect(
      RegExp(r'if \(esAdmin\)\s*\n?\s*SuscripcionBanner\(').hasMatch(fuente),
      isTrue,
      reason: 'El banner tiene que quedar detrás del permiso de admin',
    );
  });
}
