import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/domain/entities/stock_por_sede_info.dart';
import 'package:syncronize/features/producto/domain/entities/precio_nivel.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// Tests de robustez de la lógica de precios (productos, variantes, combos).
/// Verifican las reglas de negocio que tocamos esta sesión:
///  - Precedencia de precio: liquidación > oferta > base.
///  - Niveles por mayor NUNCA suben el precio; liquidación los ignora.
///  - Math de la línea de venta con descuento (combo prorrateado + manual).
void main() {
  final t0 = DateTime(2026, 1, 1);
  final ayer = DateTime.now().subtract(const Duration(days: 1));
  final manana = DateTime.now().add(const Duration(days: 1));

  StockPorSedeInfo stock({
    required double precio,
    bool precioConfigurado = true,
    double? oferta,
    DateTime? ofertaInicio,
    DateTime? ofertaFin,
    double? liq,
    DateTime? liqInicio,
    DateTime? liqFin,
  }) =>
      StockPorSedeInfo(
        sedeId: 's1',
        sedeNombre: 'Sede',
        sedeCodigo: 'S1',
        cantidad: 10,
        precio: precio,
        precioConfigurado: precioConfigurado,
        enOferta: oferta != null,
        precioOferta: oferta,
        fechaInicioOferta: ofertaInicio,
        fechaFinOferta: ofertaFin,
        enLiquidacion: liq != null,
        precioLiquidacion: liq,
        fechaInicioLiquidacion: liqInicio,
        fechaFinLiquidacion: liqFin,
      );

  PrecioNivel nivelFijo(int min, double precio, {int? max, bool activo = true}) =>
      PrecioNivel(
        id: 'n',
        nombre: 'Por Mayor',
        cantidadMinima: min,
        cantidadMaxima: max,
        tipoPrecio: TipoPrecioNivel.precioFijo,
        precio: precio,
        orden: 0,
        isActive: activo,
        creadoEn: t0,
        actualizadoEn: t0,
      );

  PrecioNivel nivelPct(int min, double pct, {int? max}) => PrecioNivel(
        id: 'n',
        nombre: 'Por Mayor',
        cantidadMinima: min,
        cantidadMaxima: max,
        tipoPrecio: TipoPrecioNivel.porcentajeDescuento,
        porcentajeDesc: pct,
        orden: 0,
        isActive: true,
        creadoEn: t0,
        actualizadoEn: t0,
      );

  group('StockPorSedeInfo.precioEfectivo — precedencia liquidación > oferta > base', () {
    test('base cuando no hay oferta ni liquidación', () {
      expect(stock(precio: 10).precioEfectivo, 10);
    });

    test('oferta vigente baja el precio', () {
      expect(stock(precio: 10, oferta: 7).precioEfectivo, 7);
    });

    test('liquidación gana sobre la oferta', () {
      expect(stock(precio: 10, oferta: 7, liq: 3).precioEfectivo, 3);
    });

    test('liquidación expirada (fin ayer) no aplica → base', () {
      expect(stock(precio: 10, liq: 3, liqFin: ayer).precioEfectivo, 10);
    });

    test('liquidación no comenzada (inicio mañana) no aplica → base', () {
      expect(stock(precio: 10, liq: 3, liqInicio: manana).precioEfectivo, 10);
    });

    test('liquidación con ventana vigente (ayer..mañana) aplica', () {
      expect(
        stock(precio: 10, liq: 3, liqInicio: ayer, liqFin: manana).precioEfectivo,
        3,
      );
    });

    test('precioEfectivo es null si precioConfigurado=false', () {
      expect(stock(precio: 10, precioConfigurado: false).precioEfectivo, isNull);
    });

    test('isLiquidacionActiva / isOfertaActiva', () {
      expect(stock(precio: 10, liq: 3).isLiquidacionActiva, isTrue);
      expect(stock(precio: 10, liq: 3, liqFin: ayer).isLiquidacionActiva, isFalse);
      expect(stock(precio: 10, oferta: 7).isOfertaActiva, isTrue);
    });
  });

  group('PrecioNivel', () {
    test('aplicaParaCantidad respeta min y max', () {
      final n = nivelFijo(3, 8, max: 6);
      expect(n.aplicaParaCantidad(2), isFalse);
      expect(n.aplicaParaCantidad(3), isTrue);
      expect(n.aplicaParaCantidad(6), isTrue);
      expect(n.aplicaParaCantidad(7), isFalse);
    });

    test('calcularPrecioFinal fijo y porcentaje', () {
      expect(nivelFijo(3, 8).calcularPrecioFinal(10), 8);
      expect(nivelPct(3, 20).calcularPrecioFinal(10), closeTo(8, 0.0001));
    });

    test('calcularDescuentoPorcentaje', () {
      expect(nivelFijo(3, 8).calcularDescuentoPorcentaje(10), closeTo(20, 0.0001));
      expect(nivelPct(3, 15).calcularDescuentoPorcentaje(10), 15);
    });
  });

  group('VentaDetalleInput — math de la línea', () {
    test('subtotalBruto = cantidad*precio − descuento', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 2, precioUnitario: 10, descuento: 3,
      );
      expect(i.subtotalBruto, 17);
    });

    test('total con IGV agregado (precioIncluyeIgv=false)', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 1, precioUnitario: 100,
        precioIncluyeIgv: false, porcentajeIGV: 18,
      );
      expect(i.total, closeTo(118, 0.0001));
    });

    test('total con IGV incluido (precioIncluyeIgv=true) no agrega', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 1, precioUnitario: 118,
        precioIncluyeIgv: true, porcentajeIGV: 18,
      );
      expect(i.total, closeTo(118, 0.0001));
    });

    test('margenUnitario descuenta el descuento prorrateado por unidad', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 2, precioUnitario: 10, descuento: 4,
        precioCostoSnapshot: 6,
      );
      // (10 − 4/2) − 6 = 2
      expect(i.margenUnitario, closeTo(2, 0.0001));
    });

    test('línea de combo: descuento total (prorrateo+manual) entra en el bruto', () {
      // precioUnitario 10 x2, descuento 3 (= 2 combo + 1 manual)
      final i = VentaDetalleInput(
        descripcion: 'Componente', cantidad: 2, precioUnitario: 10,
        descuento: 3, descuentoManual: 1,
        origenComboId: 'combo1',
      );
      expect(i.subtotalBruto, 17);
    });
  });

  group('VentaDetalleInput.recalcularPrecioPorNiveles', () {
    test('aplica nivel que baja el precio (fijo)', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 1, precioUnitario: 10, precioBase: 10,
        niveles: [nivelFijo(3, 8)],
      ).recalcularPrecioPorNiveles(5);
      expect(i.precioUnitario, 8);
      expect(i.nivelAplicado, 'Por Mayor');
    });

    test('nivel NUNCA sube el precio: si el nivel ≥ base, se ignora', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 1, precioUnitario: 10, precioBase: 10,
        niveles: [nivelFijo(3, 12)], // 12 > 10
      ).recalcularPrecioPorNiveles(5);
      expect(i.precioUnitario, 10);
      expect(i.nivelAplicado, isNull);
    });

    test('liquidación IGNORA niveles → precio base', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 1, precioUnitario: 10, precioBase: 10,
        niveles: [nivelFijo(3, 8)], enLiquidacion: true,
      ).recalcularPrecioPorNiveles(5);
      expect(i.precioUnitario, 10);
      expect(i.nivelAplicado, isNull);
    });

    test('sin nivel aplicable para la cantidad → vuelve a base', () {
      final i = VentaDetalleInput(
        descripcion: 'X', cantidad: 1, precioUnitario: 8, precioBase: 10,
        niveles: [nivelFijo(3, 8)],
      ).recalcularPrecioPorNiveles(1); // cantidad 1 < min 3
      expect(i.precioUnitario, 10);
      expect(i.nivelAplicado, isNull);
    });

    test('elige el nivel más específico (mayor cantidadMinima)', () {
      final sel = VentaDetalleInput.nivelAplicableParaCantidad(
        [nivelFijo(3, 8, max: 11), nivelFijo(12, 6)],
        12,
      );
      expect(sel?.cantidadMinima, 12);
    });
  });
}
