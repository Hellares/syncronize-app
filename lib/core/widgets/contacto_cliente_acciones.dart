import 'package:flutter/material.dart';

import '../services/whatsapp_cliente_service.dart';
import '../theme/app_colors.dart';
import '../utils/telefono_helper.dart';

/// Los dos accesos que uno quiere cuando está mirando el teléfono de un
/// cliente: escribirle por WhatsApp y llamarlo.
///
/// Se dibuja al final de la fila del teléfono. Cada botón aparece solo si el
/// número sirve para eso: un fijo se puede llamar pero no tiene WhatsApp.
class ContactoClienteAcciones extends StatelessWidget {
  const ContactoClienteAcciones({
    super.key,
    required this.telefono,
    this.onWhatsapp,
  });

  final String telefono;

  /// Qué hacer al tocar WhatsApp. Null ⇒ no se ofrece — la pantalla decide,
  /// porque el mensaje inicial depende de lo que se está mirando.
  final VoidCallback? onWhatsapp;

  static const _verdeWhatsapp = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final wa = telefonoParaWhatsapp(telefono);
    final tel = telefonoParaLlamar(telefono);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wa != null && onWhatsapp != null)
          _boton(
            icono: Icons.chat,
            color: _verdeWhatsapp,
            tooltip: 'WhatsApp',
            onTap: onWhatsapp!,
          ),
        if (tel != null)
          _boton(
            icono: Icons.call,
            color: AppColors.blue1,
            tooltip: 'Llamar',
            onTap: () => WhatsappClienteService.llamar(context, telefono),
          ),
      ],
    );
  }

  /// 🔴 `shrinkWrap` + tamaño fijo: el IconButton por defecto reserva ~48px y
  /// rompe una fila de 10px de fuente.
  /// Ver feedback_iconbutton_m3_tap_target_minimo.
  Widget _boton({
    required IconData icono,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icono, size: 16),
      color: color,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: Size.zero,
        fixedSize: const Size(30, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
