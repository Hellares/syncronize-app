import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncronize/features/herramientas/presentation/services/listas_mostrador_store.dart';
import 'package:syncronize/features/producto/domain/entities/precio_nivel.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// Tests del guardado local de listas de la Calculadora de Mostrador.
/// Lo crítico es la PARIDAD toJson=fromJson del snapshot (un campo que se
/// serializa mal reaparece como precio/IGV incorrecto al re-abrir la
/// lista) y que los niveles por mayor sigan recalculando tras restaurar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime(2026, 1, 1);

  PrecioNivel nivelFijo(int min, double precio) => PrecioNivel(
        id: 'n1',
        nombre: 'Por Mayor',
        cantidadMinima: min,
        cantidadMaxima: null,
        tipoPrecio: TipoPrecioNivel.precioFijo,
        precio: precio,
        orden: 0,
        isActive: true,
        creadoEn: t0,
        actualizadoEn: t0,
      );

  PrecioNivel nivelPorcentaje(int min, double pct) => PrecioNivel(
        id: 'n2',
        nombre: 'Docena',
        cantidadMinima: min,
        cantidadMaxima: null,
        tipoPrecio: TipoPrecioNivel.porcentajeDescuento,
        porcentajeDesc: pct,
        orden: 1,
        isActive: true,
        creadoEn: t0,
        actualizadoEn: t0,
      );

  VentaDetalleInput itemCompleto() => VentaDetalleInput(
        productoId: 'prod-1',
        varianteId: 'var-1',
        descripcion: 'Peluche Lucifer — Modelo A',
        cantidad: 2.5,
        precioUnitario: 39.9,
        precioBase: 49.9,
        precioIncluyeIgv: true,
        porcentajeIGV: 18.0,
        stockDisponible: 15,
        nivelAplicado: 'Por Mayor',
        descuentoNivelPct: 20.0,
        enOferta: true,
        enLiquidacion: false,
        precioAntesOferta: 59.9,
        niveles: [nivelFijo(3, 39.9), nivelPorcentaje(12, 10)],
      );

  ListaMostradorGuardada lista(String id, List<VentaDetalleInput> items,
          {DateTime? fecha, String? nombre}) =>
      ListaMostradorGuardada(
        id: id,
        fecha: fecha ?? DateTime(2026, 7, 9, 14, 30),
        nombre: nombre,
        sedeId: 'sede-1',
        sedeNombre: 'Sede Principal',
        items: items,
      );

  /// Round-trip por STRING (igual que SharedPreferences): detecta tipos
  /// no serializables que un toJson/fromJson directo dejaría pasar.
  ListaMostradorGuardada roundTrip(ListaMostradorGuardada l) =>
      ListaMostradorGuardada.fromJson(
          jsonDecode(jsonEncode(l.toJson())) as Map<String, dynamic>);

  group('ListaMostradorGuardada serialización', () {
    test('round-trip preserva TODOS los campos del item', () {
      final r = roundTrip(lista('1', [itemCompleto()], nombre: 'Cliente Juan'));

      expect(r.id, '1');
      expect(r.fecha, DateTime(2026, 7, 9, 14, 30));
      expect(r.nombre, 'Cliente Juan');
      expect(r.sedeId, 'sede-1');
      expect(r.sedeNombre, 'Sede Principal');
      expect(r.items, hasLength(1));

      final it = r.items.first;
      expect(it.productoId, 'prod-1');
      expect(it.varianteId, 'var-1');
      expect(it.descripcion, 'Peluche Lucifer — Modelo A');
      expect(it.cantidad, 2.5);
      expect(it.precioUnitario, 39.9);
      expect(it.precioBase, 49.9);
      expect(it.precioIncluyeIgv, isTrue);
      expect(it.porcentajeIGV, 18.0);
      expect(it.stockDisponible, 15);
      expect(it.nivelAplicado, 'Por Mayor');
      expect(it.descuentoNivelPct, 20.0);
      expect(it.enOferta, isTrue);
      expect(it.enLiquidacion, isFalse);
      expect(it.precioAntesOferta, 59.9);
      expect(it.niveles, hasLength(2));
      expect(it.niveles[0].tipoPrecio, TipoPrecioNivel.precioFijo);
      expect(it.niveles[0].precio, 39.9);
      expect(it.niveles[0].cantidadMinima, 3);
      expect(it.niveles[1].tipoPrecio, TipoPrecioNivel.porcentajeDescuento);
      expect(it.niveles[1].porcentajeDesc, 10);
    });

    test('item mínimo restaura con defaults (campos ausentes en el JSON)',
        () {
      const minimo = VentaDetalleInput(
        productoId: 'prod-2',
        descripcion: 'Lapicero',
        cantidad: 1,
        precioUnitario: 2.5,
      );
      final it = roundTrip(lista('2', [minimo])).items.first;

      expect(it.productoId, 'prod-2');
      expect(it.varianteId, isNull);
      expect(it.cantidad, 1);
      expect(it.precioUnitario, 2.5);
      expect(it.precioBase, isNull);
      expect(it.precioIncluyeIgv, isFalse);
      expect(it.porcentajeIGV, 18.0);
      expect(it.stockDisponible, isNull);
      expect(it.nivelAplicado, isNull);
      expect(it.enOferta, isFalse);
      expect(it.enLiquidacion, isFalse);
      expect(it.niveles, isEmpty);
    });

    test('precioIncluyeIgv sobrevive el round-trip (total sin +18% fantasma)',
        () {
      const conIgv = VentaDetalleInput(
        productoId: 'p',
        descripcion: 'x',
        cantidad: 1,
        precioUnitario: 30,
        precioIncluyeIgv: true,
      );
      final it = roundTrip(lista('3', [conIgv])).items.first;
      // El bug clásico: si el flag se pierde, 30 se vuelve 35.40.
      expect(it.total, closeTo(30.0, 0.001));
      expect(roundTrip(lista('3b', [conIgv])).total, closeTo(30.0, 0.001));
    });

    test('niveles por mayor siguen recalculando tras restaurar', () {
      final base = VentaDetalleInput(
        productoId: 'p',
        descripcion: 'x',
        cantidad: 1,
        precioUnitario: 10,
        precioBase: 10,
        precioIncluyeIgv: true,
        niveles: [nivelFijo(3, 5)],
      );
      final it = roundTrip(lista('4', [base])).items.first;

      final con3 = it.recalcularPrecioPorNiveles(3);
      expect(con3.precioUnitario, 5);
      expect(con3.nivelAplicado, 'Por Mayor');

      // Bajar de la cantidad mínima vuelve al precio base.
      final con1 = con3.recalcularPrecioPorNiveles(1);
      expect(con1.precioUnitario, 10);
      expect(con1.nivelAplicado, isNull);
    });

    test('liquidación restaurada sigue ganando sobre los niveles', () {
      final liq = VentaDetalleInput(
        productoId: 'p',
        descripcion: 'x',
        cantidad: 1,
        precioUnitario: 4,
        precioBase: 4,
        precioIncluyeIgv: true,
        enLiquidacion: true,
        // Nivel que SUBIRÍA el precio del remate si se aplicara.
        niveles: [nivelFijo(3, 9)],
      );
      final it = roundTrip(lista('5', [liq])).items.first;
      final con12 = it.recalcularPrecioPorNiveles(12);
      expect(con12.precioUnitario, 4);
      expect(con12.nivelAplicado, isNull);
    });

    test('total de la lista = suma de items', () {
      const a = VentaDetalleInput(
          productoId: 'a',
          descripcion: 'a',
          cantidad: 2,
          precioUnitario: 10,
          precioIncluyeIgv: true);
      const b = VentaDetalleInput(
          productoId: 'b',
          descripcion: 'b',
          cantidad: 1,
          precioUnitario: 5.5,
          precioIncluyeIgv: true);
      expect(roundTrip(lista('6', [a, b])).total, closeTo(25.5, 0.001));
    });
  });

  group('ListasMostradorStore persistencia', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('guardar + cargar: más reciente primero', () async {
      await ListasMostradorStore.guardar(
          lista('1', [itemCompleto()], fecha: DateTime(2026, 7, 8)));
      await ListasMostradorStore.guardar(
          lista('2', [itemCompleto()], fecha: DateTime(2026, 7, 9)));

      final listas = await ListasMostradorStore.cargar();
      expect(listas.map((l) => l.id), ['2', '1']);
      expect(listas.first.items.first.descripcion,
          'Peluche Lucifer — Modelo A');
    });

    test('actualizar reemplaza por id, sube al tope y no duplica', () async {
      await ListasMostradorStore.guardar(
          lista('1', [itemCompleto()], nombre: 'Cliente Juan'));
      await ListasMostradorStore.guardar(lista('2', [itemCompleto()]));

      // "1" se actualiza con 2 items y debe subir al tope, sin duplicarse.
      const extra = VentaDetalleInput(
          productoId: 'extra',
          descripcion: 'Agregado después',
          cantidad: 1,
          precioUnitario: 9,
          precioIncluyeIgv: true);
      await ListasMostradorStore.actualizar(lista(
          '1', [itemCompleto(), extra],
          nombre: 'Cliente Juan', fecha: DateTime(2026, 7, 10)));

      final listas = await ListasMostradorStore.cargar();
      expect(listas.map((l) => l.id), ['1', '2']);
      expect(listas.first.items, hasLength(2));
      expect(listas.first.nombre, 'Cliente Juan');
      expect(listas.first.fecha, DateTime(2026, 7, 10));

      // Actualizar un id que ya no existe la re-crea (upsert).
      await ListasMostradorStore.eliminar('2');
      await ListasMostradorStore.actualizar(lista('2', [itemCompleto()]));
      expect((await ListasMostradorStore.cargar()).map((l) => l.id),
          ['2', '1']);
    });

    test('actualizar con alTope:false conserva la posición (re-cotización)',
        () async {
      await ListasMostradorStore.guardar(lista('1', [itemCompleto()]));
      await ListasMostradorStore.guardar(lista('2', [itemCompleto()]));
      await ListasMostradorStore.guardar(lista('3', [itemCompleto()]));

      // "1" está al fondo; el refresh silencioso NO debe moverla.
      const nuevo = VentaDetalleInput(
          productoId: 'p',
          descripcion: 'recotizado',
          cantidad: 1,
          precioUnitario: 99,
          precioIncluyeIgv: true);
      await ListasMostradorStore.actualizar(lista('1', [nuevo]),
          alTope: false);

      final listas = await ListasMostradorStore.cargar();
      expect(listas.map((l) => l.id), ['3', '2', '1']);
      expect(listas.last.items.single.precioUnitario, 99);
    });

    test('eliminar quita solo la lista indicada', () async {
      await ListasMostradorStore.guardar(lista('1', [itemCompleto()]));
      await ListasMostradorStore.guardar(lista('2', [itemCompleto()]));

      await ListasMostradorStore.eliminar('1');
      final listas = await ListasMostradorStore.cargar();
      expect(listas.map((l) => l.id), ['2']);

      // Eliminar un id inexistente no rompe nada.
      await ListasMostradorStore.eliminar('zzz');
      expect(await ListasMostradorStore.cargar(), hasLength(1));
    });

    test('tope 50: las más viejas se descartan', () async {
      for (var i = 1; i <= 52; i++) {
        await ListasMostradorStore.guardar(lista('$i', [itemCompleto()]));
      }
      final listas = await ListasMostradorStore.cargar();
      expect(listas, hasLength(50));
      // Más reciente primero; las 2 primeras guardadas ('1' y '2') salieron.
      expect(listas.first.id, '52');
      expect(listas.last.id, '3');
      expect(listas.any((l) => l.id == '1' || l.id == '2'), isFalse);
    });

    test('entrada corrupta se salta sin tumbar el resto', () async {
      final buena = lista('ok', [itemCompleto()]).toJson();
      SharedPreferences.setMockInitialValues({
        'calculadora_mostrador_listas': jsonEncode([
          {'id': 'rota'}, // sin fecha ni items → fromJson revienta
          buena,
        ]),
      });
      final listas = await ListasMostradorStore.cargar();
      expect(listas.map((l) => l.id), ['ok']);
    });

    test('raw ilegible devuelve lista vacía', () async {
      SharedPreferences.setMockInitialValues({
        'calculadora_mostrador_listas': '{esto no es json[',
      });
      expect(await ListasMostradorStore.cargar(), isEmpty);
    });
  });
}
