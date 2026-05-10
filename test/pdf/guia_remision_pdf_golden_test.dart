import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/guia_remision/presentation/services/pdf_guia_remision_generator.dart';

import 'fixtures/guia_remision_fixture.dart';
import 'helpers/pdf_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfGuiaRemisionGenerator golden', () {
    test('Ticket 80mm — guía remitente con 2 detalles', () async {
      final guia = GuiaRemisionFixture.build();

      final bytes = await PdfGuiaRemisionGenerator.generar(
        guia: guia,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        razonSocial: 'Empresa Test SAC',
        direccionFiscal: 'Av. Empresa 999',
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 1,
        'textCount': 91,
        'textHash': 'e7a66034ff09d554',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'guia-remision-ticket');

      final blob = ' ${PdfTestHelpers.extractText(bytes).join(' ')} ';
      for (final keyword in [
        'T001-00000001',
        'Cliente',
        'ABC-123',
      ]) {
        expect(blob, contains(' $keyword '),
            reason: 'No aparece la palabra clave: "$keyword"');
      }
    });
  });
}
