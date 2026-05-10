import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/precio_nivel.dart';
import '../repositories/precio_nivel_repository.dart';

/// Cache compartido de niveles de precio por producto.
///
/// Una sola fuente de verdad para todos los consumidores que necesitan
/// los niveles de un producto (Venta Rápida, Cotización Rápida, sheets,
/// detail pages). Evita re-fetchear los mismos niveles desde cubits
/// distintos.
///
/// Comportamiento:
/// - Cache hit → retorna inmediato.
/// - Cache miss → un único fetch al backend, las llamadas concurrentes
///   se deduplican (esperan al mismo Future en `_inFlight`).
/// - Error de red → cachea `[]` para no reintentar en bucle. El llamador
///   puede invalidar manualmente si quiere reintento.
///
/// Invalidación:
/// - `invalidate(productoId)` tras crear/editar/eliminar un nivel.
/// - `clear()` al cambiar de tenant/sede o logout.
@lazySingleton
class PrecioNivelCacheService {
  final PrecioNivelRepository _repository;

  final Map<String, List<PrecioNivel>> _cache = {};
  final Map<String, Future<List<PrecioNivel>>> _inFlight = {};

  PrecioNivelCacheService(this._repository);

  /// Lookup sincrónico: devuelve la lista cacheada o `null` si nunca
  /// se consultó. No dispara fetch. Útil para inicializar items del
  /// carrito con el valor cached y diferir el fetch al async path.
  List<PrecioNivel>? peek(String productoId) => _cache[productoId];

  /// Obtiene los niveles de un producto. Devuelve lista vacía si no hay
  /// niveles configurados o si la consulta falla.
  Future<List<PrecioNivel>> getNiveles(String productoId) {
    final cached = _cache[productoId];
    if (cached != null) return Future.value(cached);

    final inFlight = _inFlight[productoId];
    if (inFlight != null) return inFlight;

    final future = _fetch(productoId);
    _inFlight[productoId] = future;
    return future;
  }

  Future<List<PrecioNivel>> _fetch(String productoId) async {
    try {
      final result =
          await _repository.getPreciosNivelProducto(productoId: productoId);
      if (result is Success<List<PrecioNivel>>) {
        _cache[productoId] = result.data;
        return result.data;
      }
      _cache[productoId] = const [];
      return const [];
    } finally {
      _inFlight.remove(productoId);
    }
  }

  /// Invalida el cache de un producto. Próxima llamada a `getNiveles`
  /// fuerza fetch al backend.
  void invalidate(String productoId) {
    _cache.remove(productoId);
  }

  /// Limpia todo el cache. Útil al cambiar de tenant/sede o cerrar sesión.
  void clear() {
    _cache.clear();
  }
}
