import 'package:equatable/equatable.dart';

/// Una lectura de la balanza, ya normalizada a GRAMOS.
///
/// 🔑 Gramos y no kilos porque el resto del sistema trabaja en unidad atómica:
/// el stock es `Int` y un producto a granel se guarda en gramos. La conversión
/// a la unidad en la que se cobra (kg) la hace `UnidadPresentacion`, que es la
/// misma capa que ya usa el teclado. La balanza no inventa un camino nuevo:
/// reemplaza al teclado y entrega el mismo número.
class LecturaPeso extends Equatable {
  /// Peso en gramos. Puede venir con decimales si la balanza los reporta;
  /// redondear es responsabilidad de quien lo consume, no del parser.
  final double gramos;

  /// La balanza declaró que el peso está ASENTADO.
  ///
  /// 🔴 Es el dato que evita cobrar mal. Una lectura a medio asentar se ve
  /// perfecta en pantalla y se cobra distinto de lo que hay en el plato. El
  /// visor muestra el número en vivo, pero "Usar peso" solo se habilita con
  /// esto en `true`.
  ///
  /// Si el equipo no reporta estabilidad, el perfil se configura con
  /// `exigeEstable: false` y acá llega siempre `true`: preferimos dejar vender
  /// a bloquear la caja por un dato que esa balanza nunca va a mandar.
  final bool estable;

  /// La línea cruda de la que salió, tal como llegó. Solo para el diagnóstico
  /// de la pantalla de configuración; ninguna lógica de venta la mira.
  final String crudo;

  const LecturaPeso({
    required this.gramos,
    required this.estable,
    this.crudo = '',
  });

  /// Peso en la unidad en la que se cobra un granel. La balanza reporta gramos
  /// y el POS pide kilos.
  double get kilos => gramos / 1000;

  /// Lo que se manda al carrito: la unidad atómica es entera.
  int get gramosEnteros => gramos.round();

  /// Una tara mal hecha deja el plato en negativo. No es una lectura vendible.
  bool get esValidoParaVender => estable && gramos > 0;

  @override
  List<Object?> get props => [gramos, estable];

  @override
  String toString() =>
      'LecturaPeso(${gramos}g, ${estable ? 'estable' : 'inestable'})';
}
