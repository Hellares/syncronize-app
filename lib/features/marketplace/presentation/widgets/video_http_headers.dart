import '../../../../config/environment/env_config.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/storage.dart';

/// Construye los headers de autenticación para reproducir videos protegidos
/// **servidos por nuestro backend** con `video_player`.
///
/// `VideoPlayerController` hace un GET HTTP plano que NO pasa por el
/// `AuthInterceptor` del Dio, por lo que el backend responde 403 si el video
/// está detrás de auth. Replicamos aquí los mismos headers (Bearer + tenant)
/// que agrega ese interceptor.
///
/// IMPORTANTE: solo se adjuntan si la URL apunta a nuestro backend. Las URLs de
/// storage (Contabo S3, etc.) viven en otro host, son de lectura pública y
/// **rechazan con 400** un header `Authorization` ajeno (lo interpretan como
/// una firma AWS inválida). Para esos casos devolvemos headers vacíos.
Future<Map<String, String>> videoAuthHeaders(String videoUrl) async {
  final headers = <String, String>{};

  if (!_isBackendUrl(videoUrl)) return headers;

  try {
    final accessToken =
        await locator<SecureStorageService>().read(key: StorageConstants.accessToken);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers[ApiConstants.authorization] = 'Bearer $accessToken';
    }

    final tenantId =
        locator<LocalStorageService>().getString(StorageConstants.tenantId);
    if (tenantId != null && tenantId.isNotEmpty) {
      headers[ApiConstants.tenantId] = tenantId;
    }
  } catch (_) {
    // Si falla la lectura de storage, devolvemos lo que haya (o vacío);
    // el reproductor manejará el error de carga.
  }
  return headers;
}

/// True solo si [url] es servida por nuestro backend (mismo host que la API).
bool _isBackendUrl(String url) {
  try {
    final target = Uri.parse(url);
    final api = Uri.parse(EnvConfig.baseUrl);
    return target.host.isNotEmpty && target.host == api.host;
  } catch (_) {
    return false;
  }
}
