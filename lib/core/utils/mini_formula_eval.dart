import 'dart:math' as math;

/// Evaluador de fórmulas de la mini hoja de cálculo. Soporta:
///  - Aritmética con precedencia y paréntesis: `+ − × ÷` (alias `* /`), `%`
///    postfijo (÷100), menos unario.
///  - Variables de una letra (A, B, C…) = valor de la columna en la fila.
///  - Comparadores `> < >= <= = <>` (devuelven 1/0) para condiciones.
///  - Funciones:
///     · `SUMA(A)`, `PROM(A)`, `MIN(A)`, `MAX(A)` — agregados de la columna A
///       (usan el resolver [columna]).
///     · `REDONDEAR(x; n)` — redondea x a n decimales.
///     · `SI(cond; a; b)` — condicional (cond ≠ 0 → a, si no → b).
///  - Separador de argumentos `;`. Prefijo `=` opcional (se ignora).
///
/// Devuelve null si la fórmula es inválida, incompleta o divide entre 0.
double? evaluarFormula(
  String expr, {
  required Map<String, double> vars,
  List<double> Function(String letra)? columna,
}) {
  var e = expr.trim();
  if (e.startsWith('=')) e = e.substring(1); // hábito Excel
  if (e.isEmpty) return null;
  try {
    final tokens = _tokenizar(e);
    if (tokens.isEmpty) return null;
    final p = _ParserFormula(tokens, vars, columna);
    final r = p.parseExpr();
    if (!p.atEnd) return null;
    if (r.isNaN || r.isInfinite) return null;
    return r;
  } catch (_) {
    return null;
  }
}

List<String> _tokenizar(String s) {
  final out = <String>[];
  final numero = RegExp(r'[0-9.]');
  final letra = RegExp(r'[A-Za-z]');
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == ' ') {
      i++;
      continue;
    }
    if (numero.hasMatch(c)) {
      final sb = StringBuffer();
      while (i < s.length && numero.hasMatch(s[i])) {
        sb.write(s[i]);
        i++;
      }
      out.add(sb.toString());
    } else if (letra.hasMatch(c)) {
      final sb = StringBuffer();
      while (i < s.length && letra.hasMatch(s[i])) {
        sb.write(s[i]);
        i++;
      }
      out.add(sb.toString().toUpperCase()); // variable o función
    } else if (c == '>' || c == '<') {
      // Comparadores de 1 o 2 caracteres.
      final sig = i + 1 < s.length ? s[i + 1] : '';
      if (sig == '=') {
        out.add('$c=');
        i += 2;
      } else if (c == '<' && sig == '>') {
        out.add('<>');
        i += 2;
      } else {
        out.add(c);
        i++;
      }
    } else if ('+-−×÷*/%();='.contains(c)) {
      out.add(c);
      i++;
    } else {
      throw const FormatException('token inválido');
    }
  }
  return out;
}

const _funciones = {'SUMA', 'PROM', 'MIN', 'MAX', 'REDONDEAR', 'SI'};

class _ParserFormula {
  final List<String> t;
  final Map<String, double> vars;
  final List<double> Function(String)? columna;
  int pos = 0;

  _ParserFormula(this.t, this.vars, this.columna);

  bool get atEnd => pos >= t.length;
  String? get _cur => atEnd ? null : t[pos];

  /// Nivel superior: comparación (opcional).
  double parseExpr() {
    var v = _parseSuma();
    const comp = {'>', '<', '>=', '<=', '=', '<>'};
    if (comp.contains(_cur)) {
      final op = t[pos++];
      final r = _parseSuma();
      final res = switch (op) {
        '>' => v > r,
        '<' => v < r,
        '>=' => v >= r,
        '<=' => v <= r,
        '=' => v == r,
        '<>' => v != r,
        _ => false,
      };
      return res ? 1.0 : 0.0;
    }
    return v;
  }

  double _parseSuma() {
    var v = _parseTerm();
    while (_cur == '+' || _cur == '-' || _cur == '−') {
      final op = t[pos++];
      final r = _parseTerm();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _parseTerm() {
    var v = _parseUnary();
    while (_cur == '×' || _cur == '*' || _cur == '÷' || _cur == '/') {
      final op = t[pos++];
      final r = _parseUnary();
      if (op == '×' || op == '*') {
        v = v * r;
      } else {
        if (r == 0) throw const FormatException('÷0');
        v = v / r;
      }
    }
    return v;
  }

  double _parseUnary() {
    if (_cur == '−' || _cur == '-') {
      pos++;
      return -_parseUnary();
    }
    if (_cur == '+') {
      pos++;
      return _parseUnary();
    }
    return _parsePostfix();
  }

  double _parsePostfix() {
    var v = _parsePrimary();
    while (_cur == '%') {
      pos++;
      v = v / 100;
    }
    return v;
  }

  double _parsePrimary() {
    final c = _cur;
    if (c == null) throw const FormatException('fin inesperado');
    if (c == '(') {
      pos++;
      final v = parseExpr();
      if (_cur != ')') throw const FormatException('falta )');
      pos++;
      return v;
    }
    // Identificador: función o variable de una letra.
    if (RegExp(r'^[A-Z]+$').hasMatch(c)) {
      pos++;
      if (_cur == '(') return _parseFuncion(c);
      if (c.length == 1) {
        return vars[c] ?? (throw FormatException('variable $c no definida'));
      }
      throw FormatException('identificador desconocido: $c');
    }
    final d = double.tryParse(c);
    if (d == null) throw FormatException('número inválido: $c');
    pos++;
    return d;
  }

  double _parseFuncion(String nombre) {
    if (!_funciones.contains(nombre)) {
      throw FormatException('función desconocida: $nombre');
    }
    _consumir('(');
    switch (nombre) {
      case 'SUMA':
      case 'PROM':
      case 'MIN':
      case 'MAX':
        final letra = _letraArg();
        _consumir(')');
        final valores = columna?.call(letra) ?? const <double>[];
        if (valores.isEmpty) return 0;
        switch (nombre) {
          case 'SUMA':
            return valores.reduce((a, b) => a + b);
          case 'PROM':
            return valores.reduce((a, b) => a + b) / valores.length;
          case 'MIN':
            return valores.reduce(math.min);
          default:
            return valores.reduce(math.max);
        }
      case 'REDONDEAR':
        final x = parseExpr();
        _consumir(';');
        final n = parseExpr();
        _consumir(')');
        final f = math.pow(10, n.round()).toDouble();
        return (x * f).roundToDouble() / f;
      default: // SI
        final cond = parseExpr();
        _consumir(';');
        final a = parseExpr();
        _consumir(';');
        final b = parseExpr();
        _consumir(')');
        return cond != 0 ? a : b;
    }
  }

  String _letraArg() {
    final c = _cur;
    if (c == null || !RegExp(r'^[A-Z]$').hasMatch(c)) {
      throw const FormatException('se esperaba una columna (A, B, …)');
    }
    pos++;
    return c;
  }

  void _consumir(String tok) {
    if (_cur != tok) throw FormatException('se esperaba "$tok"');
    pos++;
  }
}
