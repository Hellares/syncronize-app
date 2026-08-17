import 'dart:convert';

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';

/// Un conteo de efectivo a medio hacer.
///
/// Guarda las dos mitades porque el cajero puede llegar al monto por dos
/// caminos distintos: contando billete por billete en el sheet de desglose,
/// o tecleando el total a mano en "Conteo Físico". Perder cualquiera de las
/// dos lo obliga a contar todo de nuevo.
class ConteoBorrador {
  /// Desglose por denominación (200 → 3, 0.50 → 12, …).
  final Map<double, int> cantidades;

  /// Monto que quedó escrito en el campo "Conteo Físico" del efectivo.
  final double? conteoEfectivo;

  final DateTime guardadoEn;

  const ConteoBorrador({
    required this.cantidades,
    required this.conteoEfectivo,
    required this.guardadoEn,
  });

  bool get estaVacio => cantidades.isEmpty && conteoEfectivo == null;

  /// "recién" / "hace 4 min" / "hace 2 h". El cajero tiene que saber DE CUÁNDO
  /// son los números que le aparecieron en pantalla: si los aplica creyendo
  /// que son los que acaba de contar, la caja cuadra mal y nadie se entera.
  String get antiguedadLegible {
    final d = DateTime.now().difference(guardadoEn);
    if (d.inMinutes < 1) return 'recién';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} d';
  }

  Map<String, dynamic> toJson() => {
        // Claves con 2 decimales fijos: si no, 0.5 y 0.50 se releen como dos
        // denominaciones distintas y el total sale duplicado.
        'cantidades':
            cantidades.map((k, v) => MapEntry(k.toStringAsFixed(2), v)),
        'conteoEfectivo': conteoEfectivo,
        'guardadoEn': guardadoEn.toIso8601String(),
      };

  factory ConteoBorrador.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(
        (json['cantidades'] as Map?) ?? const <String, dynamic>{});
    return ConteoBorrador(
      cantidades: raw.map(
        (k, v) => MapEntry(double.parse(k), (v as num).toInt()),
      ),
      conteoEfectivo: (json['conteoEfectivo'] as num?)?.toDouble(),
      guardadoEn: DateTime.parse(json['guardadoEn'] as String),
    );
  }
}

/// `true` si dos desgloses tienen exactamente las mismas denominaciones.
///
/// Lo usan el sheet (para saber si queda algo que descartar) y las páginas
/// (para distinguir un descarte deliberado de una salida que conserva el
/// conteo — las dos vuelven con `null`).
bool mismoDesglose(Map<double, int>? a, Map<double, int>? b) {
  final x = a ?? const <double, int>{};
  final y = b ?? const <double, int>{};
  if (x.length != y.length) return false;
  for (final e in x.entries) {
    if (y[e.key] != e.value) return false;
  }
  return true;
}

/// Conserva el conteo de efectivo en curso en el dispositivo, para que
/// sobreviva a salir de la pantalla, descartar el sheet sin querer o que
/// Android mate la app en segundo plano.
///
/// 🔴 El borrador se BORRA al confirmar (cierre o arqueo) y caduca a las 12 h.
/// Sin eso el arqueo se rompe: se hace VARIAS veces sobre la misma caja, y el
/// segundo arqueo abriría precargado con el conteo del primero — que es peor
/// que no guardar nada, porque son números plausibles y ya no se notan.
class ConteoBorradorStore {
  /// `storage` solo se pasa en los tests; en la app se resuelve del locator.
  const ConteoBorradorStore([this._storageInyectado]);

  final LocalStorageService? _storageInyectado;

  static const _prefix = 'conteo_borrador_v1_';
  static const _ttl = Duration(hours: 12);

  /// Un cierre por caja: alcanza con el id.
  static String scopeCierre(String cajaId) => 'cierre_$cajaId';

  /// Varios arqueos por caja, pero solo uno en curso a la vez.
  static String scopeArqueo(String cajaId) => 'arqueo_$cajaId';

  LocalStorageService get _storage =>
      _storageInyectado ?? locator<LocalStorageService>();

  String _key(String scope) => '$_prefix$scope';

  /// Lectura SÍNCRONA — `LocalStorageService.getString` no es async — así la
  /// página restaura dentro de `initState`, sin async gap ni parpadeo de un
  /// formulario vacío que después se llena solo.
  ///
  /// Devuelve `null` si no hay nada, si caducó o si el JSON no se puede leer.
  ConteoBorrador? leer(String scope) {
    final raw = _storage.getString(_key(scope));
    if (raw == null || raw.isEmpty) return null;
    try {
      final borrador =
          ConteoBorrador.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(borrador.guardadoEn) > _ttl) {
        borrar(scope);
        return null;
      }
      return borrador.estaVacio ? null : borrador;
    } catch (_) {
      // Un borrador ilegible no puede trabar un cierre de caja: se descarta.
      borrar(scope);
      return null;
    }
  }

  /// Guarda el desglose y el total que ese desglose implica, conservando
  /// nada más: el total ES el conteo físico cuando se cuenta por denominación.
  Future<void> guardarDesglose(
    String scope,
    Map<double, int> cantidades,
    double total,
  ) async {
    await _escribir(
      scope,
      ConteoBorrador(
        cantidades: cantidades,
        conteoEfectivo: cantidades.isEmpty ? null : total,
        guardadoEn: DateTime.now(),
      ),
    );
  }

  /// Guarda el monto tecleado a mano conservando el desglose que ya hubiera:
  /// el cajero puede contar los billetes y después corregir el total.
  Future<void> guardarConteoEfectivo(String scope, double? monto) async {
    final previo = leer(scope);
    await _escribir(
      scope,
      ConteoBorrador(
        cantidades: previo?.cantidades ?? const {},
        conteoEfectivo: monto,
        guardadoEn: DateTime.now(),
      ),
    );
  }

  Future<void> borrar(String scope) => _storage.remove(_key(scope));

  Future<void> _escribir(String scope, ConteoBorrador borrador) async {
    // Un borrador vacío se borra en vez de guardarse: si no, al volver a
    // entrar aparecería el aviso de "recuperamos tu conteo" sin nada que
    // recuperar.
    if (borrador.estaVacio) {
      await borrar(scope);
      return;
    }
    await _storage.setString(_key(scope), jsonEncode(borrador.toJson()));
  }
}
