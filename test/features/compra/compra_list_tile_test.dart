import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/entities/compra.dart';
import 'package:syncronize/features/compra/presentation/widgets/compra_list_tile.dart';

void main() {
  Compra compra({
    String? tipo,
    String? serie,
    String? numero,
    String nombreProveedor = 'DISTRIBUIDORA SAC',
  }) {
    final ahora = DateTime(2026, 8, 24, 10, 30);
    return Compra(
      id: 'c-1',
      empresaId: 'e-1',
      sedeId: 's-1',
      proveedorId: 'p-1',
      codigo: 'COMPRA-00085',
      nombreProveedor: nombreProveedor,
      tipoDocumentoProveedor: tipo,
      serieDocumentoProveedor: serie,
      numeroDocumentoProveedor: numero,
      total: 1479.90,
      fechaRecepcion: ahora,
      estado: EstadoCompra.CONFIRMADA,
      creadoPor: 'u-1',
      creadoEn: ahora,
      actualizadoEn: ahora,
    );
  }

  group('Compra.documentoProveedorTexto', () {
    test('arma tipo + serie-número', () {
      expect(
        compra(tipo: 'FACTURA', serie: 'F001', numero: '5786')
            .documentoProveedorTexto,
        'FACTURA F001-5786',
      );
    });

    test('🔴 cadenas VACÍAS cuentan como sin documento', () {
      // Así vienen en la base las compras sin comprobante: '' y no null.
      // Chequeando solo null salía un chip con un guion suelto.
      expect(
        compra(tipo: '', serie: '', numero: '').documentoProveedorTexto,
        isNull,
      );
    });

    test('sin tipo no hay documento', () {
      expect(compra().documentoProveedorTexto, isNull);
      expect(compra(numero: '5786').documentoProveedorTexto, isNull);
    });

    test('con una sola parte no deja el guion colgando', () {
      expect(
        compra(tipo: 'BOLETA', numero: '5786').documentoProveedorTexto,
        'BOLETA 5786',
      );
      expect(
        compra(tipo: 'BOLETA', serie: 'B001').documentoProveedorTexto,
        'BOLETA B001',
      );
      expect(compra(tipo: 'TICKET').documentoProveedorTexto, 'TICKET');
    });
  });

  group('CompraListTile', () {
    /// Ancho acotado, como el ListView de la pantalla.
    ///
    /// 🔴 500 y no 390: las fuentes de la app NO se cargan en los tests y el
    /// fallback mide más ancho, así que a 390 el tile reporta un desborde de
    /// pocos píxeles que en el celular no existe. Lo que estos tests cuidan
    /// es que el layout no REVIENTE (un Flexible bajo restricciones no
    /// acotadas) y que los chips aparezcan cuando corresponde; medir píxeles
    /// contra una fuente que no es la real no probaría nada.
    Future<void> montar(WidgetTester tester, Compra c) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: ListView(children: [CompraListTile(compra: c)]),
            ),
          ),
        ),
      );
    }

    testWidgets('muestra el comprobante al lado del código', (tester) async {
      await montar(
        tester,
        compra(tipo: 'FACTURA', serie: 'F001', numero: '5786'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('COMPRA-00085'), findsOneWidget);
      expect(find.text('FACTURA F001-5786'), findsOneWidget);
    });

    testWidgets('sin comprobante no dibuja el chip', (tester) async {
      await montar(tester, compra(tipo: '', serie: '', numero: ''));

      expect(tester.takeException(), isNull);
      expect(find.text('COMPRA-00085'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsNothing);
    });

    testWidgets('🔴 un comprobante largo se recorta, no desborda',
        (tester) async {
      // El chip del código vive en un ancho ACOTADO y se recorta; los del
      // monto y el estado viven en una Column no-flex de una Row, que recibe
      // ancho infinito — un Flexible ahí revienta el layout.
      await montar(
        tester,
        compra(
          tipo: 'FACTURA ELECTRONICA',
          serie: 'FFFF0001',
          numero: '000000000012345',
          nombreProveedor: 'DISTRIBUIDORA COMERCIAL DEL NORTE SOCIEDAD ANONIMA',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
