import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/producto_list_item.dart';
import '../models/producto_list_item_model.dart';

/// Snapshot del catálogo persistido en disco. Contiene lo mínimo para
/// que la UI renderice instantáneamente al abrir la app sin esperar a
/// la red — los detalles completos (precios exactos, stock al segundo)
/// llegan en background por la revalidación.
class CatalogoLocalSnapshot {
  /// Versión del schema. Si cambia el shape de ProductoListItem o
  /// agregamos campos críticos, bumpear y los snapshots viejos se
  /// invalidan automáticamente al leer.
  static const int currentVersion = 1;

  final int version;
  final List<ProductoListItem> productos;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final DateTime savedAt;

  const CatalogoLocalSnapshot({
    required this.version,
    required this.productos,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'savedAt': savedAt.toIso8601String(),
        'total': total,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'hasMore': hasMore,
        'productos': productos
            .map((p) => ProductoListItemModel.fromEntity(p).toJson())
            .toList(),
      };

  static CatalogoLocalSnapshot? fromJson(Map<String, dynamic> json) {
    final v = json['version'] as int?;
    if (v != currentVersion) return null; // schema viejo, ignoramos
    try {
      final lista = (json['productos'] as List)
          .map((e) => ProductoListItemModel.fromJson(e as Map<String, dynamic>))
          .cast<ProductoListItem>()
          .toList();
      return CatalogoLocalSnapshot(
        version: v!,
        productos: lista,
        total: json['total'] as int? ?? lista.length,
        currentPage: json['currentPage'] as int? ?? 1,
        totalPages: json['totalPages'] as int? ?? 1,
        hasMore: json['hasMore'] as bool? ?? false,
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      // Snapshot corrupto o con un campo incompatible — ignoramos en
      // vez de crashear. La revalidación traerá data fresca igual.
      return null;
    }
  }
}

/// Persiste el catálogo de productos en disco (Fase 2 del plan).
///
/// Solo se cachea el catálogo **base** (sin filtros activos de search,
/// categoría, etc.) — eso es lo que se ve al abrir Venta Rápida y es
/// la pantalla que el cajero abre 50 veces al día. Las búsquedas
/// específicas usan el cache memoria + biblioteca acumulativa.
///
/// Path: `getApplicationDocumentsDirectory()/producto_catalogo_v1/{empresaId}_{sedeId}.json`
///
/// TTL implícito 24h — más allá ignoramos el cache local y forzamos
/// fetch (datos muy viejos pueden estar fuera de sync con realidad).
@lazySingleton
class ProductoCatalogoLocalStore {
  /// TTL del cache local. 24h: cubre el caso típico del cajero que
  /// abre la app día tras día.
  static const Duration ttl = Duration(hours: 24);

  Directory? _baseDir;

  /// Lazy init del directorio. Hace `mkdir -p` al primer acceso.
  Future<Directory> _ensureBaseDir() async {
    final cached = _baseDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/producto_catalogo_v1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _baseDir = dir;
    return dir;
  }

  String _fileName(String empresaId, String? sedeId) {
    final safeEmpresa = empresaId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final safeSede = (sedeId ?? '_').replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return '${safeEmpresa}_$safeSede.json';
  }

  Future<File> _fileFor(String empresaId, String? sedeId) async {
    final dir = await _ensureBaseDir();
    return File('${dir.path}/${_fileName(empresaId, sedeId)}');
  }

  /// Lee el snapshot persistido para esa combinación. Devuelve null si:
  ///  - el archivo no existe
  ///  - el snapshot está corrupto (JSON inválido o campos faltantes)
  ///  - el snapshot supera el TTL
  ///  - la version del schema no coincide
  Future<CatalogoLocalSnapshot?> read({
    required String empresaId,
    String? sedeId,
  }) async {
    try {
      final file = await _fileFor(empresaId, sedeId);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final snapshot = CatalogoLocalSnapshot.fromJson(json);
      if (snapshot == null) return null;
      final age = DateTime.now().difference(snapshot.savedAt);
      if (age > ttl) {
        // Stale — borramos por las dudas y devolvemos null.
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  /// Guarda el snapshot (sobreescribe el archivo si existía).
  Future<void> write({
    required String empresaId,
    String? sedeId,
    required CatalogoLocalSnapshot snapshot,
  }) async {
    try {
      final file = await _fileFor(empresaId, sedeId);
      await file.writeAsString(jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Silencioso: el cache es optimización, no función crítica.
      // Si falla, la próxima apertura simplemente pega al server.
    }
  }

  /// Invalida el cache de una empresa (todas sus sedes + biblioteca).
  Future<void> clearEmpresa(String empresaId) async {
    try {
      final dir = await _ensureBaseDir();
      final prefix = empresaId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.split('/').last.startsWith('${prefix}_')) {
          await entity.delete();
        }
      }
    } catch (_) {}
    try {
      final libDir = await _ensureLibreriaDir();
      final safe = empresaId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${libDir.path}/$safe.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Biblioteca acumulativa (Fase 2 — productos vistos persistentes)
  //
  // Mientras el snapshot base solo guarda la página 1 del catálogo,
  // la biblioteca acumula CUALQUIER ProductoListItem que pasó por el
  // cubit: paginación, búsquedas server, etc. Garantiza que al reabrir
  // la app, todos los productos que el cajero "tocó" antes vuelven a
  // estar disponibles para el filtro local sin pegar al server.
  //
  // Path: `getApplicationDocumentsDirectory()/producto_libreria_v1/{empresaId}.json`
  // ═══════════════════════════════════════════════════════════════════

  /// Tope de productos en biblioteca para evitar crecimiento sin
  /// control en clientes con catálogos muy grandes. Cuando se supera,
  /// el cubit recorta a este tamaño (más recientes primero).
  static const int librariaMaxProductos = 500;

  Directory? _libreriaDir;

  Future<Directory> _ensureLibreriaDir() async {
    final cached = _libreriaDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/producto_libreria_v1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _libreriaDir = dir;
    return dir;
  }

  Future<File> _libreriaFile(String empresaId) async {
    final dir = await _ensureLibreriaDir();
    final safe = empresaId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/$safe.json');
  }

  /// Lee la biblioteca acumulativa. Si el archivo no existe o está
  /// stale (> TTL), devuelve lista vacía. Misma versión que el snapshot.
  Future<List<ProductoListItem>> readLibreria({
    required String empresaId,
  }) async {
    try {
      final file = await _libreriaFile(empresaId);
      if (!await file.exists()) return const [];
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final v = json['version'] as int?;
      if (v != CatalogoLocalSnapshot.currentVersion) return const [];
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      if (savedAt == null) return const [];
      if (DateTime.now().difference(savedAt) > ttl) {
        try {
          await file.delete();
        } catch (_) {}
        return const [];
      }
      final lista = (json['productos'] as List)
          .map((e) => ProductoListItemModel.fromJson(e as Map<String, dynamic>))
          .cast<ProductoListItem>()
          .toList();
      return lista;
    } catch (_) {
      return const [];
    }
  }

  /// Sobreescribe la biblioteca con la lista actual del cubit. La
  /// lista debe venir ya con el tope aplicado (`librariaMaxProductos`).
  Future<void> writeLibreria({
    required String empresaId,
    required List<ProductoListItem> productos,
  }) async {
    try {
      final file = await _libreriaFile(empresaId);
      final payload = {
        'version': CatalogoLocalSnapshot.currentVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'productos': productos
            .map((p) => ProductoListItemModel.fromEntity(p).toJson())
            .toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }

  /// Borra todo el cache (usado en logout / reset).
  Future<void> clearAll() async {
    try {
      final dir = await _ensureBaseDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) await entity.delete();
        }
      }
    } catch (_) {}
  }
}
