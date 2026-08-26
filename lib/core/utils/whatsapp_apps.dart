import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/storage_constants.dart';
import '../di/injection_container.dart';
import '../storage/local_storage_service.dart';

/// Cuál de las dos apps de WhatsApp abrir.
///
/// Un celular con dos chips suele tener las dos instaladas, cada una con su
/// cuenta: la normal para lo personal y Business para el negocio. Mandar el
/// mensaje del negocio por la cuenta personal es un error que el usuario
/// descubre recién cuando el cliente le contesta al número equivocado.
enum AppWhatsapp {
  normal('com.whatsapp', 'WhatsApp'),
  business('com.whatsapp.w4b', 'WhatsApp Business');

  const AppWhatsapp(this.paquete, this.etiqueta);

  final String paquete;
  final String etiqueta;
}

/// Cuáles de las dos pueden abrir un enlace `wa.me`.
///
/// Solo Android: en iOS no se puede consultar ni elegir paquete, así que se
/// devuelve vacío y el sistema decide (que es lo que ya hacía).
///
/// 🔴 Se pregunta por el intent VIEW con el enlace, NO por MAIN/LAUNCHER.
/// `canResolveActivity` del plugin resuelve con `MATCH_DEFAULT_ONLY`, que
/// exige `CATEGORY_DEFAULT`, y una actividad LAUNCHER no la declara —declara
/// MAIN + LAUNCHER—. Preguntando por el launcher, las DOS daban false aunque
/// estuvieran instaladas y el selector no aparecía nunca. La actividad que
/// abre enlaces sí declara DEFAULT, que es justo la que nos interesa: la
/// pregunta correcta no es "¿está instalada?" sino "¿puede abrir esto?".
///
/// 🔴 Y necesita las dos `<package>` declaradas en `<queries>` del manifest:
/// sin eso Android 11+ las esconde y esto vuelve a devolver vacío.
Future<List<AppWhatsapp>> appsWhatsappInstaladas({String? url}) async {
  if (!Platform.isAndroid) return const [];

  // Un enlace cualquiera de wa.me alcanza: lo que se compara es el filtro de
  // intents (esquema y host), no el número.
  final prueba = url ?? 'https://wa.me/51999999999';

  final encontradas = <AppWhatsapp>[];
  for (final app in AppWhatsapp.values) {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: prueba,
        package: app.paquete,
      );
      if (await intent.canResolveActivity() ?? false) encontradas.add(app);
    } catch (_) {
      // Una app que no se puede consultar se trata como ausente.
    }
  }
  return encontradas;
}

/// La app con la que se escribió la última vez, si sigue disponible.
///
/// Se recuerda en vez de pedir una configuración: el usuario elige una vez y
/// la próxima ya viene marcada. Si la guardada ya no está instalada —o nunca
/// se eligió— manda la primera de la lista.
AppWhatsapp appWhatsappPreferida(List<AppWhatsapp> disponibles) {
  if (disponibles.isEmpty) return AppWhatsapp.normal;
  try {
    final guardada = locator<LocalStorageService>()
        .getString(StorageConstants.appWhatsappPreferida);
    final match =
        disponibles.where((a) => a.paquete == guardada).firstOrNull;
    if (match != null) return match;
  } catch (_) {
    // Sin storage disponible, se sigue con el default.
  }
  return disponibles.first;
}

/// Recuerda la elección para la próxima vez. Best-effort: que no se guarde no
/// puede impedir que el mensaje salga.
Future<void> recordarAppWhatsapp(AppWhatsapp app) async {
  try {
    await locator<LocalStorageService>()
        .setString(StorageConstants.appWhatsappPreferida, app.paquete);
  } catch (_) {}
}

/// Abre el chat con el texto prellenado.
///
/// Con [app] va por PACKAGE, que es la única forma de elegir cuál de las dos
/// abre: el enlace `wa.me` y el esquema `whatsapp://` los reclaman las dos, y
/// Android resuelve por su cuenta (o con el diálogo del sistema, o con la que
/// quedó por defecto, que es justo lo que hay que poder saltear).
///
/// Sin [app] —o si el intent falla— cae al enlace de siempre.
Future<bool> abrirChatWhatsapp({
  required String numero,
  required String texto,
  AppWhatsapp? app,
}) async {
  final url = 'https://wa.me/$numero?text=${Uri.encodeComponent(texto)}';

  if (app != null && Platform.isAndroid) {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
        package: app.paquete,
      );
      await intent.launch();
      return true;
    } catch (_) {
      // Se desinstaló entre el chequeo y el toque, o el intent no resolvió:
      // mejor abrir el chat por el camino común que no abrir nada.
    }
  }

  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
