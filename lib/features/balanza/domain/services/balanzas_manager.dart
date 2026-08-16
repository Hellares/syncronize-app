import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/balanza_config.dart';

/// Balanzas configuradas en este dispositivo.
///
/// Espeja a `ImpresorasManager` a propósito: es el mismo problema —un periférico
/// físico del mostrador, no de la empresa— y conviene que se administre igual.
///
/// ⚠️ Por ahora persiste SOLO en local. Las impresoras además se respaldan en
/// el backend por `deviceId` (modelo `ImpresoraDispositivo`) para sobrevivir a
/// una reinstalación; para la balanza eso pide un modelo y un endpoint nuevos, y
/// se deja para cuando el formato de la config se haya asentado contra equipos
/// reales. Reconfigurar una balanza es un minuto; migrar dos veces un JSON
/// guardado en el servidor, no.
@lazySingleton
class BalanzasManager {
  static const _key = 'balanzas_bluetooth_v1';
  static final _rand = Random();

  String _generarId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = _rand.nextInt(0x7fffffff).toRadixString(36);
    return 'bal_${ts}_$rand';
  }

  Future<List<BalanzaConfig>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(BalanzaConfig.fromJson).toList();
    } catch (_) {
      // Un JSON corrupto no puede dejar la pantalla inutilizable: se arranca
      // vacío y el usuario vuelve a configurar.
      return const [];
    }
  }

  Future<BalanzaConfig?> getPrincipal() async {
    final all = await listar();
    try {
      return all.firstWhere((b) => b.esPrincipal);
    } catch (_) {
      return all.isEmpty ? null : all.first;
    }
  }

  /// La primera que se crea queda como principal sola: con una sola balanza
  /// configurada, pedir que además la marquen es fricción sin sentido.
  Future<BalanzaConfig> crear(BalanzaConfig nueva) async {
    final all = await listar();
    final creada = BalanzaConfig(
      id: _generarId(),
      nombre: nueva.nombre,
      transporte: nueva.transporte,
      direccion: nueva.direccion,
      perfil: nueva.perfil,
      esPrincipal: nueva.esPrincipal || all.isEmpty,
    );
    final lista = [...all, creada];
    await _guardar(_conUnaSolaPrincipal(lista, creada.id, creada.esPrincipal));
    return creada;
  }

  Future<BalanzaConfig> actualizar(BalanzaConfig actualizada) async {
    final all = await listar();
    final idx = all.indexWhere((b) => b.id == actualizada.id);
    if (idx < 0) throw StateError('Balanza ${actualizada.id} no encontrada');
    final lista = [...all];
    lista[idx] = actualizada;
    await _guardar(
        _conUnaSolaPrincipal(lista, actualizada.id, actualizada.esPrincipal));
    return actualizada;
  }

  Future<void> eliminar(String id) async {
    final all = await listar();
    final eraPrincipal = all.any((b) => b.id == id && b.esPrincipal);
    final quedan = all.where((b) => b.id != id).toList();
    // Si se borró la principal, asciende la primera: quedarse sin ninguna
    // marcada obligaría a elegir en cada venta.
    if (eraPrincipal && quedan.isNotEmpty) {
      quedan[0] = quedan[0].copyWith(esPrincipal: true);
    }
    await _guardar(quedan);
  }

  Future<void> marcarPrincipal(String id) async {
    final all = await listar();
    await _guardar(
        all.map((b) => b.copyWith(esPrincipal: b.id == id)).toList());
  }

  /// Deja una sola marcada como principal. Con dos, `getPrincipal` devolvería
  /// cualquiera y el mostrador vería una balanza distinta según el día.
  List<BalanzaConfig> _conUnaSolaPrincipal(
    List<BalanzaConfig> lista,
    String idGanador,
    bool esPrincipal,
  ) {
    if (!esPrincipal) return lista;
    return lista
        .map((b) => b.copyWith(esPrincipal: b.id == idGanador))
        .toList();
  }

  Future<void> _guardar(List<BalanzaConfig> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(lista.map((b) => b.toJson()).toList()),
    );
  }
}
