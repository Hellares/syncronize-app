/// El catálogo compartible: lo que va en el membrete y lo que dice cada
/// tarjeta.
///
/// 🔴 El candado principal es el NOMBRE COMERCIAL. `Empresa.nombre` guarda la
/// razón social —el alta por RUC la copia ahí—, así que un catálogo armado con
/// ese campo sale encabezado "JAYLI FLORES S.A.C." en vez de "JAYLILAND". La
/// pantalla lo resuelve con `resolverIdentidadComercial` y le pasa el nombre ya
/// elegido; acá se verifica que la hoja dibuje EL QUE LE PASAN.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:syncronize/features/herramientas/presentation/services/catalogo_pdf.dart';

import 'helpers/pdf_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<ItemCatalogo> items() => [
        ItemCatalogo(
          id: '1',
          titulo: 'EDREDON 2 PLAZAS CARNERITO',
          codigo: 'EDR-2P-001',
          precio: 129.9,
          stock: 12,
          caracteristicas: const [
            ('MATERIAL', 'Microfibra'),
            ('TAMANO', '2 plazas'),
          ],
        ),
        // Sin stock pero elegido a mano: es lo que se ofrece por encargo.
        ItemCatalogo(
          id: '2',
          titulo: 'COBERTOR PLUSH KING',
          codigo: 'COB-KG-09',
          precio: 199,
          stock: 0,
          elegido: true,
        ),
        // Destildado: no tiene que aparecer en el PDF.
        ItemCatalogo(
          id: '3',
          titulo: 'ALMOHADA DESCARTADA',
          precio: 45,
          stock: 0,
        ),
      ];

  String blobDe(List<int> bytes) =>
      ' ${PdfTestHelpers.extractText(Uint8List.fromList(bytes)).join(' ')} ';

  test('el membrete lleva el nombre comercial, no la razon social', () async {
    final bytes = await construirCatalogoPdf(
      items: items(),
      // Lo que llega ya resuelto: la marca, no "JAYLI FLORES S.A.C.".
      empresaNombre: 'JAYLILAND',
      empresaRuc: '20601234567',
      empresaTelefono: '987654321',
      sedeNombre: 'TIENDA CENTRO',
      sedeDireccion: 'Jr. Pizarro 456',
      textoPie: 'Gracias por su preferencia',
      imagenes: const {},
    );

    PdfTestHelpers.expectValidPdf(bytes);
    final blob = blobDe(bytes);
    expect(blob, contains('JAYLILAND'));
    expect(blob, isNot(contains('JAYLI FLORES')));
    expect(blob, contains('20601234567'));
    expect(blob, contains('TIENDA CENTRO'));
  });

  test('solo entran los elegidos, y el sin stock sale como "A pedido"',
      () async {
    final bytes = await construirCatalogoPdf(
      items: items(),
      empresaNombre: 'JAYLILAND',
      imagenes: const {},
    );

    final blob = blobDe(bytes);
    expect(blob, contains('EDREDON'));
    expect(blob, contains('COBERTOR'));
    expect(blob, isNot(contains('DESCARTADA')));
    expect(blob, contains('pedido'));
    // El rotulo cuenta los elegidos, no la lista entera.
    expect(blob, contains('2'));
  });

  test('los interruptores apagan precio, codigo y caracteristicas', () async {
    final bytes = await construirCatalogoPdf(
      items: items(),
      empresaNombre: 'JAYLILAND',
      imagenes: const {},
      incluirPrecio: false,
      incluirCodigo: false,
      incluirCaracteristicas: false,
    );

    final blob = blobDe(bytes);
    expect(blob, contains('EDREDON'));
    expect(blob, isNot(contains('129.90')));
    expect(blob, isNot(contains('EDR-2P-001')));
    expect(blob, isNot(contains('Microfibra')));
  });

  test('un color de marca distinto no rompe el documento', () async {
    final bytes = await construirCatalogoPdf(
      items: items(),
      empresaNombre: 'COMPANY COMPUTER',
      colorPrimario: const PdfColor.fromInt(0xFFDB0D0D),
      imagenes: const {},
    );

    PdfTestHelpers.expectValidPdf(bytes);
    expect(blobDe(bytes), contains('COMPANY'));
  });
}
