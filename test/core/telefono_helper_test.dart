import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/telefono_helper.dart';

void main() {
  group('telefonoParaWhatsapp', () {
    test('un celular peruano recibe el 51', () {
      expect(telefonoParaWhatsapp('987654321'), '51987654321');
      expect(telefonoParaWhatsapp('987 654 321'), '51987654321');
      expect(telefonoParaWhatsapp('987-654-321'), '51987654321');
    });

    test('con + se respeta el código de país que ya trae', () {
      expect(telefonoParaWhatsapp('+51 987654321'), '51987654321');
      // 🔴 Un número extranjero NO puede recibir el 51 encima.
      expect(telefonoParaWhatsapp('+54 9 11 2345 6789'), '5491123456789');
    });

    test('un número que ya empieza en 51 no se duplica', () {
      expect(telefonoParaWhatsapp('51987654321'), '51987654321');
    });

    test('🔴 lo que no es un celular peruano se deja como está', () {
      // Un fijo de Lima. Prefijarlo con 51 mandaría el mensaje a un número
      // que no es el del cliente; que WhatsApp diga "no válido" es mejor.
      expect(telefonoParaWhatsapp('7777777'), '7777777');
      expect(telefonoParaWhatsapp('(01) 777-7777'), '017777777');
      // Nueve dígitos pero no empieza en 9: tampoco es celular.
      expect(telefonoParaWhatsapp('123456789'), '123456789');
    });

    test('vacío o sin dígitos devuelve null', () {
      expect(telefonoParaWhatsapp(null), isNull);
      expect(telefonoParaWhatsapp(''), isNull);
      expect(telefonoParaWhatsapp('   '), isNull);
      expect(telefonoParaWhatsapp('sin numero'), isNull);
    });
  });

  group('telefonoParaLlamar', () {
    test('limpia separadores y conserva el +', () {
      expect(telefonoParaLlamar('987 654 321'), '987654321');
      expect(telefonoParaLlamar('(01) 777-7777'), '017777777');
      expect(telefonoParaLlamar('+51 987654321'), '+51987654321');
    });

    test('NO agrega código de país', () {
      // Marcar dentro del país no lo necesita, y algunas centralitas lo
      // rechazan.
      expect(telefonoParaLlamar('987654321'), '987654321');
    });

    test('vacío o sin dígitos devuelve null', () {
      expect(telefonoParaLlamar(null), isNull);
      expect(telefonoParaLlamar('---'), isNull);
    });
  });
}
