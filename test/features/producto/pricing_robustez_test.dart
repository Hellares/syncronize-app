import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/domain/entities/stock_por_sede_info.dart';
import 'package:syncronize/features/producto/domain/entities/precio_nivel.dart';
import 'package:syncronize/features/producto/data/models/precio_nivel_model.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';
import 'package:syncronize/features/descuento/domain/entities/vip_precio.dart';
import 'package:syncronize/features/descuento/domain/entities/politica_descuento.dart'
    show EstrategiaMayor;

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

  // ── Precio especial VIP del cliente (feature "Cliente VIP") ──
  // Estos cálculos deben ser ESPEJO EXACTO del backend (PrecioNivelService);
  // si divergen, el guard 409 PRECIO_DESACTUALIZADO rebota la venta.

  VipPrecioIntent vipCosto({double markup = 0}) => VipPrecioIntent(
        politicaId: 'p-costo',
        etiqueta: 'VIP: Costo',
        modo: ModoPrecioVip.precioCosto,
        markupSobreCosto: markup,
      );
  VipPrecioIntent vipMayor(
          {EstrategiaMayor estrategia = EstrategiaMayor.primerNivel}) =>
      VipPrecioIntent(
        politicaId: 'p-mayor',
        etiqueta: 'VIP: Mayor',
        modo: ModoPrecioVip.precioMayorDesdeUnidad,
        estrategiaMayor: estrategia,
      );
  VipPrecioIntent vipPct(double v, {double? max}) => VipPrecioIntent(
        politicaId: 'p-pct',
        etiqueta: 'VIP: %',
        modo: ModoPrecioVip.porcentaje,
        valor: v,
        descuentoMaximo: max,
      );
  VipPrecioIntent vipMonto(double v) => VipPrecioIntent(
        politicaId: 'p-monto',
        etiqueta: 'VIP: Monto',
        modo: ModoPrecioVip.montoFijo,
        valor: v,
      );
  // PrecioNivelMODEL (no PrecioNivel): reproduce la covarianza que crasheaba
  // el reduce de MEJOR_NIVEL (niveles runtime List<PrecioNivelModel>).
  PrecioNivelModel nivelModel(int min, double precio) => PrecioNivelModel(
        id: 'nm',
        nombre: 'Por Mayor',
        cantidadMinima: min,
        tipoPrecio: TipoPrecioNivel.precioFijo,
        precio: precio,
        orden: 0,
        isActive: true,
        creadoEn: t0,
        actualizadoEn: t0,
      );

  VentaDetalleInput linea({
    double base = 47,
    double? costo,
    List<PrecioNivel> niveles = const [],
    bool enLiq = false,
    required List<VipPrecioIntent> vips,
  }) =>
      VentaDetalleInput(
        descripcion: 'X',
        cantidad: 1,
        precioUnitario: base,
        precioBase: base,
        precioCostoSnapshot: costo,
        niveles: niveles,
        enLiquidacion: enLiq,
        vipIntents: vips,
      ).recalcularPrecioPorNiveles(1);

  group('VentaDetalleInput VIP — recalcularPrecioPorNiveles', () {
    test('costo puro gana cuando < base', () {
      final i = linea(base: 47, costo: 27.5, vips: [vipCosto()]);
      expect(i.precioUnitario, 27.5);
      expect(i.esPrecioVip, isTrue);
      expect(i.nivelAplicado, 'VIP: Costo');
    });

    test('costo + markup 5%', () {
      final i = linea(base: 100, costo: 20, vips: [vipCosto(markup: 5)]);
      expect(i.precioUnitario, closeTo(21, 0.0001));
    });

    test('costo null → no aplica, queda base', () {
      final i = linea(base: 47, costo: null, vips: [vipCosto()]);
      expect(i.precioUnitario, 47);
      expect(i.esPrecioVip, isFalse);
    });

    test('costo 0 → no aplica (espejo backend, no vende a 0)', () {
      final i = linea(base: 47, costo: 0, vips: [vipCosto()]);
      expect(i.precioUnitario, 47);
    });

    test('mayor PRIMER_NIVEL: aplica el escalón de 3 desde la unidad 1', () {
      final i = linea(base: 47, niveles: [nivelFijo(3, 39.9)], vips: [vipMayor()]);
      expect(i.precioUnitario, 39.9);
      expect(i.esPrecioVip, isTrue);
    });

    test('mayor MEJOR_NIVEL con PrecioNivelModel (covarianza) → menor precio', () {
      final i = linea(
        base: 47,
        niveles: [nivelModel(3, 39.9), nivelModel(10, 35)],
        vips: [vipMayor(estrategia: EstrategiaMayor.mejorNivel)],
      );
      expect(i.precioUnitario, 35);
    });

    test('mayor sin niveles → no aplica', () {
      final i = linea(base: 47, niveles: const [], vips: [vipMayor()]);
      expect(i.precioUnitario, 47);
    });

    test('porcentaje 15%', () {
      final i = linea(base: 100, vips: [vipPct(15)]);
      expect(i.precioUnitario, closeTo(85, 0.0001));
    });

    test('porcentaje capeado por descuentoMaximo', () {
      final i = linea(base: 100, vips: [vipPct(50, max: 10)]);
      expect(i.precioUnitario, 90);
    });

    test('monto fijo no baja de 0', () {
      final i = linea(base: 100, vips: [vipMonto(200)]);
      expect(i.precioUnitario, 0);
    });

    test('DOS políticas (costo + mayor) → gana el menor', () {
      final i = linea(
        base: 47,
        costo: 27.5,
        niveles: [nivelFijo(3, 39.9)],
        vips: [vipCosto(), vipMayor()],
      );
      expect(i.precioUnitario, 27.5); // costo (27.5) < mayor (39.9)
      expect(i.nivelAplicado, 'VIP: Costo');
    });

    test('liquidación (en base) gana sobre VIP costo (gana el menor)', () {
      // En liquidación, precioBase = precio de liquidación (efectivo).
      final i = linea(base: 5, costo: 27.5, enLiq: true, vips: [vipCosto()]);
      expect(i.precioUnitario, 5);
      expect(i.esPrecioVip, isFalse);
    });
  });

  group('VipResolver.intentsParaProducto', () {
    VipPoliticaVigente pol({
      required String id,
      ModoPrecioVip modo = ModoPrecioVip.precioCosto,
      bool todos = true,
      Set<String> productos = const {},
      Map<String, double> override = const {},
      double valor = 0,
    }) =>
        VipPoliticaVigente(
          politicaId: id,
          nombre: id,
          modo: modo,
          valor: valor,
          markupSobreCosto: 0,
          estrategiaMayor: EstrategiaMayor.primerNivel,
          descuentoMaximo: null,
          prioridad: 0,
          aplicarATodos: todos,
          productoIds: productos,
          overridePorProducto: override,
        );

    test('aplicarATodos → aplica a cualquier producto', () {
      expect(
        VipResolver([pol(id: 'a', todos: true)]).intentsParaProducto('px').length,
        1,
      );
    });

    test('scope por producto: solo si está en la lista', () {
      final r = VipResolver([pol(id: 'a', todos: false, productos: {'prod-1'})]);
      expect(r.intentsParaProducto('prod-1').length, 1);
      expect(r.intentsParaProducto('prod-2'), isEmpty);
    });

    test('devuelve TODAS las aplicables (multi-política)', () {
      final r = VipResolver([pol(id: 'a'), pol(id: 'b')]);
      expect(r.intentsParaProducto('px').length, 2);
    });

    test('override por producto cambia el valor', () {
      final r = VipResolver([
        pol(
          id: 'a',
          modo: ModoPrecioVip.porcentaje,
          valor: 10,
          override: {'prod-1': 25},
        ),
      ]);
      expect(r.intentsParaProducto('prod-1').first.valor, 25);
      expect(r.intentsParaProducto('prod-2').first.valor, 10);
    });
  });
}
