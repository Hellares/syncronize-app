import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/servicio/presentation/services/pdf_orden_servicio_generator.dart';

import 'fixtures/orden_servicio_fixture.dart';
import 'helpers/pdf_test_helpers.dart';

/// `PdfOrdenServicioGenerator` carga fuentes TTF (Oxygen) embebidas, lo que
/// hace que `package:pdf` codifique el texto como índices de glifos binarios
/// en vez de operadores `Tj` con strings latin1. Por eso el extractor de
/// texto retorna 0 elementos.
///
/// La estrategia de golden para este generator es más débil que la de
/// cotización/venta/compra:
/// - PDF estructuralmente válido (header + EOF + tamaño razonable).
/// - Cantidad de páginas estable.
/// - Bucket de tamaño estable (±512 bytes).
///
/// Cuando se migre a la nueva infra `core/services/pdf/`, se decidirá si
/// se quitan las fuentes TTF (volviendo a hashes de texto) o se mantienen
/// y este test sigue cubriendo solo estructura.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfOrdenServicioGenerator golden', () {
    test('Ticket 80mm — orden básica', () async {
      final orden = OrdenServicioFixture.buildSimple();

      final bytes = await PdfOrdenServicioGenerator.generarTicket(
        orden: orden,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        empresaDireccion: 'Av. Empresa 999, Lima',
        empresaTelefono: '01-7777777',
        sedeNombre: 'Sede Principal',
      );

      // 1) Estructura mínima de PDF
      PdfTestHelpers.expectValidPdf(bytes);

      // 2) Firma estructural — golden congelado.
      // Solo `pages` y `sizeBucket` son verificables (text extraction no
      // funciona con TTF embebidas, ver doc del archivo).
      final sig = PdfTestHelpers.structuralSignature(bytes);
      expect(sig['pages'], 1, reason: 'Cantidad de páginas cambió');
      // Tolerancia ±1 bucket (~512 bytes) para variaciones de embedding.
      final actualBucket = sig['sizeBucket'] as int;
      const expectedBucket = 45;
      expect(
        (actualBucket - expectedBucket).abs() <= 1,
        isTrue,
        reason:
            'sizeBucket cambió drásticamente (actual=$actualBucket, expected≈$expectedBucket)',
      );
    });
  });
}
