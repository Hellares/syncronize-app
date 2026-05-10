import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/cotizacion/presentation/services/pdf_cotizacion_generator.dart';

import 'fixtures/cotizacion_fixture.dart';
import 'helpers/pdf_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfCotizacionGenerator golden', () {
    test('A4 — sin documentConfig, sin logo', () async {
      final cot = CotizacionFixture.build();

      final bytes = await PdfCotizacionGenerator.generarDocumento(
        cotizacion: cot,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        empresaDireccion: 'Av. Empresa 999, Lima',
        empresaTelefono: '01-7777777',
      );

      // 1) Estructura mínima de PDF
      PdfTestHelpers.expectValidPdf(bytes);

      // 2) Firma estructural — golden congelado.
      // Si refactoreás el generator y este hash cambia: revisa visualmente
      // que el PDF siga correcto y actualiza estos valores.
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 2,
        'textCount': 127,
        'textHash': '3cc80547458e74d2',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'cotizacion-a4');

      // 3) Verificación rápida de contenido — palabras clave esperadas.
      // El extractor recibe el texto dividido por Tj operators, por lo que
      // "Cliente de Prueba SAC" puede venir partido en 4 strings.
      final textos = PdfTestHelpers.extractText(bytes);
      final blob = ' ${textos.join(' ')} ';
      for (final keyword in [
        'COT-2026-00001',
        'Cliente',
        'Prueba',
        'SAC',
        '20111111111',
        'TOTAL',
        '200.00',
      ]) {
        expect(blob, contains(' $keyword '),
            reason: 'No aparece la palabra clave: "$keyword"');
      }
    });

    test('A4 — modo cliente (oculta precios unitarios)', () async {
      final cot = CotizacionFixture.build();

      final bytes = await PdfCotizacionGenerator.generarDocumento(
        cotizacion: cot,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        modoCliente: true,
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final sig = PdfTestHelpers.structuralSignature(bytes);
      const expected = <String, Object>{
        'pages': 1,
        'textCount': 91,
        'textHash': '1aba54486496681b',
      };
      PdfTestHelpers.expectSignatureMatches(sig, expected,
          label: 'cotizacion-a4-cliente');
    });
  });
}
