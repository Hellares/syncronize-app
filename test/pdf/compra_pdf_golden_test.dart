import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/presentation/services/pdf_compra_generator.dart';

import 'fixtures/compra_fixture.dart';
import 'helpers/pdf_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfCompraGenerator golden', () {
    test('Compra A4 — sin documentConfig', () async {
      final compra = CompraFixture.build();

      final bytes = await PdfCompraGenerator.generarDocumentoCompra(
        compra: compra,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        empresaDireccion: 'Av. Empresa 999, Lima',
        empresaTelefono: '01-7777777',
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 1,
        'textCount': 87,
        'textHash': '0b26eb8af11819ee',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'compra-a4');

      final blob = ' ${PdfTestHelpers.extractText(bytes).join(' ')} ';
      for (final keyword in [
        'C-2026-00001',
        'Proveedor',
        '20999888777',
        '500.00',
      ]) {
        expect(blob, contains(' $keyword '),
            reason: 'No aparece la palabra clave: "$keyword"');
      }
    });
  });
}
