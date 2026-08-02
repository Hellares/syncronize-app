import 'package:latlong2/latlong.dart';

/// Qué se pudo sacar de un texto compartido desde otra app.
enum TipoUbicacionCompartida {
  /// Se extrajeron coordenadas: usable de inmediato en el picker.
  coordenadas,

  /// Enlace acortado (`maps.app.goo.gl`, `goo.gl/maps`). Las coordenadas
  /// recién aparecen al seguir la redirección, y eso se resuelve en el
  /// BACKEND — no acá.
  enlaceAcortado,
}

/// Resultado de interpretar un texto compartido.
class UbicacionCompartida {
  final TipoUbicacionCompartida tipo;

  /// Solo cuando [tipo] es [TipoUbicacionCompartida.coordenadas].
  final LatLng? punto;

  /// Solo cuando [tipo] es [TipoUbicacionCompartida.enlaceAcortado].
  final String? urlAcortada;

  const UbicacionCompartida.coordenadas(LatLng this.punto)
    : tipo = TipoUbicacionCompartida.coordenadas,
      urlAcortada = null;

  const UbicacionCompartida.enlaceAcortado(String this.urlAcortada)
    : tipo = TipoUbicacionCompartida.enlaceAcortado,
      punto = null;
}

/// Interpreta el texto que otra app compartió con Syncronize (típicamente
/// WhatsApp → Compartir) y saca de ahí la ubicación.
///
/// WhatsApp comparte la ubicación como un enlace de Google Maps, a veces
/// precedido de texto suelto, y a veces **acortado** — por eso el resultado
/// distingue entre coordenadas listas y un enlace que hay que resolver.
class UbicacionCompartidaParser {
  const UbicacionCompartidaParser._();

  /// Devuelve `null` si el texto no contiene nada reconocible como ubicación.
  static UbicacionCompartida? parse(String? texto) {
    if (texto == null) return null;
    final crudo = texto.trim();
    if (crudo.isEmpty) return null;

    final geo = _rePrimerGeo.firstMatch(crudo)?.group(0);
    if (geo != null) {
      final punto = _desdeGeo(geo);
      if (punto != null) return UbicacionCompartida.coordenadas(punto);
    }

    final url = _rePrimerUrl.firstMatch(crudo)?.group(0);
    if (url != null) {
      // Los signos de puntuación finales de una frase no son parte del enlace.
      final limpia = url.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');

      if (_esAcortada(limpia)) {
        return UbicacionCompartida.enlaceAcortado(limpia);
      }
      final punto = _desdeUrlMaps(limpia);
      if (punto != null) return UbicacionCompartida.coordenadas(punto);
    }

    // Último recurso: el texto es un par "lat,lon" pelado.
    final suelto = _parDeCoordenadas(crudo);
    if (suelto != null) return UbicacionCompartida.coordenadas(suelto);

    return null;
  }

  // ── geo: ────────────────────────────────────────────────────────────────

  /// `geo:-6.77,-79.84`, `geo:-6.77,-79.84?z=17`, `geo:0,0?q=-6.77,-79.84(Casa)`.
  ///
  /// El `0,0` del tercer formato es un relleno del estándar, no una
  /// coordenada real; por eso se mira primero el parámetro `q`.
  static LatLng? _desdeGeo(String geo) {
    try {
      final uri = Uri.parse(geo);
      final desdeQ = _parDeCoordenadas(uri.queryParameters['q']);
      if (desdeQ != null) return desdeQ;
      return _parDeCoordenadas(Uri.decodeComponent(uri.path));
    } on FormatException {
      return _parDeCoordenadas(geo.substring('geo:'.length));
    }
  }

  // ── Google Maps ─────────────────────────────────────────────────────────

  static bool _esAcortada(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host == 'maps.app.goo.gl') return true;
    // `goo.gl` genérico solo cuenta si la ruta es de Maps.
    return host == 'goo.gl' &&
        (Uri.tryParse(url)?.path.startsWith('/maps') ?? false);
  }

  /// Orden de preferencia: primero los parámetros que nombran el **destino**,
  /// después el marcador del lugar (`!3d`/`!4d`), y al final el `@` — que es
  /// solo el centro de la cámara y puede estar corrido del punto real.
  static LatLng? _desdeUrlMaps(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    for (final clave in const [
      'q',
      'query',
      'll',
      'destination',
      'daddr',
      'center',
      'sll',
    ]) {
      final punto = _parDeCoordenadas(uri.queryParameters[clave]);
      if (punto != null) return punto;
    }

    final entero = Uri.decodeComponent(url);

    final marcador = _reMarcador.firstMatch(entero);
    if (marcador != null) {
      final punto = _construir(marcador.group(1)!, marcador.group(2)!);
      if (punto != null) return punto;
    }

    final camara = _reCamara.firstMatch(entero);
    if (camara != null) {
      return _construir(camara.group(1)!, camara.group(2)!);
    }

    return null;
  }

  // ── Coordenadas ─────────────────────────────────────────────────────────

  static LatLng? _parDeCoordenadas(String? crudo) {
    if (crudo == null || crudo.isEmpty) return null;
    final m = _reParCoord.firstMatch(crudo);
    if (m == null) return null;
    return _construir(m.group(1)!, m.group(2)!);
  }

  static LatLng? _construir(String lat, String lon) {
    final la = double.tryParse(lat);
    final lo = double.tryParse(lon);
    if (la == null || lo == null) return null;
    if (la.abs() > 90 || lo.abs() > 180) return null;
    // 0,0 es el relleno de `geo:` y cae en el Atlántico: nunca es un delivery.
    if (la == 0 && lo == 0) return null;
    return LatLng(la, lo);
  }

  static final RegExp _rePrimerGeo = RegExp(r'geo:[^\s]+');
  static final RegExp _rePrimerUrl = RegExp(r'https?://[^\s]+');

  /// Exige decimales en ambos lados: sin eso `17,5` de un `,17z` o de un
  /// texto cualquiera pasaría por coordenada.
  static final RegExp _reParCoord = RegExp(
    r'(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)',
  );

  /// `!3d<lat>!4d<lon>` dentro del `data=` de una URL de lugar.
  static final RegExp _reMarcador = RegExp(
    r'!3d(-?\d{1,3}\.\d+)!4d(-?\d{1,3}\.\d+)',
  );

  /// `/@<lat>,<lon>,17z`
  static final RegExp _reCamara = RegExp(
    r'@(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)',
  );
}
