/// Búsqueda de productos del lado del cliente.
///
/// 🔑 **Tiene que dar el mismo resultado que el backend.** Allá la búsqueda es
/// `Producto.textoBusqueda` (nombre + descripción + códigos + marca +
/// categoría, en minúsculas y sin tildes) partida en palabras, exigiendo que
/// **todas** aparezcan. Ver `backend/src/producto/texto-busqueda.util.ts`.
///
/// Por qué importa la simetría: el selector de productos filtra **local**
/// cuando ya tiene el catálogo entero descargado, y en ese caso **no le
/// pregunta al servidor**. Si el filtro local mira menos campos que el
/// backend, esas búsquedas devuelven vacío y el cajero concluye que el
/// producto no existe. Pasó exactamente eso al sumar marca y categoría al
/// backend: buscar por marca no encontraba nada en Venta Rápida.
library;

/// Minúsculas y sin tildes. Equivale a `lower(unaccent(...))` de Postgres.
///
/// Dart no trae normalización Unicode en el core, así que se mapean a mano
/// los caracteres que aparecen en catálogos peruanos. Alcanza: `unaccent`
/// hace lo mismo para este conjunto.
String normalizarTexto(String texto) {
  const equivalencias = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  final minuscula = texto.toLowerCase();
  final buffer = StringBuffer();
  for (final char in minuscula.characters()) {
    buffer.write(equivalencias[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Palabras únicas de la consulta, ya normalizadas. Vacío si no hay nada
/// que buscar.
List<String> terminosBusqueda(String consulta) {
  final normalizada = normalizarTexto(consulta);
  if (normalizada.isEmpty) return const [];
  final vistos = <String>{};
  for (final palabra in normalizada.split(' ')) {
    if (palabra.isNotEmpty) vistos.add(palabra);
  }
  return vistos.toList();
}

/// ¿El texto contiene **todas** las palabras? El orden no importa, y cada
/// palabra vale como fragmento en cualquier posición — así "mon te 24"
/// encuentra "MONITOR TEROS 24 PULGADAS", igual que en el backend.
bool coincideTodosLosTerminos(String texto, List<String> terminos) {
  if (terminos.isEmpty) return true;
  final heno = normalizarTexto(texto);
  return terminos.every(heno.contains);
}

extension _Caracteres on String {
  Iterable<String> characters() sync* {
    for (var i = 0; i < length; i++) {
      yield this[i];
    }
  }
}
