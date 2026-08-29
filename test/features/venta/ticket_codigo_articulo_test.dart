import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/venta/domain/entities/venta.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle.dart';
import 'package:syncronize/features/venta/presentation/services/ticket_venta_esc_pos_generator.dart';

/// El código del artículo en el ticket de venta.
///
/// Sirve para ubicar EXACTAMENTE qué se vendió ante un cambio o una garantía,
/// cuando el nombre solo no alcanza ("POLO NEGRO" hay veinte). Se imprime el
/// SKU si el artículo lo tiene y el código de producto si no.
///
/// 🔴 Este test existe porque los goldens del PDF NO lo cubren: sus fixtures no
/// traen código, así que la línea nueva no se ejecuta ahí y la suite pasaba en
/// verde sin probar nada de esto.
void main() {
  // El generador ESC-POS carga el CapabilityProfile desde un asset del
  // paquete, y sin binding el bundle no existe.
  TestWidgetsFlutterBinding.ensureInitialized();

  VentaDetalle detalle({
    String? productoCodigo,
    String? productoSku,
    String? varianteSku,
  }) {
    return VentaDetalle(
      id: 'vd_1',
      ventaId: 'vta_1',
      productoId: 'prod_1',
      descripcion: 'POLO NEGRO',
      cantidad: 1,
      precioUnitario: 50,
      subtotal: 42.37,
      igv: 7.63,
      total: 50,
      productoCodigo: productoCodigo,
      productoSku: productoSku,
      varianteSku: varianteSku,
    );
  }

  group('de dónde sale el código', () {
    test('el SKU del producto gana sobre el código', () {
      final c = detalle(productoCodigo: 'P-0001', productoSku: 'SKU-ABC')
          .codigoIdentificador;
      expect(c?.etiqueta, 'SKU');
      expect(c?.valor, 'SKU-ABC');
    });

    test('sin SKU cae al código del producto', () {
      final c = detalle(productoCodigo: 'P-0001').codigoIdentificador;
      expect(c?.etiqueta, 'Cod');
      expect(c?.valor, 'P-0001');
    });

    test('🔴 el SKU de la VARIANTE gana sobre todo', () {
      // Es lo que de verdad salió del stock: el SKU del padre no dice qué
      // talla se vendió, y eso es justo lo que se necesita en un cambio.
      final c = detalle(
        productoCodigo: 'P-0001',
        productoSku: 'SKU-PADRE',
        varianteSku: 'SKU-TALLA-M',
      ).codigoIdentificador;
      expect(c?.etiqueta, 'SKU');
      expect(c?.valor, 'SKU-TALLA-M');
    });

    test('un código en blanco no cuenta como código', () {
      final c = detalle(productoCodigo: 'P-0001', productoSku: '   ')
          .codigoIdentificador;
      expect(c?.valor, 'P-0001');
    });

    test('sin ninguno, no hay qué imprimir', () {
      expect(detalle().codigoIdentificador, isNull);
    });
  });

  group('lo que sale impreso en el ticket térmico', () {
    Future<String> ticketDe(VentaDetalle d) async {
      final venta = Venta(
        id: 'vta_1',
        empresaId: 'emp_1',
        sedeId: 'sede_1',
        vendedorId: 'vend_1',
        codigo: 'VTA-00000001',
        nombreCliente: 'Cliente de Prueba',
        tipoComprobante: 'TICKET',
        subtotal: d.subtotal,
        impuestos: d.igv,
        total: d.total,
        estado: EstadoVenta.pagadaCompleta,
        fechaVenta: DateTime.utc(2026, 8, 29),
        creadoEn: DateTime.utc(2026, 8, 29),
        actualizadoEn: DateTime.utc(2026, 8, 29),
        detalles: [d],
      );
      final bytes = await TicketVentaEscPosGenerator.generate(
        venta: venta,
        empresaNombre: 'Empresa Test SAC',
      );
      return String.fromCharCodes(bytes);
    }

    test('imprime el SKU cuando el producto lo tiene', () async {
      final texto = await ticketDe(
        detalle(productoCodigo: 'P-0001', productoSku: 'SKU-ABC'),
      );
      expect(texto, contains('SKU: SKU-ABC'));
      // El código no se imprime cuando hay SKU: sería ruido en papel.
      expect(texto, isNot(contains('P-0001')));
    });

    test('cae al código del producto cuando no hay SKU', () async {
      final texto = await ticketDe(detalle(productoCodigo: 'P-0001'));
      expect(texto, contains('Cod: P-0001'));
    });

    test('sin código no gasta un renglón de papel', () async {
      final texto = await ticketDe(detalle());
      expect(texto, isNot(contains('SKU:')));
      expect(texto, isNot(contains('Cod:')));
    });
  });
}
