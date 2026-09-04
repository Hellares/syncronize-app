/// Normalización de teléfonos para abrir WhatsApp o llamar.
///
/// Los teléfonos se cargan a mano y llegan de todas las formas: `987 654 321`,
/// `(01) 777-7777`, `+51 987654321`, `51987654321`. WhatsApp necesita el
/// número con código de país y SIN símbolos; el marcador del teléfono, en
/// cambio, funciona mejor con el número tal como se guardó.
library;

/// Prefijo de Perú. Único mercado del sistema hoy; si algún día hay otro,
/// esto pasa a salir de la configuración de la empresa.
const String kCodigoPaisPeru = '51';

/// El número listo para `wa.me`, o null si no hay con qué armarlo.
///
/// Reglas, en orden:
/// - se quedan solo los dígitos (y se recuerda si venía con `+`);
/// - con `+`, el número YA trae código de país y se respeta tal cual;
/// - un celular peruano (9 dígitos empezando en 9) recibe el `51`;
/// - un número que ya empieza en `51` y tiene 11 dígitos se deja quieto;
/// - cualquier otra cosa (un fijo de 7 dígitos, un interno) se devuelve como
///   está: es mejor que WhatsApp diga "número no válido" a que nosotros le
///   inventemos un prefijo y termine escribiéndole a un desconocido.
String? telefonoParaWhatsapp(String? telefono) {
  if (telefono == null) return null;
  final teniaMas = telefono.trimLeft().startsWith('+');
  final digitos = telefono.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return null;
  if (teniaMas) return digitos;
  if (digitos.length == 9 && digitos.startsWith('9')) {
    return '$kCodigoPaisPeru$digitos';
  }
  return digitos;
}

/// ¿Un número TIPEADO A MANO puede ser un celular?
///
/// 🔴 [telefonoParaWhatsapp] es a propósito permisivo —devuelve lo que sea que
/// tenga dígitos, para no inventarle un prefijo a un número guardado raro—, y
/// eso lo vuelve inútil como validación: `123` pasa. Cuando el número lo está
/// escribiendo alguien en el momento hay que ser estricto, porque el error se
/// puede corregir ahí mismo: un celular peruano son 9 dígitos, con código de
/// país 11, y E.164 topea en 15.
bool esCelularEscrito(String? telefono) {
  final digitos = (telefono ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  return digitos.length >= 9 && digitos.length <= 15;
}

/// El número para un `tel:`. Solo saca los espacios y separadores; no le pone
/// código de país, porque para marcar dentro del país no hace falta y algunas
/// centralitas lo rechazan.
String? telefonoParaLlamar(String? telefono) {
  if (telefono == null) return null;
  final limpio = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
  return limpio.isEmpty ? null : limpio;
}
