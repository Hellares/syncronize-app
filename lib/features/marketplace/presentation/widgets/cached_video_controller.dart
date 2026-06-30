import 'package:video_player/video_player.dart';

import '../../data/video_cache_manager.dart';
import 'video_http_headers.dart';

/// Crea un [VideoPlayerController] con estrategia **cache-first híbrida** (#2):
///
/// - Si el video YA está en disco → reproduce desde el archivo local
///   (`VideoPlayerController.file`): instantáneo, cero red. Esto es lo que da la
///   sensación "Temu" al revisitar.
/// - Si NO está → reproduce por red (arranca rápido gracias al faststart) y en
///   paralelo dispara la descarga a disco para la próxima vez (fire-and-forget).
///
/// El cache key es la URL completa (incluye el `?v=` que el backend agrega al
/// optimizar el video), así que una URL versionada = entrada de cache nueva y la
/// vieja queda huérfana (se evicta por LRU). Reusa [videoAuthHeaders]: para
/// videos servidos por el backend adjunta Bearer+tenant; para storage público
/// devuelve vacío.
///
/// El controlador devuelto **no** está inicializado: el caller hace `initialize()`
/// como ya lo hacía con `networkUrl`.
Future<VideoPlayerController> buildCachedVideoController(String url) async {
  final cached = await VideoCacheManager.instance.getFileFromCache(url);
  if (cached != null) {
    return VideoPlayerController.file(cached.file);
  }

  final headers = await videoAuthHeaders(url);

  // Descarga a cache en background; no bloquea el arranque por red.
  VideoCacheManager.instance
      .downloadFile(url, authHeaders: headers.isEmpty ? null : headers)
      .then((_) {}, onError: (_) {/* si falla, simplemente no se cachea */});

  return VideoPlayerController.networkUrl(
    Uri.parse(url),
    httpHeaders: headers,
  );
}
