import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../di/injection_container.dart';
import '../utils/telefono_helper.dart';
import '../utils/whatsapp_apps.dart';
import '../widgets/mensaje_whatsapp_dialog.dart';
import '../../features/empresa/data/datasources/empresa_remote_datasource.dart';

/// Escribirle a un cliente por WhatsApp, desde cualquier pantalla.
///
/// Vive acá y no en cada página porque el flujo tiene cuatro pasos y una
/// bifurcación —averiguar si la empresa tiene su línea vinculada, redactar,
/// enviar por el sistema o abrir WhatsApp— y duplicarlo es garantizar que las
/// dos copias se separen.
class WhatsappClienteService {
  const WhatsappClienteService._();

  /// Redacta el mensaje y lo manda por el mejor camino disponible.
  ///
  /// Con la línea de la empresa vinculada sale desde el sistema, con imagen y
  /// todo. Si no —o si el envío falla—, abre WhatsApp con el texto puesto.
  static Future<void> escribirACliente(
    BuildContext context, {
    required String empresaId,
    required String telefono,
    required String textoInicial,
    String? nombreCliente,
    List<AtajoMensaje> atajos = const [],
  }) async {
    final numero = telefonoParaWhatsapp(telefono);
    if (numero == null) return;

    final destinatario = (nombreCliente?.trim().isNotEmpty ?? false)
        ? nombreCliente!.trim()
        : 'el cliente';

    // Se resuelve ANTES de abrir el cuadro porque el cuadro tiene que decir
    // cuál de las dos cosas va a pasar.
    final envio = await _estadoEnvio(empresaId);
    // Sin línea vinculada el mensaje termina en una app del celular, y con dos
    // instaladas hay que preguntar cuál. Con envío directo no se consulta: no
    // se abre ninguna app.
    // Se pregunta con el enlace REAL, el mismo que se va a abrir: así lo que
    // se comprueba es exactamente lo que después va a pasar.
    final apps = envio.conectado
        ? const <AppWhatsapp>[]
        : await appsWhatsappInstaladas(url: 'https://wa.me/$numero');
    if (!context.mounted) return;

    final redactado = await mostrarDialogoMensajeWhatsapp(
      context,
      textoInicial: textoInicial,
      destinatario: destinatario,
      envioDirecto: envio.conectado,
      numeroEmpresa: envio.numero,
      appsDisponibles: apps,
      atajos: atajos,
    );
    if (redactado == null || !context.mounted) return;

    if (envio.conectado &&
        await _enviarPorElSistema(context, empresaId, numero, redactado)) {
      return;
    }

    // 🔴 La imagen NO puede viajar por wa.me: solo prellena texto. Por eso
    // adjuntar solo se ofrece con la línea vinculada; si igual se llegó acá
    // con una imagen, hay que decirlo en vez de mandar el texto solo y que el
    // usuario crea que la foto salió.
    if (!context.mounted) return;
    if (redactado.imagen != null) {
      _avisar(
        context,
        'No se pudo enviar la imagen. Se abre WhatsApp con el texto; '
        'la foto hay que adjuntarla ahí.',
        color: Colors.orange,
        segundos: 5,
      );
    }
    // Se recuerda ANTES de abrir: si el intent falla igual queda anotada la
    // intención, que es lo que el usuario expresó.
    final app = redactado.app;
    if (app != null) await recordarAppWhatsapp(app);

    final abierto = await abrirChatWhatsapp(
      numero: numero,
      texto: redactado.texto,
      app: app,
    );
    if (!abierto && context.mounted) {
      _avisar(context, 'No se pudo abrir WhatsApp', color: Colors.red);
    }
  }

