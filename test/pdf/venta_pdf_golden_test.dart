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

    test('🔴 nota de venta sin facturación: sin RUC ni razón social',
        () async {
      // El negocio que no emite documentos fiscales no puede poner el RUC
      // arriba del ticket: lo disfraza de comprobante. El nombre comercial y
      // la dirección sí van — identifican al negocio.
      final bytes = await PdfVentaGenerator.generarTicket(
        venta: VentaFixture.buildNotaVentaTicket(),
        empresaNombre: 'Bodega Doña Rosa',
        empresaRuc: '20111111111',
        razonSocial: 'INVERSIONES ROSA SAC',
        direccionFiscal: 'Av. Empresa 999',
        mostrarDatosFiscales: false,
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final blob = PdfTestHelpers.extractText(bytes).join(' ');

      expect(blob, isNot(contains('20111111111')),
          reason: 'No debe imprimir el RUC');
      expect(blob, isNot(contains('RUC')), reason: 'Ni la etiqueta RUC');
      expect(blob, isNot(contains('INVERSIONES ROSA SAC')),
          reason: 'No debe imprimir la razón social');
      // Lo que SÍ identifica al negocio se mantiene.
      expect(blob, contains('Bodega Do'), reason: 'Falta el nombre comercial');
      expect(blob, contains('Av. Empresa 999'), reason: 'Falta la dirección');
    });

    test('con facturación activa el ticket mantiene los datos fiscales',
        () async {
      final bytes = await PdfVentaGenerator.generarTicket(
        venta: VentaFixture.buildNotaVentaTicket(),
        empresaNombre: 'Bodega Doña Rosa',
        empresaRuc: '20111111111',
        razonSocial: 'INVERSIONES ROSA SAC',
        direccionFiscal: 'Av. Empresa 999',
      );

      final blob = PdfTestHelpers.extractText(bytes).join(' ');
      expect(blob, contains('20111111111'));
      expect(blob, contains('INVERSIONES ROSA SAC'));
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

    test('ítem pesado — la unidad va pegada al P.U.', () async {
      // Un granel se guarda en gramos y se cobra en kilos. Sin la unidad al
      // lado del precio, un "7.50" junto a un total de 18.75 se lee como el
      // precio de los 2.5 kg y no como la tarifa por kilo.
      final venta = VentaFixture.buildBoletaGranel();

      final bytes = await PdfVentaGenerator.generarTicket(
        venta: venta,
        empresaNombre: 'Empresa Test SAC',
        empresaRuc: '20111111111',
        razonSocial: 'Empresa Test SAC',
        direccionFiscal: 'Av. Empresa 999',
      );

      PdfTestHelpers.expectValidPdf(bytes);
      final blob = PdfTestHelpers.extractText(bytes).join(' ');

      expect(blob, contains('7.50(kg)'));
      expect(blob, contains('2.5'), reason: 'la cantidad va en kilos');
      // La sub-línea aparte quedó obsoleta al mover la unidad al precio.
      expect(blob, isNot(contains('Precio por')));
      expect(blob, isNot(contains('1500')), reason: 'no debe mostrar gramos');
    });
  });
}
