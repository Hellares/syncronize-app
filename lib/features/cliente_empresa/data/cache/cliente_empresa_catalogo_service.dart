import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/cliente_empresa.dart';
import '../datasources/cliente_empresa_remote_datasource.dart';
import '../models/cliente_empresa_model.dart';

/// Catálogo local de clientes empresa B2B con delta-sync — espejo de
/// `ClienteCatalogoService` (personas). Lo consume el tab Empresas del
/// [ClienteUnificadoSelector]: lista instantánea desde cache, deltas
/// (~1 KB) contra `GET /empresas/:id/clientes-empresa/sync`, y push
/// CLIENTE_EMPRESA_CAMBIADO para resincronizar (incluye cambios de
/// contactos: el backend bumpea el padre).
class ClienteEmpresaCatalogoService {
  ClienteEmpresaCatalogoService._();
  static final ClienteEmpresaCatalogoService instance =
      ClienteEmpresaCatalogoService._();

  static const int _schemaVersion = 1;

  ClienteEmpresaRemoteDataSource get _ds =>
      locator<ClienteEmpresaRemoteDataSource>();

  final Map<String, List<ClienteEmpresaModel>> _memoria = {};
  final Map<String, String?> _lastSync = {};
  final Map<String, Future<List<ClienteEmpresa>>> _syncEnCurso = {};

  /// Emite el empresaId cuando el catálogo de esa empresa cambió.
  final _changes = StreamController<String>.broadcast();
  Stream<String> get changes => _changes.stream;

  Directory? _baseDir;

  Future<File> _fileFor(String empresaId) async {
    var dir = _baseDir;
    if (dir == null) {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/cliente_empresa_catalogo_v1');
      if (!await dir.exists()) await dir.create(recursive: true);
      _baseDir = dir;
    }
    final safe = empresaId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/$safe.json');
  }

  /// Lista cacheada (memoria → disco). Solo activos (paridad con el
  /// findAll del selector, que no manda includeInactive).
  Future<List<ClienteEmpresa>> hydrate(String empresaId) async {
    final enMemoria = _memoria[empresaId];
    if (enMemoria != null) return _soloActivas(enMemoria);
    try {
      final f = await _fileFor(empresaId);
      if (!await f.exists()) return const [];
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      if (json['version'] != _schemaVersion) return const [];
      final lista = (json['empresas'] as List)
          .map((e) => ClienteEmpresaModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _memoria[empresaId] = lista;
      _lastSync[empresaId] = json['lastSync'] as String?;
      return _soloActivas(lista);
    } catch (_) {
      return const [];
    }
  }

  /// Sincroniza (delta o full). Coalesce de llamadas concurrentes.
  Future<List<ClienteEmpresa>> syncNow(String empresaId) {
    final enCurso = _syncEnCurso[empresaId];
    if (enCurso != null) return enCurso;
    final future = _doSync(empresaId).whenComplete(() {
      _syncEnCurso.remove(empresaId);
    });
    _syncEnCurso[empresaId] = future;
    return future;
  }

  Future<List<ClienteEmpresa>> _doSync(String empresaId) async {
    final data = await _ds.syncClientesEmpresa(
      empresaId: empresaId,
      lastSync: _lastSync[empresaId],
    );

    final updated = (data['updated'] as List? ?? const [])
        .map((e) => ClienteEmpresaModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final deleted = (data['deleted'] as List? ?? const [])
        .map((e) => e.toString())
        .toSet();
    final fullSync = data['fullSync'] == true;
    final serverTime = data['serverTime']?.toString();

    List<ClienteEmpresaModel> lista;
    if (fullSync) {
      lista = updated;
    } else {
      await hydrate(empresaId);
      final mapa = {
        for (final c in _memoria[empresaId] ?? const <ClienteEmpresaModel>[])
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
        a.razonSocial.toLowerCase().compareTo(b.razonSocial.toLowerCase()));
    _memoria[empresaId] = lista;
    if (serverTime != null && serverTime.isNotEmpty) {
      _lastSync[empresaId] = serverTime;
    }
    await _persist(empresaId);
    if (updated.isNotEmpty || deleted.isNotEmpty || fullSync) {
      _changes.add(empresaId);
    }
    return _soloActivas(lista);
  }

  /// Upsert optimista tras registrar inline desde el selector.
  Future<void> upsertLocal(String empresaId, ClienteEmpresa empresa) async {
    final model = ClienteEmpresaModel.fromEntity(empresa);
    final lista = List<ClienteEmpresaModel>.from(
      _memoria[empresaId] ?? const <ClienteEmpresaModel>[],
    );
    if (lista.isEmpty) await hydrate(empresaId);
    final base = List<ClienteEmpresaModel>.from(
      _memoria[empresaId] ?? const <ClienteEmpresaModel>[],
    );
    final idx = base.indexWhere((c) => c.id == model.id);
    if (idx >= 0) {
      base[idx] = model;
    } else {
      base.add(model);
    }
    base.sort((a, b) =>
        a.razonSocial.toLowerCase().compareTo(b.razonSocial.toLowerCase()));
    _memoria[empresaId] = base;
    await _persist(empresaId);
    _changes.add(empresaId);
  }

  /// Filtro local instantáneo (razón social, nombre comercial, RUC, código).
  List<ClienteEmpresa> buscar(String empresaId, String query) {
    final lista = _soloActivas(
      _memoria[empresaId] ?? const <ClienteEmpresaModel>[],
    );
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return lista;
    return lista
        .where((c) =>
            c.razonSocial.toLowerCase().contains(q) ||
            (c.nombreComercial ?? '').toLowerCase().contains(q) ||
            c.numeroDocumento.contains(q) ||
            c.codigo.toLowerCase().contains(q))
        .toList();
  }

  void invalidate(String empresaId) {
    _memoria.remove(empresaId);
    _lastSync.remove(empresaId);
  }

  List<ClienteEmpresa> _soloActivas(List<ClienteEmpresaModel> lista) =>
      lista.where((c) => c.isActive).toList();

  Future<void> _persist(String empresaId) async {
    try {
      final f = await _fileFor(empresaId);
      await f.writeAsString(jsonEncode({
        'version': _schemaVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'lastSync': _lastSync[empresaId],
        'empresas': (_memoria[empresaId] ?? const <ClienteEmpresaModel>[])
            .map((c) => c.toJson())
            .toList(),
      }));
    } catch (_) {
      // Best-effort: la memoria sigue sirviendo; el próximo arranque
      // hará full sync.
    }
  }
}
