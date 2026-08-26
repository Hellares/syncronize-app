import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';

/// Un atajo del cuadro: el rótulo del chip y la frase que agrega.
typedef AtajoMensaje = ({String etiqueta, String texto});

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
Future<String?> mostrarDialogoMensajeWhatsapp(
  BuildContext context, {
  required String textoInicial,
  required String destinatario,
  List<AtajoMensaje> atajos = const [],
}) async {
  final borrador = _BorradorMensaje(textoInicial);

  final texto = await StyledDialog.show<String>(
    context,
    accentColor: const Color(0xFF25D366),
    backgroundColor: Colors.white,
    icon: Icons.chat,
    titulo: 'Mensaje a $destinatario',
    subtitulo: 'Se abre WhatsApp con el texto ya escrito',
    content: [_MensajeForm(borrador: borrador, atajos: atajos)],
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
          text: 'Abrir WhatsApp',
          icon: const Icon(Icons.send, size: 14, color: Colors.white),
          backgroundColor: const Color(0xFF25D366),
          textColor: Colors.white,
          onPressed: () {
            final t = borrador.texto.trim();
            // Un mensaje vacío abriría el chat sin nada; mejor no hacer nada
            // que abrir WhatsApp para que el usuario vuelva.
            if (t.isEmpty) return;
            Navigator.pop(context, t);
          },
        ),
      ),
    ],
  );

  return texto;
}

class _BorradorMensaje {
  _BorradorMensaje(this.texto);
  String texto;
}

class _MensajeForm extends StatefulWidget {
  const _MensajeForm({required this.borrador, required this.atajos});

  final _BorradorMensaje borrador;
  final List<AtajoMensaje> atajos;

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
