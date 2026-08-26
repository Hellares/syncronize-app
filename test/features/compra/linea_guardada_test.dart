import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/entities/compra.dart';
import 'package:syncronize/features/compra/domain/linea_guardada.dart';

/// Reapertura de un BORRADOR: la línea guardada tiene que volver al formulario
/// EXACTAMENTE como el usuario la escribió.
///
/// Lo que se prueba es la vuelta atrás de la conversión que hace el backend al
/// guardar (que deja todo en unidad atómica). Equivocarla no rompe nada
/// visible: los números simplemente cambian solos al volver a guardar.

CompraDetalle detalle({
  int cantidad = 1,
  double precioUnitario = 0,
  double descuento = 0,
  double porcentajeIGV = 18,
  double subtotal = 0,
  double total = 0,
  bool usaUnidadCompra = false,
  double? cantidadOriginal,
  double? factorAplicado,
  String? unidadOriginalSimbolo,
  String? ordenCompraDetalleId,
  double? nuevoPrecioVenta,
  Map<String, dynamic>? producto,
  Map<String, dynamic>? variante,
}) =>
    CompraDetalle(
      id: 'det-1',
      compraId: 'c-1',
      productoId: 'prod-1',
      descripcion: 'ARROZ',
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      descuento: descuento,
      porcentajeIGV: porcentajeIGV,
      subtotal: subtotal,
      total: total,
      usaUnidadCompra: usaUnidadCompra,
      cantidadOriginal: cantidadOriginal,
      factorAplicado: factorAplicado,
      unidadOriginalSimbolo: unidadOriginalSimbolo,
      ordenCompraDetalleId: ordenCompraDetalleId,
      nuevoPrecioVenta: nuevoPrecioVenta,
      producto: producto,
      variante: variante,
    );

Map<String, dynamic> unidad(String simbolo) => {
      'id': 'u-1',
      'simboloPersonalizado': null,
      'simboloLocal': simbolo,
      'unidadMaestra': {'simbolo': 'XXX'},
    };

