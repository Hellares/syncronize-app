import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../currency/currency_formatter.dart';

/// Controlador para [PosNumpad].
///
/// Mantiene un buffer crudo de texto (ej. "100", "100.5") y refleja el
/// resultado en un [TextEditingController] externo formateado con
/// separadores de miles. Pensado para POS donde se necesita captura
/// rápida de montos sin teclado del sistema, y reutilizable para arqueo
/// de caja, caja chica, ajustes manuales, etc.
///
/// Características:
///  - `decimales` configurable (default 2).
///  - El buffer respeta los dígitos tal como el cajero los tipea, sin
///    auto-completar el `.00`. Permite tipear "100" y luego ".50".
///  - `setValue(double)` para inicializar/saltar a un monto específico
///    (ej. botón "Exacto").
///  - `addAmount(double)` para sumar un valor (chips +S/10, +S/20, etc.).
class NumpadController extends ChangeNotifier {
  final TextEditingController textController;
  final int decimales;

  /// Si true, el display formatea con separadores de miles ("1,234.50").
  /// Para identificadores como DNI/RUC/N° de operación se pasa `false`
  /// porque no se separan en grupos.
  final bool formatearMiles;

  /// Tope de dígitos (sin contar el punto). Si null, sin tope.
  /// Útil para documentos: DNI=8, RUC=11, N° op variable.
  /// Mutable: se puede ajustar dinámicamente (ej. el cajero cambió tipoDoc).
  int? maxDigitos;

  /// Callback invocado cuando se intenta agregar un dígito y se rebota
  /// por límite (decimales o maxDigitos). Por default dispara una
  /// vibración perceptible. El widget [PosNumpad] lo wrappea para
  /// agregar también feedback visual.
  VoidCallback onLimitReached;

  /// Buffer crudo: solo dígitos y un punto decimal opcional.
  String _buffer = '';

  NumpadController({
    required this.textController,
    this.decimales = 2,
    this.formatearMiles = true,
    this.maxDigitos,
    VoidCallback? onLimitReached,
  }) : onLimitReached = onLimitReached ?? _defaultLimitFeedback {
    _adoptarTextoActual();
  }

  /// Vibración suave por default cuando se rebota por límite.
  /// Requiere "Vibración táctil" / "Haptic feedback" activado en el
  /// sistema; si está apagado, ningún haptic de Flutter funciona.
  static void _defaultLimitFeedback() => HapticFeedback.lightImpact();

  /// Trunca el buffer al nuevo tope si es menor (ej. el cajero pasó de
  /// RUC=11 a DNI=8 con 11 dígitos ya tipeados).
  void truncarSiExcede() {
    if (maxDigitos == null) return;
    if (_digitosActuales <= maxDigitos!) return;
    final partes = _buffer.split('.');
    if (partes[0].length > maxDigitos!) {
      partes[0] = partes[0].substring(0, maxDigitos!);
    }
    _buffer = partes.join('.');
    _emit();
  }

  /// Cuenta dígitos efectivos en el buffer (descontando el punto).
  int get _digitosActuales =>
      _buffer.replaceAll('.', '').length;

  /// Si el [TextEditingController] viene con texto previo, intentamos
  /// reflejarlo en el buffer para no resetear al enfocar.
  void _adoptarTextoActual() {
    final actual = textController.text.trim();
    if (actual.isEmpty) {
      _buffer = '';
      return;
    }
    if (!formatearMiles) {
      // Para documentos preservamos el texto crudo (DNI '00000000' no es 0).
      _buffer = actual.replaceAll(RegExp(r'[^0-9]'), '');
      return;
    }
    final v = CurrencyUtilsImproved.parseToDouble(actual);
    setValue(v, notify: false);
  }

  /// Valor numérico actual (0 si el buffer está vacío).
  double get value {
    if (_buffer.isEmpty) return 0;
    return double.tryParse(_buffer) ?? 0;
  }

  /// True si el buffer contiene un punto decimal.
  bool get _tienePunto => _buffer.contains('.');

  /// True si ya alcanzamos el máximo de decimales.
  bool get _decimalesLlenos {
    if (!_tienePunto) return false;
    final partes = _buffer.split('.');
    return partes.length == 2 && partes[1].length >= decimales;
  }

