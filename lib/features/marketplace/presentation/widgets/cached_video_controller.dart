import 'package:video_player/video_player.dart';

import '../../data/video_cache_manager.dart';
import 'video_http_headers.dart';

/// Crea un [VideoPlayerController] con estrategia **cache-first** (#2):
///
/// - Si el video YA está en disco → reproduce desde el archivo local
///   (`VideoPlayerController.file`): instantáneo, cero red. Esto es lo que da la
///   sensación "Temu" al revisitar.
/// - Si NO está → reproduce por red (arranca rápido gracias al faststart).
///
/// OJO: a propósito **no** dispara la descarga a cache acá. Eso evita el doble
/// fetch (stream + descarga) en cada video que el usuario solo scrollea de paso.
/// El cacheo se hace por INTENCIÓN vía [prefetchVideoToCache] (abrir fullscreen
/// o seguir viendo el mini > unos segundos).
///
/// El controlador devuelto **no** está inicializado: el caller hace `initialize()`.
Future<VideoPlayerController> buildCachedVideoController(String url) async {
  final cached = await VideoCacheManager.instance.getFileFromCache(url);
  if (cached != null) {
    return VideoPlayerController.file(cached.file);
  }

  final headers = await videoAuthHeaders(url);
  return VideoPlayerController.networkUrl(
    Uri.parse(url),
    httpHeaders: headers,
  );
}

/// URLs con descarga a cache en curso, para no lanzar dos descargas del mismo
/// video si llegan varios disparos de intención (timer del mini + fullscreen).
final Set<String> _prefetching = <String>{};

/// Descarga el video a disco para revisitas, **solo cuando hay intención real**
/// (fullscreen abierto, o mini reproducido > unos segundos). Idempotente y
/// fire-and-forget: si ya está cacheado o ya se está bajando, no hace nada.
Future<void> prefetchVideoToCache(String url) async {
  if (_prefetching.contains(url)) return;

  final cached = await VideoCacheManager.instance.getFileFromCache(url);
  if (cached != null) return; // ya está en disco

  _prefetching.add(url);
  try {
    final headers = await videoAuthHeaders(url);
    await VideoCacheManager.instance
        .downloadFile(url, authHeaders: headers.isEmpty ? null : headers);
  } catch (_) {
    // Si falla la descarga, simplemente no se cachea; la próxima vista reintenta.
  } finally {
    _prefetching.remove(url);
  }
}
