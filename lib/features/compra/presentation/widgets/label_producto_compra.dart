import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../producto/domain/entities/stock_por_sede_info.dart';

/// Label del buscador de productos en el flujo de COMPRA (recepciones).
///
/// Muestra el stock EN LA SEDE que recibe, no el de la empresa: `stockTotal`
/// suma todas las sedes y para un producto con variantes mira al padre, que
/// casi siempre está en 0 — un número sin relación con la sede.
///
/// Tampoco muestra precio de venta: acá lo que importa es cuánto hay y cuánto
/// costó, no a cuánto se vende.
///
/// Casos:
/// - `Taladro | Stock: 3` — lo normal.
/// - `Taladro | Stock: 0 · 5 en Chiclayo` — en esta sede no hay, pero en otra
///   sí. Sin ese aviso, un 0 pelado esconde que no hace falta comprar: puede
///   alcanzar con una transferencia. El dato ya viene en la respuesta del
///   buscador (`stocksPorSede` trae TODAS las sedes), no cuesta un request.
/// - `Taladro | NUEVO en esta sede · 5 en Chiclayo` — todavía no vive acá; lo
///   habilita `ProductoSedeSelector.mostrarTodos`. Se marca aparte para que
///   quede claro por qué su stock es 0 y que no hace falta crearlo de nuevo, y
///   lleva el mismo aviso: casi siempre está en otra sede, que es de donde
///   salió a la lista.
String labelProductoCompra(ProductoListItem producto, String? sedeId) {
  if (sedeId == null) return producto.nombre;

  final esNuevoAca = !productoEstaEnSede(producto, sedeId);
  final enLaSede = esNuevoAca ? 0 : producto.stockConsolidadoEnSede(sedeId);
  final estado = esNuevoAca ? 'NUEVO en esta sede' : 'Stock: $enLaSede';

  // El aviso de otras sedes va SOLO cuando acá no hay nada disponible: es el
  // caso donde el dato cambia la decisión. Con stock en la sede, el label se
  // queda corto.
  if (enLaSede > 0) return '${producto.nombre} | $estado';

  final otras = stockEnOtrasSedes(producto, sedeId);
  if (otras.unidades <= 0) return '${producto.nombre} | $estado';

  final detalle = otras.sedes.length == 1
      ? '${otras.unidades} en ${otras.sedes.single}'
      : '${otras.unidades} en ${otras.sedes.length} sedes';
  return '${producto.nombre} | $estado · $detalle';
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

/// Unidades disponibles fuera de [sedeId] y en qué sedes están.
///
/// Suma el producto base y sus variantes, agrupando por sede: una misma sede
/// puede aparecer en las dos partes (stock residual del padre + variantes) y
/// tiene que contar como UNA sede.
StockOtrasSedes stockEnOtrasSedes(ProductoListItem producto, String sedeId) {
  final unidadesPorSede = <String, int>{};
  final nombrePorSede = <String, String>{};

  void acumular(List<StockPorSedeInfo>? stocks) {
    if (stocks == null) return;
    for (final stock in stocks) {
      if (stock.sedeId == sedeId || stock.cantidad <= 0) continue;
      unidadesPorSede[stock.sedeId] =
          (unidadesPorSede[stock.sedeId] ?? 0) + stock.cantidad;
      nombrePorSede[stock.sedeId] = stock.sedeNombre;
    }
  }

  acumular(producto.stocksPorSede);
  for (final variante in producto.variantes ?? const <ProductoVariante>[]) {
    acumular(variante.stocksPorSede);
  }

  return StockOtrasSedes(
    unidades: unidadesPorSede.values.fold(0, (sum, v) => sum + v),
    sedes: unidadesPorSede.keys.map((id) => nombrePorSede[id]!).toList(),
  );
}

/// Stock del producto fuera de la sede en la que se está trabajando.
class StockOtrasSedes {
  final int unidades;

  /// Nombres de las sedes con stock disponible (solo las que tienen > 0).
  final List<String> sedes;

  const StockOtrasSedes({required this.unidades, required this.sedes});
}
