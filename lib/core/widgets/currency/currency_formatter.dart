import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 💰 FORMATEADOR DE MONEDA MEJORADO
/// Formatea automáticamente mientras escribes: 0.00, 0.20, 2.00, 20.00, 200.00, 2,000.00
class CurrencyFormatterImproved extends TextInputFormatter {
  final String symbol;
  final int decimalPlaces;
  final String locale; // 'es' para español, 'en' para inglés

  CurrencyFormatterImproved({
    this.symbol = 'S/',
    this.decimalPlaces = 2,
    this.locale = 'es',
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extraer solo los dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Si está completamente vacío, permitir campo vacío
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Si solo tiene ceros, mostrar 0.00
    if (digitsOnly == '0') {
      String formatted = '0.${'0' * decimalPlaces}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Remover ceros a la izquierda innecesarios
    digitsOnly = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    if (digitsOnly.isEmpty) digitsOnly = '0';

    // Convertir a double considerando los decimales
    // Por ejemplo: "20" -> 0.20, "200" -> 2.00, "2000" -> 20.00
    double value = int.parse(digitsOnly) / 100;

    // Formatear con separadores de miles
    String formatted = _formatCurrency(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCurrency(double value) {
    // Separar parte entera y decimal
    List<String> parts = value.toStringAsFixed(decimalPlaces).split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    // Agregar separadores de miles
    integerPart = _addThousandsSeparator(integerPart);

    return '$integerPart.$decimalPart';
  }

  String _addThousandsSeparator(String number) {
    if (number.length <= 3) return number;

    String reversed = number.split('').reversed.join('');
    String withCommas = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withCommas += ',';
      }
      withCommas += reversed[i];
    }
    
    return withCommas.split('').reversed.join('');
  }
}

/// 💰 UTILIDADES DE MONEDA MEJORADAS
class CurrencyUtilsImproved {
  /// Convierte el texto formateado a double
  /// Ejemplo: "2,500.50" -> 2500.50
  static double parseToDouble(String value) {
    if (value.isEmpty) return 0.0;
    String cleaned = value.replaceAll(',', '').replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Convierte double a texto formateado
  /// Ejemplo: 2500.50 -> "2,500.50"
  static String formatFromDouble(double value, {int decimals = 2}) {
    List<String> parts = value.toStringAsFixed(decimals).split('.');
    String integerPart = _addThousandsSeparator(parts[0]);
    String decimalPart = parts.length > 1 ? parts[1] : '00';
    return '$integerPart.$decimalPart';
  }

  /// Establece un valor en el controlador con formato
  static void setControllerValue(TextEditingController controller, double value) {
    // Si el valor es 0, establecer campo vacío en lugar de "0.00"
    if (value == 0.0) {
      controller.text = '';
    } else {
      controller.text = formatFromDouble(value);
    }
  }

  /// Obtiene el valor double del controlador
  static double getControllerValue(TextEditingController controller) {
    return parseToDouble(controller.text);
  }

  /// Valida si el texto es una moneda válida
  static bool isValid(String value) {
    if (value.isEmpty) return false;
    double? parsed = parseToDouble(value);
    return parsed >= 0;
  }

  /// Formatea para mostrar con símbolo
  /// Ejemplo: "2,500.50" -> "S/ 2,500.50"
  static String formatWithSymbol(String value, String symbol) {
    if (value.isEmpty) return '';
    return '$symbol $value';
  }

  static String _addThousandsSeparator(String number) {
    if (number.length <= 3) return number;
    String reversed = number.split('').reversed.join('');
    String withCommas = '';
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) withCommas += ',';
      withCommas += reversed[i];
    }
    return withCommas.split('').reversed.join('');
  }
}

/// 💰 EXTENSIÓN MEJORADA PARA TextEditingController (Moneda)
extension CurrencyControllerExtension on TextEditingController {
  /// Obtiene el valor como double
  double get currencyValue => CurrencyUtilsImproved.getControllerValue(this);

  /// Establece el valor desde un double
  set currencyValue(double value) => CurrencyUtilsImproved.setControllerValue(this, value);

  /// Verifica si el valor es válido
  bool get isValidCurrency => CurrencyUtilsImproved.isValid(text);

  /// Obtiene el texto con símbolo
  String currencyWithSymbol(String symbol) => CurrencyUtilsImproved.formatWithSymbol(text, symbol);
}


