import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/presentation/pages/compra_productos_page.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// El catálogo que se pide para COMPRAR no es el que se pide para vender.
void main() {
  group('filtros del catálogo', () {
    test('pide el catálogo completo, no solo lo que ya vive en la sede', () {
      // Con `sedeId` y sin `mostrarTodos`, el backend devuelve SOLO lo que ya
      // tiene ProductoStock en esa sede: los productos que se están por dar de
      // alta ahí no aparecen y el usuario los crea duplicados.
      expect(CompraProductosPage.filtros.mostrarTodos, isTrue);
    });

    test('no excluye insumos: los insumos se compran', () {
      // null = todos. `false` los dejaría afuera, que es lo que necesita la
      // venta y lo contrario de lo que necesita una compra.
      expect(CompraProductosPage.filtros.esInsumo, isNull);
    });

    test('no ofrece combos ni productos dados de baja', () {
      expect(CompraProductosPage.filtros.soloProductos, isTrue);
      expect(CompraProductosPage.filtros.isActive, isTrue);
    });

    test('la query sale con mostrarTodos y sin filtro de insumo', () {
      final params = CompraProductosPage.filtros.toQueryParams();

      expect(params['mostrarTodos'], 'true');
      expect(params['soloProductos'], 'true');
      expect(params['isActive'], 'true');
      expect(params.containsKey('esInsumo'), isFalse);
    });
  });

  group('snapshot que consume la grilla', () {
    test('el total de la línea es cantidad × costo, sin sumarle IGV', () {
      // La grilla suma `total` de cada línea para el globo del carrito. El
      // IGV de una compra se decide en el formulario (el toggle "los precios
      // ya incluyen IGV"), así que acá la línea se arma como si ya lo
      // incluyera: si no, el globo mostraría un 18% que nadie cargó.
      const linea = VentaDetalleInput(
        descripcion: 'ARROZ',
        cantidad: 3,
        precioUnitario: 3.2,
        precioIncluyeIgv: true,
      );

      expect(linea.total, closeTo(9.6, 1e-9));
    });

    test('sin esa marca, la misma línea se infla con el IGV', () {
      const linea = VentaDetalleInput(
        descripcion: 'ARROZ',
        cantidad: 3,
        precioUnitario: 3.2,
      );

      expect(linea.total, closeTo(11.33, 1e-9));
    });
  });
}
