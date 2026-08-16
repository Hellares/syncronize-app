import 'package:equatable/equatable.dart';

/// En qué unidad reporta el equipo cuando la trama no lo dice.
enum UnidadPeso {
  kg,
  g;

  String get label => this == UnidadPeso.kg ? 'Kilogramos (kg)' : 'Gramos (g)';

  double aGramos(double valor) => this == UnidadPeso.kg ? valor * 1000 : valor;

  static UnidadPeso fromString(String? v) =>
      (v ?? '').toLowerCase() == 'g' ? UnidadPeso.g : UnidadPeso.kg;
}

/// Cómo leer la trama que manda una balanza.
///
/// 🔑 Esta clase es el módulo entero. Los paquetes de Bluetooth solo cambian
/// CÓMO llegan los bytes; lo que cambia de marca a marca es qué dicen:
///
///     ST,GS,+  1.234kg      CAS / Toledo y compatibles
///     +0001.234kg           sin estado, solo signo y unidad
///     1.234                 número pelado (típico de módulos BLE genéricos)
///
/// Por eso el formato es CONFIGURABLE y no una implementación por modelo: no
/// sabemos qué balanzas va a comprar el cliente, y no se puede pedir un deploy
/// cada vez que aparece una marca nueva.
class PerfilTrama extends Equatable {
  /// Nombre visible del perfil ("CAS / Toledo", "Genérica BLE", ...).
  final String nombre;

  /// Expresión regular con GRUPOS NOMBRADOS. Los reconocidos son:
  ///
  /// - `peso`   (obligatorio) el número.
  /// - `signo`  opcional, `+` o `-`.
  /// - `unidad` opcional, `kg` o `g`. Si viene, MANDA sobre [unidadPorDefecto]:
  ///            hay balanzas que cambian de unidad con un botón del equipo y la
  ///            trama es la única que se entera.
  /// - `estado` opcional, lo que se compara contra [tokensEstable].
  ///
  /// Se eligió una regex y no una lista de campos posicionales porque las
  /// tramas reales varían en separadores, relleno y orden; con posiciones fijas
  /// cada marca nueva pedía código nuevo.
  final String patron;

  /// Unidad que se asume cuando la trama no la declara.
  final UnidadPeso unidadPorDefecto;

  /// Valores del grupo `estado` que significan "peso asentado".
  final List<String> tokensEstable;

  /// Si es `false`, toda lectura se considera estable.
  ///
  /// Para equipos que no reportan estabilidad. Es preferible a inventar un
  /// token que nunca va a llegar, que dejaría el botón de "Usar peso"
  /// deshabilitado para siempre y la caja trabada.
  final bool exigeEstable;

  /// Con qué termina cada trama. Se usa para cortar el stream de bytes en
  /// líneas completas ([AcumuladorTramas]).
  final String terminador;

  /// Qué mandarle al equipo para que responda con el peso.
  ///
  /// Vacío = transmite solo, en continuo (lo más común). Hay balanzas que se
  /// quedan mudas hasta que se les pide: eso cambia CUÁNDO se escribe, no cómo
  /// se lee, así que vive acá y no en el transporte.
  final String comandoPedirPeso;

  /// Comando de tara. Vacío = el equipo no la acepta por Bluetooth y hay que
  /// usar el botón físico.
  final String comandoTara;

  const PerfilTrama({
    required this.nombre,
    required this.patron,
    this.unidadPorDefecto = UnidadPeso.kg,
    this.tokensEstable = const ['ST'],
    this.exigeEstable = true,
    this.terminador = '\r\n',
    this.comandoPedirPeso = '',
    this.comandoTara = '',
  });