  /// Manda un archivo YA armado —la ficha del producto, el catálogo— por
  /// WhatsApp, preguntando a qué número.
  ///
  /// Es el mismo flujo que [escribirACliente] con una diferencia: acá el
  /// destinatario NO sale de una ficha de cliente. Quien pregunta por un
  /// producto puede no estar registrado, así que el número se escribe en el
  /// cuadro.
  ///
  /// 🔴 El archivo solo viaja con la línea de la empresa vinculada: `wa.me`
  /// no acepta adjuntos. Sin vinculación se abre el chat con el texto y el
  /// archivo se ofrece por el compartir del sistema, que es el único camino
  /// que sí lo lleva —el usuario elige ahí el contacto—.
  static Future<void> compartirArchivo(
    BuildContext context, {
    required String empresaId,
    required File archivo,
    required String nombreArchivo,
    required String textoInicial,
    required bool esPdf,
    String? detalleAdjunto,
    String? telefono,
    String? nombreCliente,

    /// El compartir nativo de la pantalla que llama. Es el respaldo REAL del
    /// archivo cuando no hay línea vinculada.
    Future<void> Function()? compartirNativo,
  }) async {
    final envio = await _estadoEnvio(empresaId);
    final apps = envio.conectado
        ? const <AppWhatsapp>[]
        : await appsWhatsappInstaladas();
    if (!context.mounted) return;

    final destinatario = (nombreCliente?.trim().isNotEmpty ?? false)
        ? nombreCliente!.trim()
        : 'un cliente';

    final redactado = await mostrarDialogoMensajeWhatsapp(
      context,
      textoInicial: textoInicial,
      destinatario: destinatario,
      envioDirecto: envio.conectado,
      numeroEmpresa: envio.numero,
      appsDisponibles: apps,
      pedirNumero: true,
      numeroInicial: telefono,
      adjunto: (
        archivo: archivo,
        nombre: nombreArchivo,
        detalle: detalleAdjunto,
        esPdf: esPdf,
      ),
    );
    if (redactado == null || !context.mounted) return;

    // El cuadro ya validó que se puede armar; acá se arma de nuevo porque es
    // esta forma —con código de país y sin símbolos— la que viaja.
    final numero = telefonoParaWhatsapp(redactado.numero ?? telefono);
    if (numero == null) return;

    if (envio.conectado) {
      final error = await _enviarArchivo(
        empresaId: empresaId,
        numero: numero,
        archivo: archivo,
        nombreArchivo: nombreArchivo,
        esPdf: esPdf,
        caption: redactado.texto,
      );
      if (!context.mounted) return;
      if (error == null) {
        _avisar(context, 'Enviado por WhatsApp', color: Colors.green);
        return;
      }
      _avisar(context, error, color: Colors.orange, segundos: 5);
    }

    if (!context.mounted) return;
    final app = redactado.app;
    if (app != null) await recordarAppWhatsapp(app);

    final abierto = await abrirChatWhatsapp(
      numero: numero,
      texto: redactado.texto,
      app: app,
    );
    if (!context.mounted) return;
    if (!abierto) {
      _avisar(context, 'No se pudo abrir WhatsApp', color: Colors.red);
      return;
    }
    // El texto ya salió; el archivo no puede ir por el enlace. Se deja el
    // atajo a mano en vez de dar por hecho que el usuario sabe adjuntarlo.
    if (compartirNativo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El archivo no viaja por el enlace'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Enviar archivo',
            textColor: Colors.white,
            onPressed: compartirNativo,
          ),
        ),
      );
    }
  }

  /// Manda el archivo por el sistema. Devuelve null si salió, o el motivo
  /// para mostrar cuando no.
  ///
  /// 🔴 El tope no es un capricho: el backend rechaza más de 8 MB de base64
  /// (~6 MB de archivo) y un catálogo de sesenta productos con foto propia
  /// los pasa. Avisar antes es mejor que un 400 sin explicación.
  static Future<String?> _enviarArchivo({
    required String empresaId,
    required String numero,
    required File archivo,
    required String nombreArchivo,
    required bool esPdf,
    required String caption,
  }) async {
    try {
      final bytes = await archivo.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        return 'El archivo pesa ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB '
            'y no se puede enviar desde el sistema. Se abre WhatsApp.';
      }
      final datos = base64Encode(bytes);
      final ds = locator<EmpresaRemoteDataSource>();
      if (esPdf) {
        await ds.enviarDocumentoWhatsapp(
          empresaId: empresaId,
          numero: numero,
          base64: datos,
          nombreArchivo: nombreArchivo,
          caption: caption,
        );
      } else {
        await ds.enviarImagenWhatsapp(
          empresaId: empresaId,
          numero: numero,
          base64: datos,
          caption: caption,
          mimetype: 'image/png',
        );
      }
      return null;
    } catch (_) {
      return 'No se pudo enviar desde el sistema. Se abre WhatsApp.';
    }
  }

  /// Abre el marcador del teléfono.
  static Future<void> llamar(BuildContext context, String telefono) async {
    final numero = telefonoParaLlamar(telefono);
    if (numero == null) return;
    await _abrirUrl(
      context,
      Uri.parse('tel:$numero'),
      'No se pudo abrir el marcador',
    );
  }

  /// Estado liviano de la vinculación. Ante cualquier problema devuelve "no
  /// conectado": abrir WhatsApp siempre funciona, y es preferible a prometer
  /// un envío directo que después no ocurre.
  static Future<({bool conectado, String? numero})> _estadoEnvio(
    String empresaId,
  ) async {
    try {
      final data = await locator<EmpresaRemoteDataSource>()
          .getEstadoEnvioWhatsapp(empresaId);
      return (
        conectado: data['conectado'] as bool? ?? false,
        numero: data['numero'] as String?,
      );
    } catch (_) {
      return (conectado: false, numero: null);
    }
  }

  /// true si salió por el sistema.
  ///
  /// Con imagen va como UNA sola pieza —la foto con el texto de pie—, que es
  /// como WhatsApp la muestra: dos mensajes separados le llegan al cliente
  /// desordenados.
  static Future<bool> _enviarPorElSistema(
    BuildContext context,
    String empresaId,
    String numero,
    MensajeRedactado redactado,
  ) async {
    try {
      final ds = locator<EmpresaRemoteDataSource>();
      final imagen = redactado.imagen;
      if (imagen != null) {
        await ds.enviarImagenWhatsapp(
          empresaId: empresaId,
          numero: numero,
          base64: base64Encode(await imagen.readAsBytes()),
          caption: redactado.texto,
        );
      } else {
        await ds.enviarMensajeWhatsapp(
          empresaId: empresaId,
          numero: numero,
          mensaje: redactado.texto,
        );
      }
      if (context.mounted) {
        _avisar(context, 'Mensaje enviado por WhatsApp', color: Colors.green);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _abrirUrl(
    BuildContext context,
    Uri uri,
    String error,
  ) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch devolvió false');
    } catch (_) {
      if (context.mounted) _avisar(context, error, color: Colors.red);
    }
  }

  static void _avisar(
    BuildContext context,
    String texto, {
    required Color color,
    int segundos = 4,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: color,
        duration: Duration(seconds: segundos),
      ),
    );
  }
}
