import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/venta/data/models/venta_detalle_model.dart';
import 'package:syncronize/features/venta/domain/entities/venta.dart';
import 'package:syncronize/features/venta/presentation/services/ticket_venta_esc_pos_generator.dart';

/// La línea de venta de un granel se GUARDA en gramos (1500 @ S/0.008) pero el
/// cliente compró 1.5 kg a S/8.00. El ticket que se lleva y el comprobante que
/// ve SUNAT tienen que decir lo segundo — "1500" y "0.01" son dos números que
/// no aparecen en ninguna otra parte y que hacen dudar de la plata.
void main() {
  // El generador ESC-POS carga el CapabilityProfile desde los assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> lineaRicocan({
    Object? factorPresentacion = 1000,
    String? simbolo = 'kg',
  }) =>
      {
        'id': 'vd1',
        'ventaId': 'v1',
        'productoId': 'p1',
        'descripcion': 'RICOCAN 22KG',
        'cantidad': 1500,
        'precioUnitario': 0.008,
        'subtotal': 10.17,
        'igv': 1.83,
        'total': 12,
        if (factorPresentacion != null)
          'factorPresentacion': factorPresentacion,
        if (simbolo != null) 'unidadPresentacionSimbolo': simbolo,
        'codigoUnidadSunat': 'KGM',
      };

  group('VentaDetalle · snapshot de presentación', () {
    test('lee el snapshot que manda el backend', () {
      final d = VentaDetalleModel.fromJson(lineaRicocan());

      expect(d.factorPresentacion, 1000);
      expect(d.unidadPresentacionSimbolo, 'kg');
      expect(d.codigoUnidadSunat, 'KGM');
    });

    test('traduce a la unidad en la que se cobró', () {
      final u = VentaDetalleModel.fromJson(lineaRicocan()).presentacion;

      expect(u.activa, isTrue);
      expect(u.cantidadTexto(1500), '1.5 kg');
      expect(u.precio(0.008), closeTo(8, 0.000001));
    });

    test('sobrevive al ida y vuelta por JSON', () {
      // toJson alimenta la caché en disco: si no devuelve lo que fromJson lee,
      // la línea vuelve sin presentación y el ticket reimpreso dice "1500".
      final original = VentaDetalleModel.fromJson(lineaRicocan());
      final ida = VentaDetalleModel.fromJson(original.toJson());

      expect(ida.factorPresentacion, 1000);
      expect(ida.unidadPresentacionSimbolo, 'kg');
      expect(ida.codigoUnidadSunat, 'KGM');
    });

    test('una venta anterior a esta capa no tiene presentación y no cambia', () {
      final d = VentaDetalleModel.fromJson(
        lineaRicocan(factorPresentacion: null, simbolo: null),
      );

      expect(d.presentacion.activa, isFalse);
      expect(d.presentacion.cantidad(1500), 1500);
      expect(d.presentacion.precio(0.008), 0.008);
    });

    test('el factor tolera que el backend lo mande como String', () {
      // Prisma serializa Decimal como String.
      final d = VentaDetalleModel.fromJson(
        lineaRicocan(factorPresentacion: '1000'),
      );

      expect(d.factorPresentacion, 1000);
      expect(d.presentacion.activa, isTrue);
    });
  });

  group('Ticket térmico', () {
    /// El generador devuelve bytes ESC-POS; el texto viaja en ASCII plano, así
    /// que basta decodificarlo para leer lo que sale impreso.
    Future<String> imprimir(Map<String, dynamic> linea) async {
      final d = VentaDetalleModel.fromJson(linea);
      final bytes = await TicketVentaEscPosGenerator.generate(
        venta: Venta(
          id: 'v1',
          empresaId: 'emp1',
          sedeId: 'sede1',
          vendedorId: 'vendedor1',
          codigo: 'V-2026-00001',
          nombreCliente: 'Cliente de Prueba',
          moneda: 'PEN',
          subtotal: d.subtotal,
          descuento: 0,
          impuestos: d.igv,
          total: d.total,
          estado: EstadoVenta.pagadaCompleta,
          tipoComprobante: 'TICKET',
          fechaVenta: DateTime.utc(2026, 8, 6),
          creadoEn: DateTime.utc(2026, 8, 6),
          actualizadoEn: DateTime.utc(2026, 8, 6),
          detalles: [d],
        ),
        empresaNombre: 'Empresa Test SAC',
      );
      return String.fromCharCodes(bytes.where((b) => b >= 32 && b < 127));
    }

    test('imprime kilos, no gramos', () async {
      final texto = await imprimir(lineaRicocan());

      expect(texto, contains('1.5 kg x S/8.00/kg'));
      // El precio por gramo redondeado a centavos era el número fantasma.
      expect(texto, isNot(contains('0.01')));
      expect(texto, isNot(contains('1500')));
    });

    test('sin presentación imprime exactamente como antes', () async {
      final texto = await imprimir({
        ...lineaRicocan(factorPresentacion: null, simbolo: null),
        'descripcion': 'GASEOSA',
        'cantidad': 2,
        'precioUnitario': 6,
        'total': 12,
      });

      expect(texto, contains('GASEOSA'));
      expect(texto, isNot(contains(' x S/')));
    });
  });
}
