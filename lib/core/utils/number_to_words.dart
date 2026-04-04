/// Convierte un monto numérico a texto en español para comprobantes SUNAT.
/// Ejemplo: 1580.50 → "MIL QUINIENTOS OCHENTA CON 50/100 SOLES"
class NumberToWords {
  static const _unidades = [
    '', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO',
    'SEIS', 'SIETE', 'OCHO', 'NUEVE',
  ];

  static const _especiales = [
    'DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE',
    'DIECISEIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE', 'VEINTE',
  ];

  static const _decenas = [
    '', '', 'VEINTI', 'TREINTA', 'CUARENTA', 'CINCUENTA',
    'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA',
  ];

  static const _centenas = [
    '', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS',
    'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS',
  ];

  /// Convierte un monto a texto. Ej: convert(1580.50, 'SOLES') → "MIL QUINIENTOS OCHENTA CON 50/100 SOLES"
  static String convert(double amount, {String moneda = 'SOLES'}) {
    if (amount < 0) return 'MENOS ${convert(-amount, moneda: moneda)}';
    if (amount == 0) return 'CERO CON 00/100 $moneda';

    final entero = amount.truncate();
    final centavos = ((amount - entero) * 100).round();
    final centavosStr = centavos.toString().padLeft(2, '0');

    final texto = _convertirEntero(entero);
    return '$texto CON $centavosStr/100 $moneda';
  }

  static String _convertirEntero(int n) {
    if (n == 0) return 'CERO';
    if (n == 100) return 'CIEN';

    final partes = <String>[];

    if (n >= 1000000) {
      final millones = n ~/ 1000000;
      if (millones == 1) {
        partes.add('UN MILLON');
      } else {
        partes.add('${_convertirEntero(millones)} MILLONES');
      }
      n %= 1000000;
    }

    if (n >= 1000) {
      final miles = n ~/ 1000;
      if (miles == 1) {
        partes.add('MIL');
      } else {
        partes.add('${_convertirEntero(miles)} MIL');
      }
      n %= 1000;
    }

    if (n >= 100) {
      if (n == 100) {
        partes.add('CIEN');
        return partes.join(' ');
      }
      partes.add(_centenas[n ~/ 100]);
      n %= 100;
    }

    if (n >= 21 && n <= 29) {
      partes.add('${_decenas[2]}${_unidades[n - 20]}');
    } else if (n >= 10 && n <= 20) {
      partes.add(_especiales[n - 10]);
    } else if (n > 0) {
      if (n >= 30) {
        partes.add(_decenas[n ~/ 10]);
        final u = n % 10;
        if (u > 0) {
          partes.add('Y ${_unidades[u]}');
        }
      } else {
        partes.add(_unidades[n]);
      }
    }

    return partes.join(' ');
  }
}
