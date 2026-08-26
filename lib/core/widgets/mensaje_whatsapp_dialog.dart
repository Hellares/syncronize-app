import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/whatsapp_apps.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';

/// Un atajo del cuadro: el rótulo del chip y la frase que agrega.
typedef AtajoMensaje = ({String etiqueta, String texto});

/// Lo que el cuadro devuelve: el texto, la imagen si eligieron una, y con
/// cuál de las dos apps de WhatsApp abrir (null = la que decida el sistema).
typedef MensajeRedactado = ({String texto, File? imagen, AppWhatsapp? app});

/// Redacta el mensaje ANTES de abrir WhatsApp.
///
/// 🔴 Existe por una limitación que no es nuestra: `wa.me` solo acepta `phone`
/// y `text`, y **dónde queda el cursor lo decide WhatsApp** — abre el chat con
/// el texto puesto pero el caret al principio, así que seguir escribiendo
/// obliga a reposicionarlo a mano. Redactando acá, WhatsApp recibe el mensaje
/// terminado y no hay nada que reposicionar.
///
/// De paso permite revisar el saludo antes de que el cliente lo vea.
///
/// Devuelve el texto final, o null si se canceló.
Future<MensajeRedactado?> mostrarDialogoMensajeWhatsapp(
  BuildContext context, {
  required String textoInicial,
  required String destinatario,
  List<AtajoMensaje> atajos = const [],
  /// true ⇒ el mensaje sale del WhatsApp de la empresa sin salir de la app.
  /// false ⇒ se abre WhatsApp con el texto puesto.
  bool envioDirecto = false,
  /// El número de la empresa, para decir de dónde sale. Solo se muestra
  /// cuando [envioDirecto].
  String? numeroEmpresa,

  /// Las apps de WhatsApp instaladas. Con DOS se ofrece elegir; con una o
  /// ninguna no hay nada que preguntar. Se ignora si [envioDirecto], que no
  /// abre ninguna app.
  List<AppWhatsapp> appsDisponibles = const [],
}) async {
  final elegirApp = !envioDirecto && appsDisponibles.length > 1;
  final borrador = _BorradorMensaje(textoInicial)
    // Preseleccionada la primera para que el botón siempre pueda actuar sin
    // obligar a tocar el selector.
    ..app = elegirApp ? appsDisponibles.first : null;

  final resultado = await StyledDialog.show<MensajeRedactado>(
    context,
    accentColor: const Color(0xFF25D366),
    backgroundColor: Colors.white,
    icon: envioDirecto ? Icons.send : Icons.chat,
    titulo: 'Mensaje a $destinatario',
    // Que el usuario sepa ANTES de escribir si el mensaje va a salir solo o
    // si todavía le falta darle enviar en WhatsApp.
    subtitulo: envioDirecto
        ? 'Se envía desde el WhatsApp de la empresa'
        : 'Se abre WhatsApp con el texto ya escrito',
    content: [
      _MensajeForm(
        borrador: borrador,
        atajos: atajos,
        envioDirecto: envioDirecto,
        numeroEmpresa: numeroEmpresa,
        appsDisponibles: elegirApp ? appsDisponibles : const [],
      ),
    ],
    actions: [
      Expanded(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ),
      Expanded(
        child: CustomButton(
          text: envioDirecto ? 'Enviar' : 'Abrir WhatsApp',
          icon: Icon(envioDirecto ? Icons.send : Icons.open_in_new,
              size: 14, color: Colors.white),
          backgroundColor: const Color(0xFF25D366),
          textColor: Colors.white,
          onPressed: () {
            final t = borrador.texto.trim();
            // Con imagen el texto puede ir vacío: la foto ES el mensaje.
            // Sin imagen y sin texto no hay nada que mandar.
            if (t.isEmpty && borrador.imagen == null) return;
            Navigator.pop(
              context,
              (texto: t, imagen: borrador.imagen, app: borrador.app),
            );
          },
        ),
      ),
    ],
  );

  return resultado;
}

class _BorradorMensaje {
  _BorradorMensaje(this.texto);
  String texto;

  /// Solo puede haber una: WhatsApp manda una imagen con su caption, y varias
  /// serían varios mensajes — otra cosa, no un parámetro más.
  File? imagen;

  /// Con cuál de las dos apps abrir. null = la que decida el sistema.
  AppWhatsapp? app;
}

class _MensajeForm extends StatefulWidget {
  const _MensajeForm({
    required this.borrador,
    required this.atajos,
    required this.envioDirecto,
    this.numeroEmpresa,
    this.appsDisponibles = const [],
  });

  final _BorradorMensaje borrador;
  final List<AtajoMensaje> atajos;
  final bool envioDirecto;
  final String? numeroEmpresa;
  final List<AppWhatsapp> appsDisponibles;

  @override
  State<_MensajeForm> createState() => _MensajeFormState();
}

