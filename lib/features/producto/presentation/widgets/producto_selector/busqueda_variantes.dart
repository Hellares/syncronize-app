import '../../../../../core/utils/busqueda_texto.dart';
import '../../../domain/entities/producto_list_item.dart';
import '../../../domain/entities/producto_variante.dart';
import '../../pages/separar_por_diseno_page.dart' show kClaveAtributoDiseno;
import '../coleccion_disenos_card.dart' show claveColeccion;

/// Un producto que aparece en la búsqueda POR SUS VARIANTES, no por su nombre:
/// quien pide "un CRISTAL" no sabe que el producto se llama EDREDONES.
class CoincidenciaVariantes {
  /// Las variantes activas que coinciden.
  final List<ProductoVariante> variantes;

  /// Lo que se le pasa al selector de variantes para que abra ya filtrado:
  /// solo las palabras que NO explica el producto ("edredones cristal" →
  /// "cristal"), porque el selector busca en las variantes y el nombre del
  /// producto no está ahí.
  final String consulta;

  /// El chip de la card: "CRISTAL · 2" (el valor que coincidió y cuántas
  /// colecciones lo tienen).
  final String etiqueta;

  /// El valor que coincidió ("CRISTAL"): el título de la card.
  final String valor;

  /// Cuántas colecciones lo tienen (TELA con sus diseños cuenta una).
  final int colecciones;

  const CoincidenciaVariantes({
    required this.variantes,
    required this.consulta,
    required this.etiqueta,
    required this.valor,
    required this.colecciones,
  });
}

/// Texto del producto en sí: lo mismo que mira el buscador de la grilla.
String textoDeProducto(ProductoListItem p) => [
      p.nombre,
      p.codigoEmpresa,
      p.marcaNombre ?? '',
      p.categoriaNombre ?? '',
    ].join(' ');

/// Lo que se busca de una variante: sus valores sin el Diseño (D1, D2… no
/// los busca nadie) y, si no tiene atributos, su nombre. Mismo criterio que
/// el backend (`texto-busqueda.service.ts`). El nombre de una variante con
/// atributos NO entra: lleva el "D1" adentro.
List<String> valoresBuscables(ProductoVariante v) => v.atributosValores.isEmpty
    ? [v.nombre]
    : [
        for (final a in v.atributosValores)
          if (a.atributo.clave != kClaveAtributoDiseno) a.valor,
      ];

/// Si [p] aparece en la búsqueda [query] SOLO por sus variantes, cuáles y cómo
/// rotularlo. Null si coincide por su propio nombre (la búsqueda de siempre),
/// si no coincide, o si no tiene variantes.
CoincidenciaVariantes? coincidenciaPorVariantes(ProductoListItem p, String query) {
  final terminos = terminosBusqueda(query);
  if (terminos.isEmpty) return null;
  final variantes = (p.variantes ?? const <ProductoVariante>[]).where((v) => v.isActive);
  if (variantes.isEmpty) return null;

  final textoProducto = textoDeProducto(p);
  if (coincideTodosLosTerminos(textoProducto, terminos)) return null;

  final coinciden = [
    for (final v in variantes)
      if (coincideTodosLosTerminos(
          '$textoProducto ${valoresBuscables(v).join(' ')}', terminos))
        v,
  ];
  if (coinciden.isEmpty) return null;

  // Las palabras que pone la variante, no el producto.
  final propios = [
    for (final t in terminos)
      if (!coincideTodosLosTerminos(textoProducto, [t])) t,
  ];

  // El valor que coincidió: el primero de la primera variante que contiene
  // alguna de esas palabras ("CRISTAL"). Si ninguno, el nombre de la variante.
  final v0 = coinciden.first;
  final candidatos = [...valoresBuscables(v0), v0.nombre];
  final valor = candidatos.firstWhere(
    (c) => propios.any((t) => normalizarTexto(c).contains(t)),
    orElse: () => v0.nombre,
  );
  final colecciones = {for (final v in coinciden) claveColeccion(v)}.length;

  return CoincidenciaVariantes(
    variantes: coinciden,
    consulta: propios.join(' '),
    etiqueta: colecciones > 1 ? '$valor · $colecciones' : valor,
    valor: valor,
    colecciones: colecciones,
  );
}