void main() {
  group('línea en unidad base', () {
    test('cantidad y precio vuelven tal cual', () {
      final item = itemDesdeDetalleGuardado(
        detalle(cantidad: 10, precioUnitario: 5, subtotal: 42.37, total: 50),
        precioIncluyeIgv: true,
      );

      expect(item['cantidad'], 10);
      expect(item['precioUnitario'], 5);
      expect(item.containsKey('usaUnidadCompra'), isFalse);
    });

    test('el IGV de la línea viaja de vuelta, no se asume 18', () {
      final item = itemDesdeDetalleGuardado(
        detalle(cantidad: 3, precioUnitario: 10, porcentajeIGV: 0, total: 30),
        precioIncluyeIgv: true,
      );

      expect(item['porcentajeIGV'], 0);
    });

    test('el vínculo con la OC y el precio de venta nuevo se conservan', () {
      final item = itemDesdeDetalleGuardado(
        detalle(
          cantidad: 2,
          precioUnitario: 10,
          total: 20,
          ordenCompraDetalleId: 'ocd-9',
          nuevoPrecioVenta: 14.5,
        ),
        precioIncluyeIgv: true,
      );

      expect(item['ordenCompraDetalleId'], 'ocd-9');
      expect(item['nuevoPrecioVenta'], 14.5);
    });
  });

  group('línea cargada por unidad de compra', () {
    // 1 SACO de S/147.99 con factor 22 000: el backend guarda 22 000 g a
    // S/0.006727 (6 decimales) y un total de S/147.99.
    final saco = detalle(
      cantidad: 22000,
      precioUnitario: 0.006727,
      subtotal: 125.42,
      total: 147.99,
      usaUnidadCompra: true,
      cantidadOriginal: 1,
      factorAplicado: 22000,
      unidadOriginalSimbolo: 'SACO',
    );

    test('vuelve como 1 SACO a S/147.99, no como 22 000 a S/0.006727', () {
      final item = itemDesdeDetalleGuardado(saco, precioIncluyeIgv: true);

      expect(item['cantidad'], 1);
      // 🔴 Acá se ve por qué el precio se reconstruye desde la plata de la
      // línea: 0.006727 × 22 000 da 147.994.
      expect(item['precioUnitario'], 147.99);
      expect(item['usaUnidadCompra'], isTrue);
      expect(item['factorCompra'], 22000);
      expect(item['unidadCompraSimbolo'], 'SACO');
    });

    test('con el IGV por encima el bruto es el SUBTOTAL, no el total', () {
      // 2 cajas de 50 a S/100 + IGV: subtotal 200, total 236.
      final item = itemDesdeDetalleGuardado(
        detalle(
          cantidad: 100,
          precioUnitario: 2,
          subtotal: 200,
          total: 236,
          usaUnidadCompra: true,
          cantidadOriginal: 2,
          factorAplicado: 50,
        ),
        precioIncluyeIgv: false,
      );

      expect(item['precioUnitario'], 100);
    });

    test('el descuento de la línea vuelve al precio del saco', () {
      // 3 sacos a S/50 con S/10 de descuento: bruto 150, total 140.
      final item = itemDesdeDetalleGuardado(
        detalle(
          cantidad: 150,
          precioUnitario: 1,
          descuento: 10,
          total: 140,
          usaUnidadCompra: true,
          cantidadOriginal: 3,
          factorAplicado: 50,
        ),
        precioIncluyeIgv: true,
      );

      expect(item['cantidad'], 3);
      expect(item['precioUnitario'], 50);
      expect(item['descuento'], 10);
    });
  });

  group('unidades para poder reabrir la línea en el editor', () {
    test('presentación y unidad de venta salen del producto', () {
      final item = itemDesdeDetalleGuardado(
        detalle(
          cantidad: 15000,
          precioUnitario: 0.008,
          total: 120,
          producto: {
            'factorCompra': 50,
            'unidadCompra': unidad('SACO'),
            'factorPresentacion': 1000,
            'unidadPresentacion': unidad('kg'),
            'unidadMedida': unidad('g'),
          },
        ),
        precioIncluyeIgv: true,
      );

      expect(item['factorPresentacion'], 1000);
      expect(item['unidadPresentacionSimbolo'], 'kg');
      expect(item['unidadVentaSimbolo'], 'g');
      // El empaque viaja aunque la línea NO se haya cargado por saco: sin él,
      // al reabrirla el editor ya no ofrecería comprar por saco.
      expect(item['factorCompra'], 50);
      expect(item['unidadCompraSimbolo'], 'SACO');
    });

    test('la presentación de la VARIANTE le gana a la del producto', () {
      final item = itemDesdeDetalleGuardado(
        detalle(
          cantidad: 5,
          precioUnitario: 20,
          total: 100,
          producto: {
            'factorPresentacion': 1000,
            'unidadPresentacion': unidad('kg'),
            'unidadMedida': unidad('g'),
          },
          variante: {
            'factorPresentacion': 1,
            'unidadPresentacion': unidad('u'),
            'unidadMedida': unidad('u'),
          },
        ),
        precioIncluyeIgv: true,
      );

      expect(item['factorPresentacion'], 1);
      expect(item['unidadPresentacionSimbolo'], 'u');
      expect(item['unidadVentaSimbolo'], 'u');
    });

    test('el símbolo personalizado le gana al local y al de la maestra', () {
      expect(
        simboloDeUnidad({
          'simboloPersonalizado': 'cja12',
          'simboloLocal': 'CJA',
          'unidadMaestra': {'simbolo': 'BX'},
        }),
        'cja12',
      );
      expect(
        simboloDeUnidad({
          'unidadMaestra': {'simbolo': 'BX'},
        }),
        'BX',
      );
      expect(simboloDeUnidad(null), isNull);
    });
  });
}
