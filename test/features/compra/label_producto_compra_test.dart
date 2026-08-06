import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/presentation/widgets/label_producto_compra.dart';
import 'package:syncronize/features/producto/domain/entities/producto_list_item.dart';
import 'package:syncronize/features/producto/domain/entities/producto_variante.dart';
import 'package:syncronize/features/producto/domain/entities/stock_por_sede_info.dart';

/// En una recepción el número que importa es el stock de la sede que recibe.
/// `stockTotal` sumaba TODAS las sedes y, con variantes, miraba al producto
/// padre (que no tiene fila de stock: cuelga de la variante).
void main() {
  const sedeA = 'sede-a';
  const sedeB = 'sede-b';

  StockPorSedeInfo stock(String sedeId, int cantidad, {String? nombre}) =>
      StockPorSedeInfo(
        sedeId: sedeId,
        sedeNombre: nombre ?? sedeId,
        sedeCodigo: sedeId,
        cantidad: cantidad,
      );

  ProductoVariante variante(String id, List<StockPorSedeInfo> stocks) =>
      ProductoVariante(
        id: id,
        productoId: 'p1',
        empresaId: 'e1',
        nombre: 'Variante $id',
        sku: id,
        codigoEmpresa: id,
        atributosValores: const [],
        stocksPorSede: stocks,
        isActive: true,
        orden: 0,
        creadoEn: DateTime(2026),
        actualizadoEn: DateTime(2026),
      );

  ProductoListItem producto({
    List<StockPorSedeInfo>? stocks,
    List<ProductoVariante>? variantes,
  }) =>
      ProductoListItem(
        id: 'p1',
        nombre: 'Taladro',
        codigoEmpresa: 'P-001',
        destacado: false,
        isActive: true,
        tieneVariantes: variantes != null,
        variantes: variantes,
        stocksPorSede: stocks,
      );

  test('muestra el stock de la sede, no la suma de todas', () {
    final p = producto(stocks: [stock(sedeA, 3), stock(sedeB, 40)]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 3');
    expect(p.stockTotal, 43); // lo que se mostraba antes
  });

  test('marca NUEVO cuando el producto no tiene stock en esa sede', () {
    final p = producto(stocks: [stock(sedeB, 40, nombre: 'Chiclayo')]);

    expect(
      labelProductoCompra(p, sedeA),
      'Taladro | NUEVO en esta sede · 40 en Chiclayo',
    );
    expect(productoEstaEnSede(p, sedeA), isFalse);
  });

  test('NUEVO sin stock en ninguna otra sede va sin aviso', () {
    final p = producto(stocks: [stock(sedeB, 0, nombre: 'Chiclayo')]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | NUEVO en esta sede');
  });

  test('stock 0 en la sede NO es lo mismo que no estar en la sede', () {
    final p = producto(stocks: [stock(sedeA, 0)]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 0');
    expect(productoEstaEnSede(p, sedeA), isTrue);
  });

  test('en 0 acá pero con stock en otra sede, avisa cuál y cuánto', () {
    final p = producto(stocks: [
      stock(sedeA, 0),
      stock(sedeB, 5, nombre: 'Chiclayo'),
    ]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 0 · 5 en Chiclayo');
  });

  test('en 0 acá y stock en varias sedes, resume la cantidad de sedes', () {
    final p = producto(stocks: [
      stock(sedeA, 0),
      stock(sedeB, 5, nombre: 'Chiclayo'),
      stock('sede-c', 3, nombre: 'Trujillo'),
    ]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 0 · 8 en 2 sedes');
  });

  test('con stock en la sede NO agrega el aviso de otras sedes', () {
    final p = producto(stocks: [
      stock(sedeA, 3),
      stock(sedeB, 40, nombre: 'Chiclayo'),
    ]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 3');
  });

  test('las otras sedes en 0 no cuentan como stock disponible', () {
    final p = producto(stocks: [
      stock(sedeA, 0),
      stock(sedeB, 0, nombre: 'Chiclayo'),
    ]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 0');
  });

  test('con variantes suma las otras sedes y cuenta cada sede una vez', () {
    // sedeB aparece en las dos variantes: son 5+2 unidades en UNA sola sede.
    final p = producto(
      stocks: [stock(sedeA, 0)],
      variantes: [
        variante('v1', [stock(sedeB, 5, nombre: 'Chiclayo')]),
        variante('v2', [stock(sedeB, 2, nombre: 'Chiclayo')]),
      ],
    );

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 0 · 7 en Chiclayo');
  });

  test('con variantes suma las de la sede y no lo da por nuevo', () {
    // El padre no tiene stocksPorSede: las filas cuelgan de las variantes.
    final p = producto(
      variantes: [
        variante('v1', [stock(sedeA, 2), stock(sedeB, 9)]),
        variante('v2', [stock(sedeA, 5)]),
      ],
    );

    expect(productoEstaEnSede(p, sedeA), isTrue);
    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 7');
  });

  test('con variantes que solo viven en otra sede, marca NUEVO y avisa', () {
    final p = producto(
      variantes: [
        variante('v1', [stock(sedeB, 9, nombre: 'Chiclayo')]),
      ],
    );

    expect(
      labelProductoCompra(p, sedeA),
      'Taladro | NUEVO en esta sede · 9 en Chiclayo',
    );
  });

  test('sin sede cae al nombre pelado', () {
    expect(labelProductoCompra(producto(), null), 'Taladro');
  });
}
