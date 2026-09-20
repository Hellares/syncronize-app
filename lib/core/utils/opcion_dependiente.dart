/// Campo de plantilla con seleccion en CASCADA (`OPCION_DEPENDIENTE`).
///
/// Fabricante -> Familia -> Modelo: cada nivel ofrece solo lo que cuelga del
/// valor elegido en el anterior. El arbol vive en `campo.opciones`:
///
///     {
///       "niveles": ["Fabricante", "Familia", "Modelo"],
///       "arbol": [ { "valor": "QUALCOMM",
///                    "hijos": [ { "valor": "SNAPDRAGON",
///                                 "hijos": [ { "valor": "8 Gen 3" } ] } ] } ]
///     }
///
/// El VALOR guardado es la ruta unida por [sepDependiente].
///
/// 🔴 Separador ASCII a proposito: este valor sale impreso en tickets
/// termicos, cuyos code pages no tienen cualquier caracter.
library;

const String sepDependiente = ' / ';

class NodoOpcion {
  final String valor;
  final List<NodoOpcion> hijos;

  const NodoOpcion(this.valor, [this.hijos = const []]);
}

class ArbolDependiente {
  final List<String> niveles;
  final List<NodoOpcion> arbol;

  const ArbolDependiente(this.niveles, this.arbol);
}

List<NodoOpcion>? _nodos(dynamic lista) {
  if (lista is! List) return null;
  final out = <NodoOpcion>[];
  for (final e in lista) {
    if (e is! Map) return null;
    final valor = e['valor'];
    if (valor is! String || valor.trim().isEmpty) return null;
    final hijos = e.containsKey('hijos') ? _nodos(e['hijos']) : <NodoOpcion>[];
    if (hijos == null) return null;
    out.add(NodoOpcion(valor, hijos));
  }
  return out;
}

/// Lee `opciones` como arbol, o null si no tiene la forma esperada.
///
/// Devolver null y no tirar es a proposito: un campo mal configurado se avisa
/// en pantalla, no rompe el formulario entero.
ArbolDependiente? leerArbolDependiente(dynamic opciones) {
  if (opciones is! Map) return null;
  final niveles = opciones['niveles'];
  if (niveles is! List || niveles.isEmpty) return null;
  if (niveles.any((n) => n is! String || n.trim().isEmpty)) return null;
  final arbol = _nodos(opciones['arbol']);
  if (arbol == null) return null;
  return ArbolDependiente(
    niveles.map((n) => n as String).toList(),
    arbol,
  );
}

/// Los hijos del nodo al que llega [ruta] (la raiz si la ruta esta vacia).
List<NodoOpcion> hijosDeRuta(ArbolDependiente a, List<String> ruta) {
  var nivel = a.arbol;
  for (final paso in ruta) {
    final i = nivel.indexWhere((n) => n.valor == paso);
    if (i < 0) return const [];
    nivel = nivel[i].hijos;
  }
  return nivel;
}

/// Parte "A / B / C" en sus tramos, tolerando espacios de mas.
List<String> partirRuta(String? valor) {
  if (valor == null) return const [];
  return valor
      .split('/')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}

/// Texto indentado -> arbol. Cada nivel se marca con 2 espacios (o un tab):
///
///     QUALCOMM
///       SNAPDRAGON
///         8 Gen 3
///
/// Se edita como texto y no con un constructor de nodos porque asi se tipea
/// y se PEGA rapido una lista de modelos, que es como se cargan de verdad.
/// Mismo formato que la web.
List<Map<String, dynamic>> textoAArbol(String texto) {
  final raiz = <Map<String, dynamic>>[];
  final pila = <List<Map<String, dynamic>>>[raiz];
  for (final linea in texto.split(RegExp(r'\r?\n'))) {
    if (linea.trim().isEmpty) continue;
    final sangria = RegExp(r'^[\t ]*').firstMatch(linea)?.group(0) ?? '';
    final prof = sangria.replaceAll('\t', '  ').length ~/ 2;
    final nivel = prof < pila.length ? prof : pila.length - 1;
    final hijos = <Map<String, dynamic>>[];
    final nodo = <String, dynamic>{'valor': linea.trim(), 'hijos': hijos};
    pila[nivel].add(nodo);
    pila.removeRange(nivel + 1, pila.length);
    pila.add(hijos);
  }

  List<Map<String, dynamic>> limpiar(List<Map<String, dynamic>> ns) {
    return ns.map((n) {
      final hijos = limpiar((n['hijos'] as List).cast<Map<String, dynamic>>());
      return hijos.isEmpty
          ? <String, dynamic>{'valor': n['valor']}
          : <String, dynamic>{'valor': n['valor'], 'hijos': hijos};
    }).toList();
  }

  return limpiar(raiz);
}

/// Arbol -> texto indentado, para volver a editarlo.
String arbolATexto(List<NodoOpcion> nodos, [int prof = 0]) {
  return nodos.map((n) {
    final linea = '  ' * prof + n.valor;
    final hijos = n.hijos.isEmpty ? '' : '\n${arbolATexto(n.hijos, prof + 1)}';
    return '$linea$hijos';
  }).join('\n');
}
