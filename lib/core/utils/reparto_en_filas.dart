/// Reparto de N controles compactos en filas de un formulario.
///
/// La regla la fijo el user: "maximo 3 por fila, y 2 si no hay para poner 3".
/// Por eso NO alcanza con partir de a 3: con 4 campos eso deja `[3, 1]`, un
/// control huerfano contra el borde izquierdo y dos tercios de fila vacios.
/// Se reparte lo mas parejo posible sin pasarse de [maximo]:
///
///     1 -> [1]      4 -> [2, 2]     7 -> [3, 2, 2]
///     2 -> [2]      5 -> [3, 2]     8 -> [3, 3, 2]
///     3 -> [3]      6 -> [3, 3]    10 -> [3, 3, 2, 2]
///
/// Las filas mas cargadas quedan ARRIBA: un formulario se lee de arriba
/// hacia abajo y la fila corta molesta menos al final.
///
/// 🔴 Esto decide cuantos entran, NO si entran: el ancho minimo por celda lo
/// resuelve quien llama (ver `kAnchoMinimoCampoCompacto` en el renderer),
/// porque depende del ancho real que le den al formulario.
library;

List<int> repartirEnFilas(int cantidad, int maximo) {
  if (cantidad <= 0) return const <int>[];
  final porFila = maximo < 1 ? 1 : maximo;
  if (cantidad <= porFila) return <int>[cantidad];

  final filas = (cantidad + porFila - 1) ~/ porFila;
  final base = cantidad ~/ filas;
  final resto = cantidad % filas;
  return <int>[
    for (var i = 0; i < filas; i++) i < resto ? base + 1 : base,
  ];
}
