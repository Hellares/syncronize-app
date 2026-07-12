import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/sorteo.dart';

/// Envío del ticket por WhatsApp al ganador en 2 pasos guiados.
///
/// WhatsApp NO permite mandar imagen + texto a un número no agendado en
/// un solo intent: wa.me solo prellenar TEXTO, y el share de imagen no
/// deja preseleccionar destinatario. El truco: el paso 1 (wa.me) crea el
/// chat con el número, y en el paso 2 ese chat ya aparece en "recientes"
/// del share sheet.
Future<void> showEnviarWhatsAppPremioSheet({
  required BuildContext context,
  required SorteoPremio premio,
  required String empresaNombre,
  File? ticketLocal,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnviarWhatsAppPremioSheet(
      premio: premio,
      empresaNombre: empresaNombre,
      ticketLocal: ticketLocal,
    ),
  );
}

class _EnviarWhatsAppPremioSheet extends StatefulWidget {
  final SorteoPremio premio;
  final String empresaNombre;

  /// Ticket recién subido (aún en disco) — evita re-descargarlo.
  final File? ticketLocal;

  const _EnviarWhatsAppPremioSheet({
    required this.premio,
    required this.empresaNombre,
    this.ticketLocal,
  });

  @override
  State<_EnviarWhatsAppPremioSheet> createState() =>
      _EnviarWhatsAppPremioSheetState();
}

class _EnviarWhatsAppPremioSheetState
    extends State<_EnviarWhatsAppPremioSheet> {
  late final _mensajeCtrl =
      TextEditingController(text: _mensajeDefault(widget.premio));
  bool _paso1Hecho = false;
  bool _compartiendo = false;

  String _mensajeDefault(SorteoPremio p) {
    final hora = DateTime.now().hour;
    final saludo = hora >= 5 && hora < 12
        ? 'Buenos días'
        : hora < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    final buf = StringBuffer()
      ..writeln('$saludo ${p.ganadorNombre} 🎉')
      ..writeln()
      ..writeln('*PREMIO ENVIADO* 📦')
      ..writeln('Su premio: ${p.descripcion}');
    if (p.agenciaNombre != null && p.agenciaNombre!.isNotEmpty) {
      buf.writeln(
          'Agencia: ${p.agenciaNombre}${p.destinoTexto != null ? ' → ${p.destinoTexto}' : ''}');
    }
    final envio = [
      if (p.envioNumeroOrden != null) 'Orden: ${p.envioNumeroOrden}',
      if (p.envioCodigo != null) 'Código: ${p.envioCodigo}',
      if (p.envioClave != null) 'Clave de recojo: *${p.envioClave}*',
    ];
    if (envio.isNotEmpty) {
      buf.writeln(envio.join(' · '));
      if (p.envioClave != null) {
        buf.writeln('(la agencia le pedirá la clave para entregarle)');
      }
    }
    buf
      ..writeln()
      ..writeln('Le compartimos el ticket de envío como constancia.')
      ..writeln('¡Gracias por su preferencia! 😊')
      ..writeln('_${widget.empresaNombre}_');
    return buf.toString().trim();
  }

  /// Misma normalización que WhatsAppNotificationService (órdenes de
  /// servicio): celular peruano de 9 dígitos → 51XXXXXXXXX.
  String get _phone {
    var phone =
        (widget.premio.ganadorCelular ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    } else if (phone.startsWith('00')) {
      phone = phone.substring(2);
    } else if (phone.length <= 10) {
      phone = phone.startsWith('0')
          ? '51${phone.substring(1)}'
          : '51$phone';
    }
    return phone;
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WhatsApp a ${widget.premio.ganadorNombre}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('+$_phone',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: _mensajeCtrl,
                label: 'Mensaje (editable)',
                borderColor: AppColors.blue1,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 4,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.amber.shade700.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'WhatsApp no permite adjuntar la imagen '
                        'automáticamente: primero envía el mensaje y luego '
                        'comparte el ticket eligiendo el mismo chat '
                        '(saldrá en recientes).',
                        style: TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: _paso1Hecho
                    ? '✓ Mensaje enviado — reenviar'
                    : '1 · Enviar mensaje por WhatsApp',
                backgroundColor:
                    _paso1Hecho ? Colors.grey.shade500 : Colors.green.shade700,
                textColor: Colors.white,
                icon: const Icon(Icons.send, size: 15, color: Colors.white),
                iconColor: Colors.white,
                onPressed: _enviarMensaje,
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: _compartiendo
                    ? 'Preparando imagen…'
                    : '2 · Compartir imagen del ticket',
                backgroundColor:
                    _paso1Hecho ? Colors.green.shade700 : Colors.white,
                textColor: _paso1Hecho ? Colors.white : Colors.green.shade800,
                isOutlined: !_paso1Hecho,
                borderColor: Colors.green.shade700,
                icon: Icon(Icons.image_outlined,
                    size: 15,
                    color: _paso1Hecho ? Colors.white : Colors.green.shade800),
                iconColor: _paso1Hecho ? Colors.white : Colors.green.shade800,
                onPressed: _compartiendo ? null : _compartirTicket,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    final url = Uri.parse(
        'https://wa.me/$_phone?text=${Uri.encodeComponent(_mensajeCtrl.text.trim())}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _paso1Hecho = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir WhatsApp',
              style: TextStyle(fontSize: 12))));
    }
  }

  Future<void> _compartirTicket() async {
    setState(() => _compartiendo = true);
    try {
      final file = await _ticketFile();
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No se pudo obtener la imagen del ticket',
                  style: TextStyle(fontSize: 12))));
        }
        return;
      }
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ticket de envío de su premio 📦',
      );
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  /// Ticket recién subido (local) o descarga del último ticket del premio.
  Future<File?> _ticketFile() async {
    final local = widget.ticketLocal;
    if (local != null && await local.exists()) return local;
    final tickets = widget.premio.tickets;
    if (tickets.isEmpty) return null;
    try {
      final url = tickets.last.url;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final ext = url.split('.').last.split('?').first;
      final file = File(
          '${dir.path}/ticket_${widget.premio.id}.${ext.length <= 4 ? ext : 'jpg'}');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      return null;
    }
  }
}
