import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/device_id_service.dart';
import '../../data/datasources/impresoras_remote_datasource.dart';
import '../entities/impresora_config.dart';

/// Resultado del scan: incluye el motivo si no se pudo escanear.
class ScanBluetoothResult {
  final List<BluetoothInfo> devices;
  final String? error;
  const ScanBluetoothResult({this.devices = const [], this.error});

  bool get ok => error == null;
}

/// Gestor de impresoras térmicas configuradas. Persistencia local
/// (SharedPreferences) + respaldo en backend por dispositivo (ANDROID_ID),
/// para que la lista sobreviva a reinstalaciones del app.
@lazySingleton
class ImpresorasManager {
  static const _key = 'impresoras_termicas_v1';
  static final _rand = Random();

  // Persistencia: local (SharedPreferences) + respaldo en backend por
  // dispositivo, para que la config sobreviva a reinstalaciones del app.
  final ImpresorasRemoteDataSource _remote;
  final DeviceIdService _deviceId;
  bool _restoreIntentado = false;

  ImpresorasManager(this._remote, this._deviceId);

  /// Genera un id local sin agregar dependencia uuid.
  /// Suficientemente único para el contexto (lista de impresoras
  /// del usuario, decenas máximo).
  String _generarId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = _rand.nextInt(0x7fffffff).toRadixString(36);
    return 'imp_${ts}_$rand';
  }

  Future<List<ImpresoraConfig>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        return list.map(ImpresoraConfig.fromJson).toList();
      } catch (_) {
        return const [];
      }
    }
    // Local vacío (p. ej. tras reinstalar): intentar restaurar desde el backend
    // una vez por sesión, usando el ID estable del dispositivo.
    if (!_restoreIntentado) {
      return _restaurarDesdeBackend();
    }
    return const [];
  }

  /// Trae la config guardada en el servidor para este dispositivo y la
  /// re-hidrata localmente. Silencioso si no hay sesión/red o no hay nada.
  /// Solo marca el intento como hecho si el fetch tuvo éxito (así, si el primer
  /// listar() ocurre sin sesión, reintenta tras el login).
  Future<List<ImpresoraConfig>> _restaurarDesdeBackend() async {
    try {
      final deviceId = await _deviceId.getDeviceId();
      final maps = await _remote.obtener(deviceId);
      _restoreIntentado = true;
      if (maps.isEmpty) return const [];
      final lista = maps.map(ImpresoraConfig.fromJson).toList();
      await _guardarLocal(lista);
      return lista;
    } catch (_) {
      return const [];
    }
  }

  Future<ImpresoraConfig?> getById(String id) async {
    final all = await listar();
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ImpresoraConfig?> getPrincipal() async {
    final all = await listar();
    try {
      return all.firstWhere((i) => i.esPrincipal);
    } catch (_) {
      return null;
    }
  }

  /// Crea una nueva impresora. Si es la primera de la lista, la marca
  /// como principal automáticamente.
  Future<ImpresoraConfig> crear(ImpresoraConfig nueva) async {
    final all = await listar();
    final esPrimera = all.isEmpty;
    final conId = ImpresoraConfig(
      id: _generarId(),
      nombre: nueva.nombre,
      tipoConexion: nueva.tipoConexion,
      direccion: nueva.direccion,
      anchoPapel: nueva.anchoPapel,
      tamanoFuentePx: nueva.tamanoFuentePx,
      autoImprimirVentaRapida: nueva.autoImprimirVentaRapida,
      esPrincipal: nueva.esPrincipal || esPrimera,
    );
    final actualizadas = [...all, conId];
    // Si la nueva entró como principal, despromover a las demás
    if (conId.esPrincipal) {
      for (var i = 0; i < actualizadas.length - 1; i++) {
        if (actualizadas[i].esPrincipal) {
          actualizadas[i] = actualizadas[i].copyWith(esPrincipal: false);
        }
      }
    }
    await _guardar(actualizadas);
    return conId;
  }

  Future<ImpresoraConfig> actualizar(ImpresoraConfig actualizada) async {
    final all = await listar();
    final idx = all.indexWhere((i) => i.id == actualizada.id);
    if (idx < 0) {
      throw StateError('Impresora ${actualizada.id} no encontrada');
    }
    final nuevaLista = [...all];
    nuevaLista[idx] = actualizada;
    // Si esta pasó a principal, despromover al resto
    if (actualizada.esPrincipal) {
      for (var i = 0; i < nuevaLista.length; i++) {
        if (i != idx && nuevaLista[i].esPrincipal) {
          nuevaLista[i] = nuevaLista[i].copyWith(esPrincipal: false);
        }
      }
    }
    await _guardar(nuevaLista);
    return actualizada;
  }

  Future<void> eliminar(String id) async {
    final all = await listar();
    final filtradas = all.where((i) => i.id != id).toList();
    // Si quitamos la principal y queda al menos una, promover la primera
    final habiaPrincipal = all.any((i) => i.id == id && i.esPrincipal);
    if (habiaPrincipal && filtradas.isNotEmpty) {
      filtradas[0] = filtradas[0].copyWith(esPrincipal: true);
    }
    await _guardar(filtradas);
  }

  /// Marca una impresora como principal y despromueve a las demás.
  Future<void> marcarPrincipal(String id) async {
    final all = await listar();
    final nuevaLista = all
        .map((i) => i.copyWith(esPrincipal: i.id == id))
        .toList();
    await _guardar(nuevaLista);
  }

  Future<void> _guardar(List<ImpresoraConfig> lista) async {
    await _guardarLocal(lista);
    // Respaldo en backend (fire-and-forget): si no hay sesión/red queda local
    // y se reintenta en el próximo guardado.
    unawaited(_pushBackend(lista));
  }

  Future<void> _guardarLocal(List<ImpresoraConfig> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(lista.map((i) => i.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> _pushBackend(List<ImpresoraConfig> lista) async {
    try {
      final deviceId = await _deviceId.getDeviceId();
      await _remote.guardar(deviceId, lista.map((i) => i.toJson()).toList());
    } catch (_) {
      // Silencioso: el respaldo no debe romper el guardado local.
    }
  }

  // ───────────────────────────────────────────────────────────
  //  Operación física
  // ───────────────────────────────────────────────────────────

  /// Garantiza conexión LIMPIA a la impresora indicada. Siempre intenta
  /// desconectar primero para limpiar cualquier socket muerto/stale, y
  /// después conecta fresh.
  ///
  /// Bluetooth Classic solo permite 1 conexión activa por impresora. Si
  /// otro celular se quedó conectado (o nuestro lib piensa que sigue
  /// conectado pero el socket está muerto), `connect()` falla con
  /// "read failed, socket might closed or timeout, read ret: -1".
  /// El disconnect previo libera cualquier estado pegado del lado Android.
  ///
  /// La primera llamada por sesión puede ser ~1s más lenta por este
  /// disconnect "innecesario", pero garantiza robustez al cambiar de
  /// celular o reintentar tras una impresión fallida.
  Future<bool> _asegurarConexion(String mac) async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {
      // No nos importa si falla el disconnect (probablemente no había nada).
    }
    // Pequeña pausa para que Android libere el socket antes de reconectar.
    await Future.delayed(const Duration(milliseconds: 300));
    return PrintBluetoothThermal.connect(macPrinterAddress: mac);
  }

  /// Envía bytes ESC-POS a la impresora principal. Si no hay principal
  /// configurada o falla la conexión, devuelve false sin lanzar.
  Future<bool> imprimirEnPrincipal(List<int> bytes) async {
    final principal = await getPrincipal();
    if (principal == null) return false;
    if (principal.tipoConexion != TipoConexionImpresora.bluetooth) {
      // V1 solo Bluetooth. Ethernet TODO.
      return false;
    }
    final conectada = await _asegurarConexion(principal.direccion);
    if (!conectada) return false;
    // IMPORTANTE: pasar List<int> plano, NO Uint8List. La lib
    // print_bluetooth_thermal hace _channel.invokeMethod('writebytes', bytes)
    // y el plugin Kotlin espera List<Integer>. Si mandamos Uint8List, Android
    // lo serializa como byte[] y crashea con "byte[] cannot be cast to java.util.List".
    return PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Envía bytes a una impresora específica (para botón "Imprimir prueba").
  Future<bool> imprimirEn(ImpresoraConfig config, List<int> bytes) async {
    if (config.tipoConexion != TipoConexionImpresora.bluetooth) return false;
    final conectada = await _asegurarConexion(config.direccion);
    if (!conectada) return false;
    return PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Solicita los permisos de Bluetooth (nearby devices en Android 12+).
  /// Devuelve true si están concedidos.
  Future<bool> _asegurarPermisosBluetooth() async {
    if (!Platform.isAndroid) return true;

    // Android 12+ separa BLUETOOTH_CONNECT y BLUETOOTH_SCAN.
    // permission_handler los mapea automáticamente; en Android < 12
    // estas permisiones son no-op (devuelven granted).
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    return connect.isGranted && scan.isGranted;
  }

  /// Lista dispositivos Bluetooth ya emparejados con el celular.
  /// Maneja permisos runtime y aplica timeout para no colgar la UI.
  Future<ScanBluetoothResult> scanBluetooth({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final permisos = await _asegurarPermisosBluetooth();
    if (!permisos) {
      return const ScanBluetoothResult(
        error:
            'Necesito permiso de Bluetooth (Dispositivos cercanos). Actívalo en Ajustes → Apps → Syncronize.',
      );
    }

    final on = await PrintBluetoothThermal.bluetoothEnabled;
    if (!on) {
      return const ScanBluetoothResult(
        error: 'Bluetooth desactivado. Activalo desde la barra de notificaciones.',
      );
    }

    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths.timeout(
        timeout,
        onTimeout: () => <BluetoothInfo>[],
      );
      if (devices.isEmpty) {
        return const ScanBluetoothResult(
          error:
              'No hay impresoras emparejadas. Emparejalas primero desde los ajustes Bluetooth del celular.',
        );
      }
      return ScanBluetoothResult(devices: devices);
    } catch (e) {
      return ScanBluetoothResult(error: 'No se pudieron listar dispositivos: $e');
    }
  }

  Future<bool> bluetoothEnabled() => PrintBluetoothThermal.bluetoothEnabled;
}
