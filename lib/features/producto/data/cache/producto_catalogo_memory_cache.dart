import 'package:injectable/injectable.dart';

import '../../domain/entities/producto_filtros.dart';
import '../../domain/entities/producto_list_item.dart';
import '../../domain/entities/producto.dart';

/// Snapshot de una respuesta de catálogo guardado en memoria.
class CatalogoCacheEntry {
  final List<ProductoListItem> productos;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final ProductoFiltros filtros;
  final Map<String, Producto> productosFullCache;
  final DateTime timestamp;

  const CatalogoCacheEntry({
    required this.productos,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.filtros,
    required this.productosFullCache,
    required this.timestamp,
  });

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(timestamp) <= ttl;
  }
}

/// Cache en memoria del catálogo de productos.
///
/// Es la **Fase 1** del plan de acelerar VR (ver
/// `memory/project_catalogo_carga_rapida.md`). Render instantáneo desde
/// memoria mientras corre el revalidate en background. Sin persistencia
/// — se pierde al cerrar la app (eso lo cubre Fase 2 con Hive).
///
/// Key del cache: `empresaId:sedeId:filtros.hashCode`. Permite que
/// distintas combinaciones (catálogo base, catálogo con filtro
/// categoría, búsqueda específica) tengan entradas separadas y no se
/// pisen entre sí.
///
/// Invalidación: el `RealtimeSyncService` debería llamar `invalidateAll`
/// cuando un FCM avisa de cambios de precio/stock/catálogo. Si no se
/// invalida, el TTL (5 min) actúa como fallback.
@lazySingleton
class ProductoCatalogoMemoryCache {
  /// TTL del cache. 5 min cubre la sesión típica del cajero entre
  /// cambios de pantalla. Para sesiones más largas, FCM se encarga de
  /// invalidar antes.
  static const Duration ttl = Duration(minutes: 5);

  final Map<String, CatalogoCacheEntry> _cache = {};

  String _key(String empresaId, String? sedeId, ProductoFiltros filtros) {
    return '$empresaId:${sedeId ?? "_"}:${filtros.hashCode}';
  }

  /// Devuelve la entrada cacheada si existe y está dentro del TTL.
  CatalogoCacheEntry? get(
    String empresaId,
    String? sedeId,
    ProductoFiltros filtros,
  ) {
    final entry = _cache[_key(empresaId, sedeId, filtros)];
    if (entry == null) return null;
    if (!entry.isFresh(ttl)) {
      // Limpiamos el slot stale para no acumular memoria.
      _cache.remove(_key(empresaId, sedeId, filtros));
      return null;
    }
    return entry;
  }

  /// Guarda/actualiza la entrada para esa combinación de filtros.
  void put(
    String empresaId,
    String? sedeId,
    ProductoFiltros filtros,
    CatalogoCacheEntry entry,
  ) {
    _cache[_key(empresaId, sedeId, filtros)] = entry;
  }

  /// Invalida todas las entradas (llamar cuando llega FCM de cambios).
  void invalidateAll() {
    _cache.clear();
  }

  /// Invalida solo las entradas de una empresa (cuando el cambio se
  /// confirma scoped a la empresa actual).
  void invalidateEmpresa(String empresaId) {
    _cache.removeWhere((k, _) => k.startsWith('$empresaId:'));
  }
}
