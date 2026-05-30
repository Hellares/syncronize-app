import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/producto_variante.dart';
import '../models/producto_variante_model.dart';

/// Cache en disco de las VARIANTES COMPLETAS (con `archivos`/imágenes) por
/// producto.
///
/// El catálogo base y los deltas FCM viajan livianos (sin imágenes de
/// variante) para no engordar el payload. Las variantes con imágenes se
/// fetchean on-demand al abrir el detalle (`getVariantes`). Este store
/// persiste ese resultado para que las próximas aperturas sean instantáneas
/// y funcionen offline, sin re-fetchear.
///
/// Path: `getApplicationDocumentsDirectory()/variante_imagenes_v1/{empresaId}_{productoId}.json`
///
/// Invalidación:
///  - TTL 24h (igual que el catálogo).
///  - `invalidate(empresaId, productoId)` desde el FCM `IMAGEN_CAMBIADA` /
///    `PRODUCTO_ACTUALIZADO` (lo dispara RealtimeSyncService).
@lazySingleton
class VarianteImagenesLocalStore {
  static const int currentVersion = 1;
  static const Duration ttl = Duration(hours: 24);

  Directory? _baseDir;

  Future<Directory> _ensureBaseDir() async {
    final cached = _baseDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/variante_imagenes_v1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _baseDir = dir;
    return dir;
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<File> _fileFor(String empresaId, String productoId) async {
    final dir = await _ensureBaseDir();
    return File('${dir.path}/${_safe(empresaId)}_${_safe(productoId)}.json');
  }

  /// Lee las variantes cacheadas. Devuelve null si: no existe, está corrupto,
  /// la versión del schema no coincide, o superó el TTL.
  Future<List<ProductoVariante>?> read({
    required String empresaId,
    required String productoId,
  }) async {
    try {
      final file = await _fileFor(empresaId, productoId);
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (json['version'] != currentVersion) return null;
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      if (savedAt == null) return null;
      if (DateTime.now().difference(savedAt) > ttl) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      final lista = (json['variantes'] as List)
          .map((e) =>
              ProductoVarianteModel.fromJson(e as Map<String, dynamic>))
          .cast<ProductoVariante>()
          .toList();
      return lista;
    } catch (_) {
      return null;
    }
  }

  /// Guarda las variantes completas (sobreescribe).
  Future<void> write({
    required String empresaId,
    required String productoId,
    required List<ProductoVariante> variantes,
  }) async {
    try {
      final file = await _fileFor(empresaId, productoId);
      final payload = {
        'version': currentVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'variantes': variantes
            .map((v) => ProductoVarianteModel.fromEntity(v).toJson())
            .toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Silencioso: el cache es optimización, no función crítica.
    }
  }

  /// Borra la entrada de un producto (FCM imagen/producto cambiado).
  Future<void> invalidate({
    required String empresaId,
    required String productoId,
  }) async {
    try {
      final file = await _fileFor(empresaId, productoId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Borra todo (logout / cambio de empresa).
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