  /// Agrega un dígito (0-9). Bloquea si ya hay `decimales` dígitos
  /// después del punto o si se alcanzó `maxDigitos`. En caso de rebote
  /// dispara `onLimitReached` (haptic feedback en el widget).
  void appendDigit(String digit) {
    assert(digit.length == 1 && RegExp(r'^[0-9]$').hasMatch(digit));
    if (_decimalesLlenos) {
      onLimitReached();
      return;
    }
    if (maxDigitos != null && _digitosActuales >= maxDigitos!) {
      onLimitReached();
      return;
    }
    // Para montos, evitar leading zeros tipo "007" (pero permitir "0.5").
    // Para documentos, los leading zeros sí valen (ej. DNI "01234567"
    // o N° de operación "000123").
    if (formatearMiles && _buffer == '0') {
      _buffer = digit;
    } else {
      _buffer = _buffer + digit;
    }
    _emit();
  }

  /// Agrega varios dígitos en un solo emit. Útil para botones como "00"
  /// que insertan múltiples dígitos sin disparar dos rebuilds. Si en el
  /// medio se alcanza un límite, los dígitos restantes se descartan y se
  /// dispara `onLimitReached` una sola vez.
  void appendDigits(String digits) {
    assert(RegExp(r'^[0-9]+$').hasMatch(digits));
    var cambios = false;
    var rebotado = false;
    for (final d in digits.split('')) {
      if (_decimalesLlenos) {
        rebotado = true;
        break;
      }
      if (maxDigitos != null && _digitosActuales >= maxDigitos!) {
        rebotado = true;
        break;
      }
      if (formatearMiles && _buffer == '0') {
        _buffer = d;
      } else {
        _buffer = _buffer + d;
      }
      cambios = true;
    }
    if (cambios) _emit();
    if (rebotado) onLimitReached();
  }

  /// Agrega el separador decimal. No-op si el buffer ya lo tiene.
  void appendDecimal() {
    if (_tienePunto) return;
    _buffer = _buffer.isEmpty ? '0.' : '$_buffer.';
    _emit();
  }

  /// Elimina el último carácter del buffer.
  void backspace() {
    if (_buffer.isEmpty) return;
    _buffer = _buffer.substring(0, _buffer.length - 1);
    _emit();
  }

  /// Vacía el buffer.
  void clear() {
    if (_buffer.isEmpty) return;
    _buffer = '';
    _emit();
  }

  /// Setea el buffer desde un valor numérico. Si el resultado excede
  /// `maxDigitos` se ignora (no rompe el estado del input). Útil para
  /// "Exacto" (setear total) o quick amounts.
  void setValue(double v, {bool notify = true}) {
    if (v <= 0) {
      _buffer = '';
      if (notify) _emit();
      return;
    }
    final candidato = v.toStringAsFixed(decimales);
    final digitosCandidato = candidato.replaceAll('.', '').length;
    if (maxDigitos != null && digitosCandidato > maxDigitos!) {
      onLimitReached();
      return;
    }
    _buffer = candidato;
    if (notify) _emit();
  }

  /// Suma un monto al valor actual (ej. botón "+S/100"). Si la suma
  /// excede el tope, no aplica el cambio.
  void addAmount(double monto) {
    if (monto <= 0) return;
    setValue(value + monto);
  }

  /// Re-sincroniza el buffer con un texto externo (ej. el cajero pegó
  /// algo, o cambió el input activo del numpad).
  void resync() => _adoptarTextoActual();

  void _emit() {
    final nuevoTexto = _formatearParaDisplay();
    if (textController.text != nuevoTexto) {
      textController.value = TextEditingValue(
        text: nuevoTexto,
        selection: TextSelection.collapsed(offset: nuevoTexto.length),
      );
    }
    notifyListeners();
  }

  String _formatearParaDisplay() {
    if (_buffer.isEmpty) return '';
    // Documentos (DNI/RUC/N°op): devolver el buffer tal cual, sin
    // separadores de miles (44885296, no 44,885,296).
    if (!formatearMiles) return _buffer;
    // Si el cajero acaba de tocar "." mostramos tal cual para no perder
    // el feedback visual (sin auto-rellenar con ceros).
    if (_buffer.endsWith('.')) {
      final intPart = _buffer.substring(0, _buffer.length - 1);
      final n = int.tryParse(intPart) ?? 0;
      return '${_separarMiles(n)}.';
    }
    final v = double.tryParse(_buffer) ?? 0;
    if (_tienePunto) {
      // Conservar exactamente los decimales tipeados (ej. "100.5" → "100.5").
      final partes = _buffer.split('.');
      final intStr = _separarMiles(int.tryParse(partes[0]) ?? 0);
      final decStr = partes[1];
      return '$intStr.$decStr';
    }
    return _separarMiles(v.toInt());
  }

  String _separarMiles(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
