import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/cliente.dart';
import '../datasources/cliente_remote_datasource.dart';
import '../models/cliente_model.dart';

/// Catálogo local de clientes con delta-sync — espejo del patrón de
/// productos (store en disco + lastSync + push CLIENTE_CAMBIADO).
///
/// La búsqueda del [ClienteUnificadoSelector] pasa a ser local e
/// instantánea: la lista completa vive en memoria/disco y solo viajan
/// deltas (~1 KB) contra `GET /clientes/sync`. Los push CLIENTE_CAMBIADO
/// (incluido el fan-out cuando OTRA empresa edita una Persona compartida)
/// disparan la resincronización.
///
/// Singleton manual (sin codegen de injectable): resuelve el datasource
/// vía locator en el primer uso.
class ClienteCatalogoService {
  ClienteCatalogoService._();
  static final ClienteCatalogoService instance = ClienteCatalogoService._();

  /// Bumpear si cambia el shape persistido — los snapshots viejos se
  /// ignoran y el próximo sync será full.
  static const int _schemaVersion = 1;

  ClienteRemoteDataSource get _ds => locator<ClienteRemoteDataSource>();

  final Map<String, List<ClienteModel>> _memoria = {};
  final Map<String, String?> _lastSync = {};
  final Map<String, Future<List<Cliente>>> _syncEnCurso = {};

  /// Emite el empresaId cada vez que el catálogo de esa empresa cambió
  /// (tras un sync o un upsert local). La UI suscrita se refresca.
  final _changes = StreamController<String>.broadcast();
  Stream<String> get changes => _changes.stream;

  Directory? _baseDir;

  Future<File> _fileFor(String empresaId) async {
    var dir = _baseDir;
    if (dir == null) {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/cliente_catalogo_v1');
      if (!await dir.exists()) await dir.create(recursive: true);
      _baseDir = dir;
    }
    final safe = empresaId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/$safe.json');
  }

  /// Lista cacheada (memoria → disco). Vacía si nunca se sincronizó.
  /// No toca la red — para eso está [syncNow].
  Future<List<Cliente>> hydrate(String empresaId) async {
    final enMemoria = _memoria[empresaId];
    if (enMemoria != null) return enMemoria;
    try {
      final f = await _fileFor(empresaId);
      if (!await f.exists()) return const [];
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      if (json['version'] != _schemaVersion) return const [];
      final lista = (json['clientes'] as List)
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _memoria[empresaId] = lista;
      // El server decide si el lastSync sigue siendo usable (> 7 días →
      // responde full): acá solo lo conservamos tal cual.
      _lastSync[empresaId] = json['lastSync'] as String?;
      return lista;
    } catch (_) {
      // Snapshot corrupto: lo ignoramos, el sync traerá data fresca.
      return const [];
    }
  }

  /// Sincroniza contra el backend (delta o full según lastSync) y
  /// devuelve la lista actualizada. Coalesce: llamadas concurrentes para
  /// la misma empresa comparten el mismo request.
  Future<List<Cliente>> syncNow(String empresaId) {
    final enCurso = _syncEnCurso[empresaId];
    if (enCurso != null) return enCurso;
    final future = _doSync(empresaId).whenComplete(() {
      _syncEnCurso.remove(empresaId);
    });
    _syncEnCurso[empresaId] = future;
    return future;
  }

  Future<List<Cliente>> _doSync(String empresaId) async {
    final data = await _ds.syncClientes(lastSync: _lastSync[empresaId]);

    final updated = (data['updated'] as List? ?? const [])
        .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final deleted = (data['deleted'] as List? ?? const [])
        .map((e) => e.toString())
        .toSet();
    final fullSync = data['fullSync'] == true;
    final serverTime = data['serverTime']?.toString();

    List<ClienteModel> lista;
    if (fullSync) {
      lista = updated;
    } else {
      await hydrate(empresaId); // asegura base en memoria
      final mapa = {
        for (final c in _memoria[empresaId] ?? const <ClienteModel>[])
          c.id: c,
      };
      for (final c in updated) {
        mapa[c.id] = c;
      }
      for (final id in deleted) {
        mapa.remove(id);
      }
      lista = mapa.values.toList();
    }

    lista.sort((a, b) =>
        a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));
    _memoria[empresaId] = lista;
    if (serverTime != null && serverTime.isNotEmpty) {
      _lastSync[empresaId] = serverTime;
    }
    await _persist(empresaId);
    if (updated.isNotEmpty || deleted.isNotEmpty || fullSync) {
      _changes.add(empresaId);
    }
    return lista;
  }

  /// Inserta/actualiza un cliente localmente (optimista: tras registrarlo
  /// inline desde el selector, aparece al instante sin esperar el sync).
  /// El push CLIENTE_CAMBIADO del backend confirmará al resto de devices.
  Future<void> upsertLocal(String empresaId, Cliente cliente) async {
    final model = cliente is ClienteModel
        ? cliente
        : ClienteModel(
            id: cliente.id,
            personaId: cliente.personaId,
            usuarioId: cliente.usuarioId,
            dni: cliente.dni,
            nombres: cliente.nombres,
            apellidos: cliente.apellidos,
            nombreCompleto: cliente.nombreCompleto,
            telefono: cliente.telefono,
            email: cliente.email,
            direccion: cliente.direccion,
            distrito: cliente.distrito,
            provincia: cliente.provincia,
            departamento: cliente.departamento,
            isActive: cliente.isActive,
            estado: cliente.estado,
            emailVerificado: cliente.emailVerificado,
            telefonoVerificado: cliente.telefonoVerificado,
            dniVerificado: cliente.dniVerificado,
            yaExistiaEnSistema: cliente.yaExistiaEnSistema,
            registradoPor: cliente.registradoPor,
            registradoPorNombre: cliente.registradoPorNombre,
            fechaRegistro: cliente.fechaRegistro,
            creadoEn: cliente.creadoEn,
            actualizadoEn: cliente.actualizadoEn,
          );

    final lista = List<ClienteModel>.from(
      _memoria[empresaId] ?? await hydrate(empresaId),
    );
    final idx = lista.indexWhere((c) => c.id == model.id);
    if (idx >= 0) {
      lista[idx] = model;
    } else {
      lista.add(model);
    }
    lista.sort((a, b) =>
        a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));
    _memoria[empresaId] = lista;
    await _persist(empresaId);
    _changes.add(empresaId);
  }

  /// Filtro local instantáneo por nombre, DNI, teléfono o email.
  List<Cliente> buscar(String empresaId, String query) {
    final lista = _memoria[empresaId] ?? const <ClienteModel>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return lista;
    return lista
        .where((c) =>
            c.nombreCompleto.toLowerCase().contains(q) ||
            (c.dni ?? '').contains(q) ||
            (c.telefono ?? '').contains(q) ||
            (c.email ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Limpia el cache de una empresa (logout / switch-tenant).
  void invalidate(String empresaId) {
    _memoria.remove(empresaId);
    _lastSync.remove(empresaId);
  }

  Future<void> _persist(String empresaId) async {
    try {
      final f = await _fileFor(empresaId);
      await f.writeAsString(jsonEncode({
        'version': _schemaVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'lastSync': _lastSync[empresaId],
        'clientes':
            (_memoria[empresaId] ?? const <ClienteModel>[])
                .map((c) => c.toJson())
                .toList(),
      }));
    } catch (_) {
      // Persistencia best-effort: si falla, la memoria sigue sirviendo y
      // el próximo arranque hará full sync.
    }
  }
}
