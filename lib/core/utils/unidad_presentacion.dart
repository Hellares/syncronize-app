/// Traduce entre la unidad en la que el sistema GUARDA y la unidad en la que
/// el usuario PIENSA.
///
/// Un alimento a granel se guarda en gramos —para que el stock entero aguante
/// los 22 000 de un saco y, más adelante, la lectura de una balanza— pero
/// nadie lee "22000" ni "S/0.008". Con la presentación configurada (kg = 1000
/// g) eso se muestra como **22 kg** y **S/8.00/kg**.
///
/// Sin presentación el factor es 1 y todo queda exactamente como antes, así
/// que se puede usar en cualquier pantalla sin preguntar si el producto la
/// tiene.
class UnidadPresentacion {
  /// Unidades de venta que trae 1 de presentación (1 kg = 1000 g).
  final double factor;

  /// Símbolo de la presentación, ej. "kg".
  final String? simbolo;

  /// Símbolo de la unidad de venta, ej. "g". Es el fallback cuando no hay
  /// presentación configurada.
  final String? simboloVenta;

  const UnidadPresentacion({
    required this.factor,
    this.simbolo,
    this.simboloVenta,
  });

  /// Producto sin presentación: todo se muestra tal cual está guardado.
  const UnidadPresentacion.ninguna()
      : factor = 1,
        simbolo = null,
        simboloVenta = null;

  bool get activa =>
      factor > 1 && simbolo != null && simbolo!.isNotEmpty;

  /// En qué unidad se le habla al usuario.
  String? get simboloVisible => activa ? simbolo : simboloVenta;

  /// Cantidad guardada → cantidad que se muestra. 22 000 g → 22 (kg).
  double cantidad(num enUnidadDeVenta) =>
      activa ? enUnidadDeVenta / factor : enUnidadDeVenta.toDouble();

  /// Precio POR unidad de venta → precio por unidad mostrada.
  /// S/0.008 el gramo → S/8.00 el kilo.
  double precio(double porUnidadDeVenta) =>
      activa ? porUnidadDeVenta * factor : porUnidadDeVenta;

  /// Lo que el usuario escribió (por unidad mostrada) → por unidad de venta,
  /// que es como se guarda SIEMPRE.
  double aUnidadDeVenta(double porUnidadMostrada) =>
      activa ? porUnidadMostrada / factor : porUnidadMostrada;

  /// "22 kg" · "20.5 kg" · "1.237 kg" · sin presentación, "22000".
  ///
  /// Hasta 3 decimales y sin ceros de relleno: con base en gramos, 3 decimales
  /// de un kilo son exactamente 1 g, así que no se pierde precisión al mostrar
  /// y no queda "22.000 kg", que se lee horrible.
  String cantidadTexto(num enUnidadDeVenta, {bool conSimbolo = true}) {
    final valor = cantidad(enUnidadDeVenta);
    final texto = _sinCerosSobrantes(valor, 3);
    if (!conSimbolo || simboloVisible == null) return texto;
    return '$texto ${simboloVisible!}';
  }

  /// "S/ 8.00/kg". Los precios siempre con 2 decimales: en la unidad en la que
  /// se habla, el precio ya es un número normal.
  String precioTexto(
    double porUnidadDeVenta, {
    String moneda = 'S/',
    bool conSimbolo = true,
  }) {
    final valor = precio(porUnidadDeVenta).toStringAsFixed(2);
    if (!conSimbolo || !activa) return '$moneda $valor';
    return '$moneda $valor/$simbolo';
  }

  static String _sinCerosSobrantes(double v, int maxDecimales) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(maxDecimales);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    return s.replaceFirst(RegExp(r'\.$'), '');
  }
}
