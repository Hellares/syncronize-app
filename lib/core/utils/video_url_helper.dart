/// Helper para detectar y manejar diferentes tipos de URLs de video
class VideoUrlHelper {
  /// Enum para los tipos de video soportados
  static const String youtube = 'youtube';
  static const String facebook = 'facebook';
  static const String vimeo = 'vimeo';
  static const String instagram = 'instagram';
  static const String tiktok = 'tiktok';
  static const String direct = 'direct'; // MP4, MOV, etc.

  /// Detecta el tipo de video basado en la URL
  static String detectVideoType(String url) {
    final uri = Uri.parse(url.toLowerCase());
    final host = uri.host;

    // YouTube
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return youtube;
    }

    // Facebook
    if (host.contains('facebook.com') || host.contains('fb.watch') || host.contains('fb.com')) {
      return facebook;
    }

    // Vimeo
    if (host.contains('vimeo.com')) {
      return vimeo;
    }

    // Instagram
    if (host.contains('instagram.com')) {
      return instagram;
    }

    // TikTok
    if (host.contains('tiktok.com')) {
      return tiktok;
    }

    // Video directo (MP4, MOV, etc.)
    final path = uri.path.toLowerCase();
    if (path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm') ||
        path.endsWith('.m3u8')) {
      return direct;
    }

    // Por defecto, asumir que es un video directo
    return direct;
  }

  /// Extrae el ID de video de YouTube de diferentes formatos de URL
  /// Soporta:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://www.youtube.com/v/VIDEO_ID
  static String? extractYoutubeId(String url) {
    try {
      final uri = Uri.parse(url);

      // youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      // youtube.com/watch?v=VIDEO_ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }

      // youtube.com/embed/VIDEO_ID o youtube.com/v/VIDEO_ID
      if (uri.pathSegments.length >= 2) {
        if (uri.pathSegments[0] == 'embed' || uri.pathSegments[0] == 'v') {
          return uri.pathSegments[1];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convierte una URL de Facebook a formato embed
  static String getFacebookEmbedUrl(String url) {
    // Facebook requiere un iframe embed URL
    final encodedUrl = Uri.encodeComponent(url);
    return 'https://www.facebook.com/plugins/video.php?href=$encodedUrl&show_text=false&appId';
  }

  /// Convierte una URL de Vimeo a formato embed
  static String getVimeoEmbedUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      final videoId = uri.pathSegments.last;
      return 'https://player.vimeo.com/video/$videoId';
    }
    return url;
  }

  /// Obtiene la URL apropiada para WebView según el tipo
  static String getWebViewUrl(String url, String type) {
    switch (type) {
      case facebook:
        return getFacebookEmbedUrl(url);
      case vimeo:
        return getVimeoEmbedUrl(url);
      case instagram:
      case tiktok:
      default:
        return url;
    }
  }
}