  PerfilTrama copyWith({
    String? nombre,
    String? patron,
    UnidadPeso? unidadPorDefecto,
    List<String>? tokensEstable,
    bool? exigeEstable,
    String? terminador,
    String? comandoPedirPeso,
    String? comandoTara,
  }) {
    return PerfilTrama(
      nombre: nombre ?? this.nombre,
      patron: patron ?? this.patron,
      unidadPorDefecto: unidadPorDefecto ?? this.unidadPorDefecto,
      tokensEstable: tokensEstable ?? this.tokensEstable,
      exigeEstable: exigeEstable ?? this.exigeEstable,
      terminador: terminador ?? this.terminador,
      comandoPedirPeso: comandoPedirPeso ?? this.comandoPedirPeso,
      comandoTara: comandoTara ?? this.comandoTara,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'patron': patron,
        'unidadPorDefecto': unidadPorDefecto.name,
        'tokensEstable': tokensEstable,
        'exigeEstable': exigeEstable,
        // Los terminadores y comandos viajan ESCAPADOS: un \r\n crudo adentro
        // de un JSON que además se muestra en un campo de texto es invisible y
        // se pierde al editar.
        'terminador': escapar(terminador),
        'comandoPedirPeso': escapar(comandoPedirPeso),
        'comandoTara': escapar(comandoTara),
      };

  factory PerfilTrama.fromJson(Map<String, dynamic> json) {
    return PerfilTrama(
      nombre: json['nombre'] as String? ?? 'Personalizado',
      patron: json['patron'] as String? ?? PerfilesTrama.soloNumero.patron,
      unidadPorDefecto: UnidadPeso.fromString(json['unidadPorDefecto'] as String?),
      tokensEstable:
          (json['tokensEstable'] as List?)?.cast<String>() ?? const ['ST'],
      exigeEstable: json['exigeEstable'] as bool? ?? true,
      terminador: desescapar(json['terminador'] as String? ?? '\\r\\n'),
      comandoPedirPeso: desescapar(json['comandoPedirPeso'] as String? ?? ''),
      comandoTara: desescapar(json['comandoTara'] as String? ?? ''),
    );
  }

  /// `\r\n` → `"\\r\\n"`, para poder verlo y editarlo en un campo de texto.
  static String escapar(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('\r', '\\r').replaceAll('\n', '\\n');

  static String desescapar(String s) =>
      s.replaceAll('\\r', '\r').replaceAll('\\n', '\n').replaceAll('\\\\', '\\');

  @override
  List<Object?> get props => [
        nombre,
        patron,
        unidadPorDefecto,
        tokensEstable,
        exigeEstable,
        terminador,
        comandoPedirPeso,
        comandoTara,
      ];
}

/// Perfiles de arranque. No pretenden cubrir todas las marcas: son el punto de
/// partida para que nadie tenga que escribir una regex desde cero, y se ajustan
/// desde la pantalla de configuración mirando la trama real.
class PerfilesTrama {
  PerfilesTrama._();

  /// `ST,GS,+  1.234kg` — CAS, Toledo y los muchos clones que copian su
  /// protocolo. `GS` es peso bruto y `NT` neto; los dos se aceptan.
  static const casToledo = PerfilTrama(
    nombre: 'CAS / Toledo (ST,GS,+1.234kg)',
    patron:
        r'(?<estado>ST|US)\s*,\s*(?:GS|NT)\s*,\s*(?<signo>[+-])?\s*(?<peso>\d+(?:[.,]\d+)?)\s*(?<unidad>kg|g)?',
    tokensEstable: ['ST'],
  );

  /// `+0001.234kg` — sin flag de estabilidad. Al no haberlo, no se exige:
  /// bloquear el botón contra un dato que nunca llega traba la venta.
  static const signoYUnidad = PerfilTrama(
    nombre: 'Signo + peso + unidad (+0001.234kg)',
    patron: r'(?<signo>[+-])?\s*(?<peso>\d+(?:[.,]\d+)?)\s*(?<unidad>kg|g)',
    exigeEstable: false,
  );

  /// `1.234` pelado. Es el caso de muchos módulos BLE genéricos, que mandan el
  /// número y nada más; ahí la unidad la define la configuración.
  static const soloNumero = PerfilTrama(
    nombre: 'Solo el número (1.234)',
    patron: r'(?<signo>[+-])?\s*(?<peso>\d+(?:[.,]\d+)?)',
    exigeEstable: false,
  );

  static const List<PerfilTrama> todos = [casToledo, signoYUnidad, soloNumero];
}
