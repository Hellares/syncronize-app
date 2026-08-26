import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Cuáles de las dos están instaladas.
///
/// Solo Android: en iOS no se puede consultar ni elegir paquete, así que se
/// devuelve vacío y el sistema decide (que es lo que ya hacía).
///
/// 🔴 Necesita las dos `<package>` declaradas en `<queries>` del manifest. Sin
/// eso Android 11+ las esconde y esto devuelve vacío aunque estén instaladas
/// — falla silenciosa, se ve como "nunca aparece el selector".
Future<List<AppWhatsapp>> appsWhatsappInstaladas() async {
  if (!Platform.isAndroid) return const [];

  final encontradas = <AppWhatsapp>[];
  for (final app in AppWhatsapp.values) {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: app.paquete,
      );
      if (await intent.canResolveActivity() ?? false) encontradas.add(app);
    } catch (_) {
      // Una app que no se puede consultar se trata como ausente.
    }
  }
  return encontradas;
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
