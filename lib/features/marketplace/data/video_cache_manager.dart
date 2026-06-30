import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// CacheManager dedicado a los videos de producto del marketplace.
///
/// Separado del cache de imágenes (`cached_network_image`) porque los videos
/// son archivos grandes y queremos topes propios:
/// - [stalePeriod]: a los 14 días se considera viejo y se re-descarga.
/// - [maxNrOfCacheObjects]: tope por CONTEO de archivos (no por bytes); evicta
///   por LRU. Conservador a propósito: los videos comprimidos (1280px) suelen
///   pesar pocos MB, así que ~25 ≈ 100-200MB en disco.
class VideoCacheManager {
  VideoCacheManager._();

  static const _key = 'productVideoCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 25,
    ),
  );
}
