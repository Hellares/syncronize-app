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

  StockPorSedeInfo stock(String sedeId, int cantidad) => StockPorSedeInfo(
        sedeId: sedeId,
        sedeNombre: sedeId,
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
    final p = producto(stocks: [stock(sedeB, 40)]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | NUEVO en esta sede');
    expect(productoEstaEnSede(p, sedeA), isFalse);
  });

  test('stock 0 en la sede NO es lo mismo que no estar en la sede', () {
    final p = producto(stocks: [stock(sedeA, 0)]);

    expect(labelProductoCompra(p, sedeA), 'Taladro | Stock: 0');
    expect(productoEstaEnSede(p, sedeA), isTrue);
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

  test('con variantes que solo viven en otra sede, marca NUEVO', () {
    final p = producto(
      variantes: [
        variante('v1', [stock(sedeB, 9)]),
      ],
    );

    expect(labelProductoCompra(p, sedeA), 'Taladro | NUEVO en esta sede');
  });

  test('sin sede cae al nombre pelado', () {
    expect(labelProductoCompra(producto(), null), 'Taladro');
  });
}
