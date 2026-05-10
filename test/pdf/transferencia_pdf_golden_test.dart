import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/presentation/services/pdf_transferencia_generator.dart';

import 'fixtures/transferencia_fixture.dart';
import 'helpers/pdf_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfTransferenciaGenerator golden', () {
    test('A4 — transferencia básica entre sedes', () async {
      final transferencia = TransferenciaFixture.build();

      final bytes = await PdfTransferenciaGenerator.generarDocumento(
        transferencia: transferencia,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 2,
        'textCount': 92,
        'textHash': '5c7669ee5ec2fc2b',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'transferencia-a4');

      final blob = ' ${PdfTestHelpers.extractText(bytes).join(' ')} ';
      for (final keyword in [
        'TR-2026-00001',
        'Sede',
        'Central',
        'Sucursal',
        'Norte',
        'Producto',
      ]) {
        expect(blob, contains(' $keyword '),
            reason: 'No aparece la palabra clave: "$keyword"');
      }
    });
  });
}