class _MensajeFormState extends State<_MensajeForm> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.borrador.texto);
    // El caret al final, explícito. Con `autofocus` Flutter ya lo deja ahí
    // —lo verifiqué quitando esta línea y el test sigue pasando—, pero el
    // controller nace con la selección en -1 y depender de ese default en la
    // única pantalla cuyo motivo de existir ES la posición del cursor sería
    // gratuito. Una línea, y queda dicho.
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  File? _imagen;

  /// 🔴 Redimensiona AL ELEGIR, no al enviar: una foto de celular son 3-5 MB
  /// y en base64 crece un tercio más. A 1600px y calidad 70 queda en unos
  /// 300 KB, que es lo que el picker ya hace en el resto de la app.
  Future<void> _elegirImagen(ImageSource source) async {
    try {
      final foto = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 70,
      );
      if (foto == null || !mounted) return;
      setState(() => _imagen = File(foto.path));
      widget.borrador.imagen = _imagen;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la cámara o galería')),
      );
    }
  }

  void _quitarImagen() {
    setState(() => _imagen = null);
    widget.borrador.imagen = null;
  }

  Widget _botonAdjuntar(IconData icono, String texto, ImageSource source) {
    return Expanded(
      child: InkWell(
        onTap: () => _elegirImagen(source),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 15, color: AppColors.blue1),
              const SizedBox(width: 5),
              AppSubtitle(
                texto,
                font: AppFont.amazonEmberMedium,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonApp(AppWhatsapp app) {
    final elegida = widget.borrador.app == app;
    return InkWell(
      onTap: () => setState(() => widget.borrador.app = app),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: elegida
              ? const Color(0xFF25D366).withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: elegida
                ? const Color(0xFF25D366).withValues(alpha: 0.55)
                : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              elegida ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 14,
              color: elegida ? const Color(0xFF25D366) : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AppSubtitle(
                app.etiqueta,
                font: AppFont.amazonEmberMedium,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: elegida ? AppColors.blue3 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniatura() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            _imagen!,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppSubtitle(
            'Se envía con el mensaje',
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        IconButton(
          onPressed: _quitarImagen,
          icon: const Icon(Icons.close, size: 16),
          color: Colors.grey.shade500,
          tooltip: 'Quitar imagen',
          style: IconButton.styleFrom(
            minimumSize: Size.zero,
            fixedSize: const Size(32, 32),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  /// El atajo se agrega AL FINAL y deja el caret ahí. Insertar en la posición
  /// del cursor sería más astuto y menos predecible: partiría la frase por la
  /// mitad si el cursor quedó en el medio.
  void _agregar(String frase) {
    final actual = _ctrl.text.trimRight();
    final nuevo = actual.isEmpty ? frase : '$actual $frase';
    _ctrl.text = nuevo;
    _ctrl.selection = TextSelection.collapsed(offset: nuevo.length);
    widget.borrador.texto = nuevo;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          autofocus: true,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF25D366), width: 1.2),
            ),
          ),
          onChanged: (v) => widget.borrador.texto = v,
        ),
        // 🔴 Adjuntar solo con la línea vinculada: `wa.me` no acepta
        // archivos, así que sin vinculación no hay forma de mandar la imagen
        // y ofrecer el botón sería mentir.
        if (widget.envioDirecto) ...[
          const SizedBox(height: 8),
          if (_imagen != null)
            _buildMiniatura()
          else
            Row(
              children: [
                _botonAdjuntar(
                  Icons.photo_library_outlined,
                  'Galería',
                  ImageSource.gallery,
                ),
                const SizedBox(width: 8),
                _botonAdjuntar(
                  Icons.photo_camera_outlined,
                  'Cámara',
                  ImageSource.camera,
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle,
                  size: 13, color: Color(0xFF25D366)),
              const SizedBox(width: 5),
              Expanded(
                child: AppSubtitle(
                  widget.numeroEmpresa != null
                      ? 'Sale del WhatsApp de la empresa '
                          '(${widget.numeroEmpresa}) sin salir de la app'
                      : 'Sale del WhatsApp de la empresa sin salir de la app',
                  fontSize: 9,
                  maxLines: 2,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
        // Con dos apps instaladas hay que preguntar: cada una tiene su propia
        // cuenta, y mandar el mensaje del negocio por la personal es un error
        // que se descubre cuando el cliente contesta al número equivocado.
        if (widget.appsDisponibles.length > 1) ...[
          const SizedBox(height: 10),
          AppSubtitle(
            'Abrir con',
            font: AppFont.amazonEmberMedium,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 5),
          Row(
            children: widget.appsDisponibles
                .map((app) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: app == widget.appsDisponibles.last ? 0 : 6,
                        ),
                        child: _botonApp(app),
                      ),
                    ))
                .toList(),
          ),
        ],
        if (widget.atajos.isNotEmpty) ...[
          const SizedBox(height: 10),
          AppSubtitle(
            'Agregar',
            font: AppFont.amazonEmberMedium,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.atajos
                .map((a) => InkWell(
                      onTap: () => _agregar(a.texto),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.blue1.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add,
                                size: 12, color: AppColors.blue1),
                            const SizedBox(width: 3),
                            AppSubtitle(
                              a.etiqueta,
                              font: AppFont.amazonEmberMedium,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue1,
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
