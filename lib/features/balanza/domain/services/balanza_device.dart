import 'dart:async';
import 'dart:math';

import '../entities/balanza_config.dart';
import '../entities/lectura_peso.dart';
import '../entities/perfil_trama.dart';
import 'trama_balanza_parser.dart';

/// Lo único que el visor sabe de una balanza.
///
/// 🔑 El visor consume [lecturas] y no sabe de Bluetooth. Cambiar de marca, o
/// pasar de SPP a BLE, no lo toca: se escribe otra implementación de esta
/// interfaz. Mismo criterio con el que se aisló ESC/POS de las térmicas.
abstract class BalanzaDevice {
  /// Pesos ya parseados y normalizados a gramos.
  Stream<LecturaPeso> get lecturas;

  /// Las líneas CRUDAS tal como llegan. Solo para el diagnóstico de la pantalla
  /// de configuración: ninguna lógica de venta las mira.
  Stream<String> get crudo;

  bool get conectado;

  Future<void> conectar();
  Future<void> desconectar();

  /// Pone el visor en cero. Vacío si el equipo no acepta tara por Bluetooth y
  /// hay que usar su botón físico.
  Future<void> tara();
}

/// Balanza de mentira, para ver el flujo completo sin equipo.
///
/// 🔑 No emite `LecturaPeso` directo: **genera tramas de texto y las hace pasar
/// por el mismo camino que las reales** —[AcumuladorTramas] y [parsearTrama]—,
/// partiéndolas en dos paquetes de vez en cuando. Así el simulador ejercita la
/// cadena de verdad y no solo la pantalla: si el acumulador se rompe, se nota
/// acá y no recién con la balanza en el mostrador.
///
/// Simula lo que hace una balanza real: el peso oscila unos gramos mientras se
/// asienta (`US`) y recién después se estabiliza (`ST`).
class BalanzaFake implements BalanzaDevice {
  /// Peso final al que converge, en gramos.
  final double objetivoGramos;

  /// Cuánto tarda en asentarse.
  final Duration tiempoAsentado;

  /// Cada cuánto manda una trama. Una balanza de mostrador ronda las 10 por
  /// segundo.
  final Duration intervalo;

  final PerfilTrama _perfil = PerfilesTrama.casToledo;
  final _rand = Random();

  late final AcumuladorTramas _acc =
      AcumuladorTramas(terminador: _perfil.terminador);

  final _lecturas = StreamController<LecturaPeso>.broadcast();
  final _crudo = StreamController<String>.broadcast();

  Timer? _timer;
  DateTime? _desde;
  double _tara = 0;
  bool _conectado = false;

  BalanzaFake({
    this.objetivoGramos = 1237,
    this.tiempoAsentado = const Duration(seconds: 3),
    this.intervalo = const Duration(milliseconds: 120),
  });

  @override
  Stream<LecturaPeso> get lecturas => _lecturas.stream;

  @override
  Stream<String> get crudo => _crudo.stream;

  @override
  bool get conectado => _conectado;

  @override
  Future<void> conectar() async {
    if (_conectado) return;
    _conectado = true;
    _desde = DateTime.now();
    _timer = Timer.periodic(intervalo, (_) => _emitir());
  }

  @override
  Future<void> desconectar() async {
    _conectado = false;
    _timer?.cancel();
    _timer = null;
    _acc.limpiar();
  }

  @override
  Future<void> tara() async {
    // Tara real: el cero pasa a ser el peso que hay ahora sobre el plato.
    _tara = _pesoActual();
    _desde = DateTime.now();
  }

  void _emitir() {
    final estable = _estabilizado;
    final peso = _pesoActual() - _tara;

    // La trama se arma en el formato del perfil y se manda por el mismo camino
    // que la de una balanza real.
    final trama = '${estable ? 'ST' : 'US'},GS,'
        '${peso < 0 ? '-' : '+'}'
        '${(peso.abs() / 1000).toStringAsFixed(3).padLeft(7, ' ')}kg'
        '${_perfil.terminador}';

    // Una de cada cinco veces llega partida al medio, que es lo que pasa de
    // verdad con el Bluetooth.
    final paquetes = _rand.nextInt(5) == 0
        ? [trama.substring(0, trama.length ~/ 2), trama.substring(trama.length ~/ 2)]
        : [trama];

    for (final p in paquetes) {
      for (final linea in _acc.agregar(p)) {
        _crudo.add(linea);
        final lectura = parsearTrama(linea, _perfil);
        if (lectura != null) _lecturas.add(lectura);
      }
    }
  }

  bool get _estabilizado {
    final desde = _desde;
    if (desde == null) return false;
    return DateTime.now().difference(desde) >= tiempoAsentado;
  }

  /// Mientras se asienta oscila; después queda clavado.
  double _pesoActual() {
    if (_estabilizado) return objetivoGramos;
    final ruido = (_rand.nextDouble() - 0.5) * 40; // ±20 g
    return (objetivoGramos + ruido).clamp(0, double.infinity);
  }

  void dispose() {
    desconectar();
    _lecturas.close();
    _crudo.close();
  }
}

/// Devuelve el dispositivo con el que hablarle a una balanza configurada, o
/// `null` si ese transporte todavía no está implementado.
///
/// 🔴 Devolver null en vez de un fake es deliberado: un peso inventado que
/// entra a una venta como si fuera real es exactamente el error que no se
/// puede permitir. El simulador solo aparece si el usuario lo eligió como
/// transporte.
BalanzaDevice? crearDevice(BalanzaConfig config) {
  if (config.transporte.esSimulador) {
    // 🔴 Segunda llave, y la que importa: acá es donde el peso falso ENTRARÍA
    // al sistema. Que el selector no lo ofrezca (primera llave) no alcanza —
    // una config guardada con un build viejo, restaurada de un respaldo, o
    // escrita a mano en las preferencias, llegaría igual hasta este punto.
    if (!config.transporte.disponibleEnEsteBuild) return null;
    return BalanzaFake();
  }
  // clasico → flutter_blue_classic · ble → flutter_bluetooth_serial_ble.
  // Se implementan cuando haya equipo contra el cual probarlos.
  return null;
}
