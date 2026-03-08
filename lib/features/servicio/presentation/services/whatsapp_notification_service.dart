import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/orden_servicio.dart';

class WhatsAppNotificationService {
  static const _templates = {
    'RECIBIDO':
        'Hola {cliente}! Hemos recibido su equipo en {empresa}. Su orden de servicio es *{codigo}*. Le mantendremos informado del progreso.',
    'EN_DIAGNOSTICO':
        'Hola {cliente}! Su equipo con orden *{codigo}* esta siendo diagnosticado en {empresa}. Pronto le informaremos los resultados.',
    'ESPERANDO_APROBACION':
        'Hola {cliente}! El diagnostico de su equipo (orden *{codigo}*) esta listo. Esperamos su aprobacion para continuar con el servicio en {empresa}.',
    'EN_REPARACION':
        'Hola {cliente}! Su equipo con orden *{codigo}* esta en reparacion en {empresa}. Le avisaremos cuando este listo.',
    'PENDIENTE_PIEZAS':
        'Hola {cliente}! Su equipo con orden *{codigo}* esta en espera de piezas en {empresa}. Le notificaremos cuando lleguen.',
    'REPARADO':
        'Hola {cliente}! Su equipo con orden *{codigo}* ha sido reparado en {empresa}. Pronto estara listo para recoger.',
    'LISTO_ENTREGA':
        'Hola {cliente}! Su equipo con orden *{codigo}* esta listo para recoger en {empresa}. Lo esperamos!',
    'ENTREGADO':
        'Hola {cliente}! Gracias por recoger su equipo (orden *{codigo}*) en {empresa}. Esperamos que todo este en orden.',
    'FINALIZADO':
        'Hola {cliente}! El servicio de su equipo (orden *{codigo}*) ha sido finalizado en {empresa}. Gracias por su confianza!',
    'CANCELADO':
        'Hola {cliente}! Le informamos que la orden de servicio *{codigo}* en {empresa} ha sido cancelada. Contactenos si tiene dudas.',
  };

  static Future<void> notificarCambioEstado({
    required OrdenServicio orden,
    required String nuevoEstado,
    required String empresaNombre,
  }) async {
    final telefono = orden.cliente?.telefono;
    if (telefono == null) return;

    final template = _templates[nuevoEstado];
    if (template == null) return;

    final clienteNombre = orden.cliente?.nombre ?? '';
    final mensaje = template
        .replaceAll('{cliente}', clienteNombre)
        .replaceAll('{codigo}', orden.codigo)
        .replaceAll('{empresa}', empresaNombre);

    final phone = _normalizePhone(telefono);
    final encodedMessage = Uri.encodeComponent(mensaje);

    final whatsappUrl =
        Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  static String _normalizePhone(String telefono) {
    var phone = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    } else if (phone.startsWith('00')) {
      phone = phone.substring(2);
    } else if (phone.length <= 10) {
      // Número local sin código de país — asumir Perú (+51)
      if (phone.startsWith('9') && phone.length == 9) {
        phone = '51$phone';
      } else if (phone.startsWith('0')) {
        // Número fijo con 0 delante
        phone = '51${phone.substring(1)}';
      } else {
        phone = '51$phone';
      }
    }
    return phone;
  }
}
