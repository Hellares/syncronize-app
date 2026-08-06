import '../../../producto/domain/entities/producto_list_item.dart';

/// Label del buscador de productos en el flujo de COMPRA (recepciones).
///
/// Muestra el stock EN LA SEDE que recibe, no el de la empresa: `stockTotal`
/// suma todas las sedes y para un producto con variantes mira al padre, que
/// casi siempre está en 0 — un número sin relación con la sede.
///
/// Tampoco muestra precio de venta: acá lo que importa es cuánto hay y cuánto
/// costó, no a cuánto se vende.
///
/// Los productos que todavía NO viven en esta sede (los habilita
/// `ProductoSedeSelector.mostrarTodos`) se marcan aparte, para que quede claro
/// por qué su stock es 0 y que no hace falta crearlos de nuevo.
String labelProductoCompra(ProductoListItem producto, String? sedeId) {
  if (sedeId == null) return producto.nombre;
  if (!productoEstaEnSede(producto, sedeId)) {
    return '${producto.nombre} | NUEVO en esta sede';
  }
  return '${producto.nombre} | Stock: ${producto.stockConsolidadoEnSede(sedeId)}';
}

/// True si el producto ya tiene stock creado en la sede, sea en el producto
/// base o en alguna de sus variantes: con variantes, la fila de ProductoStock
/// cuelga de la variante y el padre no tiene ninguna (es un XOR).
bool productoEstaEnSede(ProductoListItem producto, String sedeId) {
  if (producto.stockSedeInfo(sedeId) != null) return true;
  final variantes = producto.variantes;
  if (variantes == null) return false;
  return variantes.any((v) => v.stockSedeInfo(sedeId) != null);
}
