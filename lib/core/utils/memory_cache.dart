/// Cache en memoria sencillo, con expiración por TTL y clave string.
///
/// Pensado para datos que **rara vez cambian** dentro de la sesión
/// (catálogos de empresa: categorías, marcas, sedes, unidades de
/// medida, etc). Vive mientras el repositorio que lo aloja vive — los
/// repositorios del proyecto son `@LazySingleton`, así que el cache
/// sobrevive entre pantallas pero NO entre cierres de app.
///
/// El TTL actúa de salvaguardia para el caso "otro device modificó
/// algo y no recibí FCM". Si el usuario crea/edita/elimina desde la
/// misma app, el repositorio invoca `invalidate(empresaId)` tras la
/// operación para que la próxima lectura vaya fresca al server.
///
/// Uso típico:
/// ```dart
/// final _cache = MemoryCache<List<EmpresaCategoria>>();
///
/// Future<List<EmpresaCategoria>> getCategorias(String empresaId) async {
///   final cached = _cache.get(empresaId);
///   if (cached != null) return cached;
///   final fresh = await _remote.fetch(empresaId);
///   _cache.put(empresaId, fresh);
///   return fresh;
/// }
///
/// // Tras un create/update/delete exitoso:
/// _cache.invalidate(empresaId);
/// ```
class MemoryCache<T> {
  /// Tiempo de vida de cada entrada. Default 30 min — suficiente para
  /// la sesión típica del cajero entre cambios administrativos.
  final Duration ttl;

  final Map<String, _Entry<T>> _store = {};

  MemoryCache({this.ttl = const Duration(minutes: 30)});

  /// Devuelve la entrada cacheada si todavía no expiró. Si expiró, la
  /// borra y devuelve `null` (la próxima lectura traerá data fresca).
  T? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.data;
  }

  /// Almacena `data` bajo `key` con timestamp actual.
  void put(String key, T data) {
    _store[key] = _Entry(data, DateTime.now());
  }

  /// Elimina la entrada para `key`. Llamar tras cualquier mutación
  /// (create/update/delete) sobre la entidad cacheada para esa empresa.
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Vacía el cache entero. Útil en logout / switch de empresa.
  void invalidateAll() {
    _store.clear();
  }
}

class _Entry<T> {
  final T data;
  final DateTime cachedAt;
  const _Entry(this.data, this.cachedAt);
}
