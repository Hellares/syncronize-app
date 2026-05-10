import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/venta/presentation/services/pdf_venta_generator.dart';

import 'fixtures/venta_fixture.dart';
import 'helpers/pdf_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfVentaGenerator golden', () {
    test('Boleta — ticket térmico', () async {
      final venta = VentaFixture.buildBoletaTicket();

      final bytes = await PdfVentaGenerator.generarTicket(
        venta: venta,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        razonSocial: 'Empresa Test SAC',
        direccionFiscal: 'Av. Empresa 999',
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 1,
        'textCount': 79,
        'textHash': '6ae39ab0601aa91b',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'venta-boleta-ticket');

      final blob = ' ${PdfTestHelpers.extractText(bytes).join(' ')} ';
      for (final keyword in [
        'B001-00000001',
        'BOLETA',
        '100.00',
        'Producto',
      ]) {
        expect(blob, contains(' $keyword '),
            reason: 'No aparece la palabra clave: "$keyword"');
      }
    });

    test('Factura SUNAT — A4 con QR', () async {
      final venta = VentaFixture.buildFacturaA4();

      final bytes = await PdfVentaGenerator.generarTicket(
        venta: venta,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        razonSocial: 'Empresa Test SAC',
        direccionFiscal: 'Av. Empresa 999',
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 1,
        'textCount': 80,
        'textHash': '92c16dce3c4595c2',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'venta-factura');

      final blob = ' ${PdfTestHelpers.extractText(bytes).join(' ')} ';
      for (final keyword in [
        'F001-00000001',
        'FACTURA',
        '20987654321',
        '200.00',
      ]) {
        expect(blob, contains(' $keyword '),
            reason: 'No aparece la palabra clave: "$keyword"');
      }
    });
  });
}
