

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import 'hoja_calculo_view.dart';

/// Modo de la calculadora.
enum _Modo {
  /// Cinta estilo CalcTape: escribes número + operador y cada línea se
  /// apila en la cinta con el total corriendo (suma secuencial).
  cinta,

  /// Calculadora de expresión con precedencia y paréntesis.
  normal,

  /// Mini hoja de cálculo (tabla estructurada + sumas).
  hoja,
}

/// Calculadora ARITMÉTICA moderna: herramienta 100% local para cuentas
/// rápidas sin salir del app. Convive con la [CalculadoraMostradorSheet]
/// (precios) dentro del dialer de herramientas flotantes.
///
/// Dos modos alternables:
///  - **CINTA (CalcTape)**: adding-machine. Número → operador apila la
///    línea; el total se calcula secuencialmente (sin precedencia). Cada
///    línea admite una etiqueta.
///  - **NORMAL**: expresión con precedencia + paréntesis (parser propio).
///
/// Comunes: IGV 18%, copiar/compartir, historial/cinta persistente.
class CalculadoraSimpleSheet extends StatefulWidget {
  const CalculadoraSimpleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CalculadoraSimpleSheet(),
    );
  }

  @override
  State<CalculadoraSimpleSheet> createState() => _CalculadoraSimpleSheetState();
}

class _CalculadoraSimpleSheetState extends State<CalculadoraSimpleSheet> {
  static const String _prefsKeyHist = 'calculadora_simple_historial';
  static const String _prefsKeyTape = 'calculadora_tape';
  static const String _prefsKeyModo = 'calculadora_modo';
  static const int _maxHistorial = 50;
  static const int _maxLineas = 200;
  static const int _maxLenExpr = 40;
  static const int _maxLenEntrada = 12;

  /// Tasa IGV Perú (18%). Constante — herramienta rápida, no lee config.
  static const double _igvRate = 0.18;

  _Modo _modo = _Modo.cinta;

  final TextEditingController _notaCtrl = TextEditingController();
  final TextEditingController _valorCtrl = TextEditingController();

  // ── Estado modo NORMAL (expresión) ────────────────────────────────────
  String _expr = '';
  bool _error = false;
  bool _recienIgual = false;
  bool _copiado = false;
  final List<_Calculo> _historial = [];
  final ScrollController _histCtrl = ScrollController();

  // ── Estado modo CINTA ─────────────────────────────────────────────────
  final List<_Linea> _lineas = [];
  String _entrada = '';

  /// Operador que se aplicará a la PRÓXIMA entrada al confirmarla. Presionar
  /// un operador con la entrada vacía solo cambia esto (no toca líneas
  /// previas). Así "15 − 5 =" resta 5 al total.
  String _opPend = '+';

  final ScrollController _tapeCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _histCtrl.dispose();
    _tapeCtrl.dispose();
    _notaCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  // ── Persistencia ──────────────────────────────────────────────────────

  Future<void> _cargarTodo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawH = prefs.getString(_prefsKeyHist);
      final rawT = prefs.getString(_prefsKeyTape);
      final modo = prefs.getString(_prefsKeyModo);
      final hist = rawH == null
          ? <_Calculo>[]
          : (jsonDecode(rawH) as List)
              .map((e) => _Calculo(
                    expr: e['e'] as String,
                    resultado: e['r'] as String,
                    nota: e['n'] as String?,
                  ))
              .toList();
      final tape = rawT == null
          ? <_Linea>[]
          : (jsonDecode(rawT) as List)
              .map((e) => _Linea(
                    op: e['o'] as String,
                    valor: (e['v'] as num).toDouble(),
                    esPct: e['p'] == true,
                    esCorte: e['c'] == true,
                    nota: e['n'] as String?,
                    notaSub: e['s'] as String?,
                  ))
              .toList();
      if (!mounted) return;
      setState(() {
        _historial
          ..clear()
          ..addAll(hist);
        _lineas
          ..clear()
          ..addAll(tape);
        if (modo == 'normal') {
          _modo = _Modo.normal;
        } else if (modo == 'hoja') {
          _modo = _Modo.hoja;
        }
      });
      _scrollHistFinal();
      _scrollTapeFinal();
    } catch (_) {
      // Datos corruptos → se ignoran (no es crítico).
    }
  }

  Future<void> _guardarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recorte = _historial.length > _maxHistorial
          ? _historial.sublist(_historial.length - _maxHistorial)
          : _historial;
      await prefs.setString(
        _prefsKeyHist,
        jsonEncode(recorte
            .map((c) => {
                  'e': c.expr,
                  'r': c.resultado,
                  if (c.nota != null && c.nota!.isNotEmpty) 'n': c.nota,
                })
            .toList()),
      );
    } catch (_) {}
  }

  Future<void> _guardarTape() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recorte = _lineas.length > _maxLineas
          ? _lineas.sublist(_lineas.length - _maxLineas)
          : _lineas;
      await prefs.setString(
        _prefsKeyTape,
        jsonEncode(recorte
            .map((l) => {
                  'o': l.op,
                  'v': l.valor,
                  if (l.esPct) 'p': true,
                  if (l.esCorte) 'c': true,
                  if (l.nota != null && l.nota!.isNotEmpty) 'n': l.nota,
                  if (l.notaSub != null && l.notaSub!.isNotEmpty) 's': l.notaSub,
                })
            .toList()),
      );
    } catch (_) {}
  }

  Future<void> _guardarModo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKeyModo,
          _modo == _Modo.cinta
              ? 'cinta'
              : (_modo == _Modo.normal ? 'normal' : 'hoja'));
    } catch (_) {}
  }

  void _cambiarModo(_Modo m) {
    if (m == _modo) return;
    setState(() => _modo = m);
    _guardarModo();
    HapticFeedback.selectionClick();
  }

  // ════════════════════════════════════════════════════════════════════
  //  MODO CINTA (CalcTape)
  // ════════════════════════════════════════════════════════════════════

  double _applyOp(double t, double v, String op) {
    switch (op) {
      case '+':
        return t + v;
      case '−':
        return t - v;
      case '×':
        return t * v;
      case '÷':
        return v == 0 ? double.nan : t / v;
    }
    return t;
  }

  /// Total del BLOQUE actual (secuencial). Cada corte reinicia el
  /// acumulador, así el bloque nuevo ignora los cálculos anteriores.
  double _totalCinta() {
    var t = 0.0;
    var idx = 0; // posición dentro del bloque
    for (final l in _lineas) {
      if (l.esCorte) {
        t = 0;
        idx = 0;
        continue;
      }
      final v = l.esPct ? t * l.valor / 100 : l.valor;
      t = idx == 0 ? (l.op == '−' ? -v : v) : _applyOp(t, v, l.op);
      idx++;
    }
    return t;
  }

  void _cintaDigito(String d) {
    setState(() {
      if (_entrada.length >= _maxLenEntrada) return;
      if (_entrada == '0') {
        _entrada = d;
      } else {
        _entrada += d;
      }
    });
  }

  void _cintaDecimal() {
    setState(() {
      if (_entrada.isEmpty) {
        _entrada = '0.';
      } else if (!_entrada.contains('.')) {
        _entrada += '.';
      }
    });
  }

  void _cintaOperar(String op) {
    // Entrada vacía: solo fija el operador pendiente para el próximo número
    // (no toca las líneas ya escritas).
    if (_entrada.isEmpty) {
      setState(() => _opPend = op);
      HapticFeedback.selectionClick();
      return;
    }
    // Confirma la entrada actual con el operador pendiente y deja el nuevo
    // operador como pendiente para lo que siga.
    setState(() {
      _lineas.add(_Linea(op: _opPend, valor: double.tryParse(_entrada) ?? 0));
      _entrada = '';
      _opPend = op;
    });
    _guardarTape();
    _scrollTapeFinal();
    HapticFeedback.selectionClick();
  }

  void _cintaIgual() {
    if (_entrada.isEmpty) return;
    setState(() {
      _lineas.add(_Linea(op: _opPend, valor: double.tryParse(_entrada) ?? 0));
      _entrada = '';
      _opPend = '+';
    });
    _guardarTape();
    _scrollTapeFinal();
    HapticFeedback.lightImpact();
  }

  /// % en cinta: apila una LÍNEA de porcentaje con el operador pendiente
  /// (ej. "− 18 %" resta 18%). Se resuelve sobre el total corriente.
  void _cintaPorcentaje() {
    if (_entrada.isEmpty) return;
    setState(() {
      _lineas.add(_Linea(
          op: _opPend, valor: double.tryParse(_entrada) ?? 0, esPct: true));
      _entrada = '';
      _opPend = '+';
    });
    _guardarTape();
    _scrollTapeFinal();
    HapticFeedback.selectionClick();
  }

  void _cintaBorrar() {
    setState(() {
      if (_entrada.isNotEmpty) {
        _entrada = _entrada.substring(0, _entrada.length - 1);
      } else if (_lineas.isNotEmpty) {
        _lineas.removeLast();
        _guardarTape();
      }
    });
  }

  void _cintaClear() {
    setState(() {
      _entrada = '';
      _opPend = '+';
    });
  }

  /// Cierra el bloque actual y empieza uno nuevo (que ignora lo anterior).
  /// Primero confirma la entrada pendiente para que entre en este bloque.
  void _cintaNuevoBloque() {
    setState(() {
      if (_entrada.isNotEmpty) {
        _lineas.add(_Linea(op: _opPend, valor: double.tryParse(_entrada) ?? 0));
        _entrada = '';
      }
      _opPend = '+';
      // Nada que cortar si el bloque actual está vacío.
      if (_lineas.isEmpty || _lineas.last.esCorte) return;
      _lineas.add(_Linea(op: '+', valor: 0, esCorte: true));
    });
    _guardarTape();
    _scrollTapeFinal();
    HapticFeedback.mediumImpact();
  }

  /// IGV en cinta: con número escrito transforma la entrada; sin número,
  /// agrega una LÍNEA de IGV sobre el total corriente.
  void _cintaIgv(bool agregar) {
    if (_entrada.isNotEmpty) {
      setState(() {
        final v = double.tryParse(_entrada) ?? 0;
        _entrada = _fmt(agregar ? v * (1 + _igvRate) : v / (1 + _igvRate));
      });
      HapticFeedback.lightImpact();
      return;
    }
    final total = _totalCinta();
    if (total.isNaN || _lineas.isEmpty) return;
    setState(() {
      final igv = agregar
          ? _round2(total * _igvRate)
          : _round2(total * _igvRate / (1 + _igvRate));
      _lineas.add(_Linea(op: agregar ? '+' : '−', valor: igv, nota: 'IGV 18%'));
    });
    _guardarTape();
    _scrollTapeFinal();
    HapticFeedback.lightImpact();
  }

  /// Editor de una fila de la cinta. [sub]=true → solo etiqueta del SUBTOTAL
  /// que sigue a la entrada [i]. false → edita operador + monto + nota de la
  /// entrada (los subtotales son calculados, no se editan sus valores).
  Future<void> _editarNotaLinea(int i, {bool sub = false}) async {
    if (i < 0 || i >= _lineas.length) return;
    if (sub) {
      await _editarNotaSubtotal(i);
      return;
    }
    final l = _lineas[i];
    _valorCtrl.text = _fmt(l.valor);
    _notaCtrl.text = l.nota ?? '';
    var opSel = l.op;
    await StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.edit_outlined,
      titulo: 'Editar línea',
      content: [
        StatefulBuilder(
          builder: (_, setLocal) => _selectorOp(
            opSel,
            (o) => setLocal(() => opSel = o),
          ),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _valorCtrl,
          hintText: l.esPct ? 'Porcentaje' : 'Monto',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: _notaCtrl,
          hintText: 'Nota (opcional)',
          maxLength: 40,
        ),
      ],
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).maybePop();
              _eliminarLinea(i);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.delete_outline, size: 15),
            label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
          ),
        ),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _aplicarLinea(i, opSel, _valorCtrl.text, _notaCtrl.text);
              Navigator.of(context).maybePop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.check, size: 15),
            label: const Text('Guardar', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  /// Diálogo de etiqueta para un subtotal (solo texto).
  Future<void> _editarNotaSubtotal(int i) async {
    final l = _lineas[i];
    _notaCtrl.text = l.notaSub ?? '';
    await StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.edit_note,
      titulo: 'Nota del subtotal',
      content: [
        CustomText(
          controller: _notaCtrl,
          hintText: 'Ej. subtotal muebles…',
          maxLength: 40,
          onSubmitted: (_) {
            _aplicarNotaLinea(i, _notaCtrl.text, sub: true);
            Navigator.of(context).maybePop();
          },
        ),
      ],
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).maybePop();
              _aplicarNotaLinea(i, '', sub: true);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.backspace_outlined, size: 15),
            label: const Text('Quitar', style: TextStyle(fontSize: 12)),
          ),
        ),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _aplicarNotaLinea(i, _notaCtrl.text, sub: true);
              Navigator.of(context).maybePop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.check, size: 15),
            label: const Text('Guardar', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  /// Selector de operador (+ − × ÷) para el editor de línea.
  Widget _selectorOp(String sel, void Function(String) onSel) {
    Color colorDe(String o) => o == '−'
        ? AppColors.red
        : (o == '+' ? AppColors.greendark : AppColors.blue1);
    return Row(
      children: ['+', '−', '×', '÷'].map((o) {
        final activo = sel == o;
        final c = colorDe(o);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSel(o),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activo
                      ? c.withValues(alpha: 0.14)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                  border: activo
                      ? Border.all(color: c.withValues(alpha: 0.55))
                      : null,
                ),
                child: Text(
                  o,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: activo ? c : AppColors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Reemplaza la línea [i] con nuevo operador/monto/nota (preserva
  /// esPct/esCorte/notaSub). Monto inválido → no cambia.
  void _aplicarLinea(int i, String op, String valorText, String notaText) {
    if (i < 0 || i >= _lineas.length) return;
    final v = double.tryParse(valorText);
    if (v == null) return;
    final old = _lineas[i];
    setState(() {
      _lineas[i] = _Linea(
        op: op,
        valor: v,
        esPct: old.esPct,
        esCorte: old.esCorte,
        nota: notaText.trim().isEmpty ? null : notaText.trim(),
        notaSub: old.notaSub,
      );
    });
    _guardarTape();
  }

  void _aplicarNotaLinea(int i, String texto, {bool sub = false}) {
    if (i < 0 || i >= _lineas.length) return;
    final t = texto.trim().isEmpty ? null : texto.trim();
    setState(() {
      if (sub) {
        _lineas[i].notaSub = t;
      } else {
        _lineas[i].nota = t;
      }
    });
    _guardarTape();
  }

  void _eliminarLinea(int i) {
    if (i < 0 || i >= _lineas.length) return;
    setState(() => _lineas.removeAt(i));
    _guardarTape();
    HapticFeedback.mediumImpact();
  }

  void _scrollTapeFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tapeCtrl.hasClients) {
        _tapeCtrl.animateTo(
          _tapeCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════
  //  MODO NORMAL (expresión con precedencia)
  // ════════════════════════════════════════════════════════════════════

  double? _evaluar(String s) {
    if (s.trim().isEmpty) return null;
    try {
      final tokens = _tokenizar(s);
      if (tokens.isEmpty) return null;
      final p = _Parser(tokens);
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
      } else if ('+-−×÷*/%()'.contains(c)) {
        out.add(c);
        i++;
      } else {
        throw const FormatException('token inválido');
      }
    }
    return out;
  }

  String get _ultimo => _expr.isEmpty ? '' : _expr[_expr.length - 1];
  bool _esOp(String c) => '+-−×÷'.contains(c);
  String _runNumeroFinal() =>
      RegExp(r'[0-9.]+$').firstMatch(_expr)?.group(0) ?? '';
  bool _tieneOperacion(String e) =>
      RegExp(r'[+×÷%()]').hasMatch(e) || e.lastIndexOf('−') > 0;

  void _digito(String d) {
    setState(() {
      if (_error) {
        _expr = '';
        _error = false;
      }
      if (_recienIgual) {
        _expr = '';
        _recienIgual = false;
      }
      if (_expr.length >= _maxLenExpr) return;
      if (_ultimo == ')' || _ultimo == '%') _expr += '×';
      _expr += d;
    });
  }

  void _punto() {
    setState(() {
      if (_error) {
        _expr = '';
        _error = false;
      }
      if (_recienIgual) {
        _expr = '';
        _recienIgual = false;
      }
      if (_expr.length >= _maxLenExpr) return;
      final run = _runNumeroFinal();
      if (run.contains('.')) return;
      _expr += run.isEmpty ? '0.' : '.';
    });
  }

  void _operador(String op) {
    setState(() {
      if (_error) {
        _expr = '';
        _error = false;
      }
      _recienIgual = false;
      if (_expr.isEmpty) {
        if (op == '−') _expr = '−';
        return;
      }
      if (_esOp(_ultimo)) {
        if (op == '−' && (_ultimo == '×' || _ultimo == '÷')) {
          _expr += op;
          return;
        }
        _expr = _expr.substring(0, _expr.length - 1) + op;
        return;
      }
      if (_ultimo == '(') {
        if (op == '−') _expr += op;
        return;
      }
      _expr += op;
    });
  }

  void _porcentaje() {
    setState(() {
      if (_error || _expr.isEmpty) return;
      if (_expr.length >= _maxLenExpr) return;
      if (RegExp(r'[0-9)%]').hasMatch(_ultimo)) {
        _recienIgual = false;
        _expr += '%';
      }
    });
  }

  void _parenAbre() {
    setState(() {
      if (_error) {
        _expr = '';
        _error = false;
      }
      if (_recienIgual) {
        _expr = '';
        _recienIgual = false;
      }
      if (_expr.length >= _maxLenExpr) return;
      if (RegExp(r'[0-9)%]').hasMatch(_ultimo)) {
        _expr += '×(';
      } else {
        _expr += '(';
      }
    });
  }

  void _parenCierra() {
    setState(() {
      if (_error) return;
      final abre = '('.allMatches(_expr).length;
      final cierra = ')'.allMatches(_expr).length;
      if (abre <= cierra) return;
      if (_expr.isEmpty || _esOp(_ultimo) || _ultimo == '(') return;
      _recienIgual = false;
      _expr += ')';
    });
  }

  void _borrar() {
    setState(() {
      if (_error) {
        _expr = '';
        _error = false;
        return;
      }
      _recienIgual = false;
      if (_expr.isNotEmpty) {
        _expr = _expr.substring(0, _expr.length - 1);
      }
    });
  }

  void _clear() {
    setState(() {
      _expr = '';
      _error = false;
      _recienIgual = false;
    });
  }

  void _igual() {
    final v = _evaluar(_expr);
    if (v == null) {
      setState(() => _error = _expr.isNotEmpty);
      return;
    }
    final res = _fmt(v);
    setState(() {
      if (_tieneOperacion(_expr)) {
        _historial.add(_Calculo(expr: _prettyExpr(_expr), resultado: res));
      }
      _expr = res;
      _recienIgual = true;
      _error = false;
    });
    _guardarHistorial();
    _scrollHistFinal();
    HapticFeedback.lightImpact();
  }

  void _igv(bool agregar) {
    final v = _evaluar(_expr.isEmpty ? '0' : _expr);
    if (v == null) {
      setState(() => _error = true);
      return;
    }
    final res = _fmt(agregar ? v * (1 + _igvRate) : v / (1 + _igvRate));
    setState(() {
      final label = '${_pretty(_fmt(v))} ${agregar ? '+' : '−'} IGV 18%';
      _historial.add(_Calculo(expr: label, resultado: res));
      _expr = res;
      _recienIgual = true;
      _error = false;
    });
    _guardarHistorial();
    _scrollHistFinal();
    HapticFeedback.lightImpact();
  }

  String? get _valorPlano {
    final v = _evaluar(_expr.isEmpty ? '0' : _expr);
    return v == null ? null : _fmt(v);
  }

  void _usarResultado(String resultado) {
    setState(() {
      _expr = resultado;
      _error = false;
      _recienIgual = true;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _editarNota(int i) async {
    final c = _historial[i];
    _notaCtrl.text = c.nota ?? '';
    await StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.edit_note,
      titulo: 'Nota del cálculo',
      content: [
        Text(
          '${c.expr} = ${_pretty(c.resultado)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.blue1,
          ),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _notaCtrl,
          hintText: 'Ej. alquiler, luz, sueldo Juan…',
          maxLength: 40,
          onSubmitted: (_) {
            _aplicarNota(i, _notaCtrl.text);
            Navigator.of(context).maybePop();
          },
        ),
      ],
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).maybePop();
              _usarResultado(c.resultado);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue1,
              side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.north_east, size: 15),
            label: const Text('Usar', style: TextStyle(fontSize: 12)),
          ),
        ),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _aplicarNota(i, _notaCtrl.text);
              Navigator.of(context).maybePop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.check, size: 15),
            label: const Text('Guardar', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  void _aplicarNota(int i, String texto) {
    if (i < 0 || i >= _historial.length) return;
    setState(
        () => _historial[i].nota = texto.trim().isEmpty ? null : texto.trim());
    _guardarHistorial();
  }

  void _scrollHistFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_histCtrl.hasClients) {
        _histCtrl.animateTo(
          _histCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Acciones compartidas (copiar / compartir / limpiar) ───────────────

  bool get _hayDatos {
    switch (_modo) {
      case _Modo.cinta:
        return _lineas.isNotEmpty;
      case _Modo.normal:
        return _historial.isNotEmpty;
      case _Modo.hoja:
        return false; // la Hoja tiene su propia barra de acciones
    }
  }

  String? get _valorParaCopiar {
    if (_modo == _Modo.hoja) return null;
    if (_modo == _Modo.cinta) {
      if (_lineas.isEmpty && _entrada.isEmpty) return null;
      final t = _entrada.isNotEmpty && _lineas.isEmpty
          ? double.tryParse(_entrada)
          : _totalCinta();
      return (t == null || t.isNaN) ? null : _fmt(t);
    }
    return _valorPlano;
  }

  void _copiar() {
    final v = _valorParaCopiar;
    if (v == null) return;
    Clipboard.setData(ClipboardData(text: v));
    HapticFeedback.selectionClick();
    setState(() => _copiado = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  void _compartir() {
    final buf = StringBuffer();
    if (_modo == _Modo.cinta) {
      if (_lineas.isEmpty) return;
      buf.writeln('Cinta');
      var run = 0.0;
      var idx = 0;
      for (final l in _lineas) {
        if (l.esCorte) {
          buf.writeln('──── nuevo bloque ────');
          run = 0;
          idx = 0;
          continue;
        }
        final v = l.esPct ? run * l.valor / 100 : l.valor;
        final signed = l.op == '−' ? -v : v;
        run = idx == 0 ? signed : _applyOp(run, v, l.op);
        // Línea de entrada (con su etiqueta).
        final notaE =
            (l.nota != null && l.nota!.isNotEmpty) ? '   ${l.nota}' : '';
        final val = l.esPct
            ? '${_fmt(l.valor)}% (${_money(signed)})'
            : _money(l.valor);
        buf.writeln('${l.op} $val$notaE');
        // Subtotal corriente (con su etiqueta), desde la 2ª línea del bloque.
        if (idx >= 1) {
          final notaS = (l.notaSub != null && l.notaSub!.isNotEmpty)
              ? '   ${l.notaSub}'
              : '';
          buf.writeln('   = ${_money(run)}$notaS');
        }
        idx++;
      }
      buf.writeln('──────────');
      buf.write('Total = ${_money(run)}');
    } else if (_historial.isNotEmpty) {
      buf.writeln('Cálculos');
      for (final c in _historial) {
        final prefijo =
            (c.nota != null && c.nota!.isNotEmpty) ? '${c.nota}: ' : '';
        buf.writeln('$prefijo${c.expr} = ${_pretty(c.resultado)}');
      }
    } else {
      final v = _valorPlano;
      if (v == null) return;
      buf.write('Resultado: ${_pretty(v)}');
    }
    Share.share(buf.toString().trim());
  }

  Future<void> _limpiar() async {
    final n = _modo == _Modo.cinta ? _lineas.length : _historial.length;
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: _modo == _Modo.cinta ? 'Limpiar cinta' : 'Limpiar historial',
      message:
          '¿Borrar las $n líneas? Esta acción no se puede deshacer.',
      confirmText: 'Limpiar',
      icon: Icons.delete_sweep_outlined,
    );
    if (ok != true || !mounted) return;
    setState(() {
      if (_modo == _Modo.cinta) {
        _lineas.clear();
        _entrada = '';
      } else {
        _historial.clear();
      }
    });
    _modo == _Modo.cinta ? _guardarTape() : _guardarHistorial();
    HapticFeedback.mediumImpact();
  }

  // ── Formato ───────────────────────────────────────────────────────────

  double _round2(double v) => (v * 100).roundToDouble() / 100;

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(8);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  String _pretty(String raw) {
    if (raw == 'Error') return raw;
    final neg = raw.startsWith('-') || raw.startsWith('−');
    final sinSigno = neg ? raw.substring(1) : raw;
    final partes = sinSigno.split('.');
    final entero = partes[0];
    final buf = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) buf.write(',');
      buf.write(entero[i]);
    }
    var out = buf.toString();
    if (partes.length > 1) out += '.${partes[1]}';
    return (neg ? '−' : '') + out;
  }

  String _prettyExpr(String s) =>
      s.replaceAllMapped(RegExp(r'\d+(\.\d*)?'), (m) => _pretty(m.group(0)!));

  /// Formato monetario para la cinta: 2 decimales fijos + separadores.
  String _money(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    final neg = v < 0;
    return (neg ? '−' : '') + _pretty(v.abs().toStringAsFixed(2));
  }

  // ════════════════════════════════════════════════════════════════════
  //  UI
  // ════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            children: [
              _grabHandle(),
              _header(),
              const SizedBox(height: 8),
              _toggleModo(),
              const SizedBox(height: 10),
              Expanded(
                child: switch (_modo) {
                  _Modo.cinta => _pantallaCinta(),
                  _Modo.normal => _pantalla(),
                  _Modo.hoja => const HojaCalculoView(),
                },
              ),
              if (_modo != _Modo.hoja) ...[
                const SizedBox(height: 10),
                _modo == _Modo.cinta ? _tecladoCinta() : _teclado(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header() {
    final hayCopiar = _valorParaCopiar != null;
    return Row(
      children: [
        const Icon(Icons.calculate_outlined, size: 18, color: AppColors.blue1),
        const SizedBox(width: 8),
        const Text(
          'Calculadora',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.blue1,
          ),
        ),
        const Spacer(),
        if (hayCopiar)
          _iconoHeader(
            _copiado ? Icons.check_rounded : Icons.copy_rounded,
            _copiado ? AppColors.green : AppColors.blueGrey,
            _copiar,
          ),
        if (_hayDatos || hayCopiar)
          _iconoHeader(Icons.ios_share, AppColors.blueGrey, _compartir),
        if (_hayDatos)
          _iconoHeader(Icons.delete_sweep_outlined,
              AppColors.red.withValues(alpha: 0.8), _limpiar),
        _iconoHeader(
            Icons.close, AppColors.grey, () => Navigator.of(context).maybePop()),
      ],
    );
  }

  Widget _iconoHeader(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  Widget _toggleModo() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _segmento('Cinta', Icons.receipt_long_outlined, _Modo.cinta),
          _segmento('Normal', Icons.calculate_outlined, _Modo.normal),
          _segmento('Hoja', Icons.grid_on_outlined, _Modo.hoja),
        ],
      ),
    );
  }

  Widget _segmento(String label, IconData icon, _Modo modo) {
    final activo = _modo == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () => _cambiarModo(modo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: activo ? AppColors.blue1 : AppColors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activo ? AppColors.blue1 : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pantalla CINTA ────────────────────────────────────────────────────

  Widget _pantallaCinta() {
    final total = _totalCinta();
    // Intercala entradas con subtotales corrientes (estilo CalcTape): el
    // subtotal se muestra desde la 2ª entrada en adelante.
    final items = <_ItemCinta>[];
    var run = 0.0;
    var idx = 0; // posición dentro del bloque actual
    for (var i = 0; i < _lineas.length; i++) {
      final l = _lineas[i];
      if (l.esCorte) {
        items.add(_ItemCinta.corte());
        run = 0;
        idx = 0;
        continue;
      }
      final v = l.esPct ? run * l.valor / 100 : l.valor;
      final signed = l.op == '−' ? -v : v;
      run = idx == 0 ? signed : _applyOp(run, v, l.op);
      items.add(_ItemCinta.entrada(i, l.esPct ? signed : null));
      if (idx >= 1) items.add(_ItemCinta.subtotal(run, i));
      idx++;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: _lineas.isEmpty
                ? Center(
                    child: Text(
                      'Escribe un número y toca  +  −  ×  ÷',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _tapeCtrl,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      if (it.esCorte) return _filaCorte();
                      return it.esSub
                          ? _filaSubtotal(it.val, it.idx)
                          : _filaEntrada(it.idx, it.pctSigned);
                    },
                  ),
          ),
          // Entrada activa (lo que se está escribiendo).
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
            child: Row(
              children: [
                Text(
                  _opPend,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _opPend == '−'
                        ? AppColors.red
                        : (_opPend == '+'
                            ? AppColors.greendark
                            : AppColors.blue1),
                  ),
                ),
                const Spacer(),
                Text(
                  _entrada.isEmpty ? '0' : _pretty(_entrada),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _entrada.isEmpty
                        ? AppColors.grey.withValues(alpha: 0.5)
                        : AppColors.blue1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFE4E8EE)),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _money(total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: total.isNaN ? AppColors.red : AppColors.blue1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Fila de una entrada del usuario. Si es %, muestra `18.00% | −19.08`.
  Widget _filaEntrada(int i, double? pctSigned) {
    final l = _lineas[i];
    final tieneNota = l.nota != null && l.nota!.isNotEmpty;
    final colorOp = l.op == '−'
        ? AppColors.red
        : (l.op == '+' ? AppColors.greendark : AppColors.blue1);
    return InkWell(
      onTap: () => _editarNotaLinea(i),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: Text(
                l.op,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorOp,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: tieneNota
                  ? Text(
                      l.nota!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.blue1,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.add_comment_outlined,
                          size: 12,
                          color: AppColors.grey.withValues(alpha: 0.4)),
                    ),
            ),
            const SizedBox(width: 8),
            if (l.esPct) ...[
              Text(
                '${_fmt(l.valor)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black87,
                ),
              ),
              Text('  |  ',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.grey.withValues(alpha: 0.7))),
              Text(
                _money(pctSigned ?? 0),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.red,
                ),
              ),
            ] else
              Text(
                _money(l.valor),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Subtotal corriente (calculado): divisor arriba + valor en azul.
  /// Tocable para etiquetar el subtotal ([i] = índice de la entrada previa).
  Widget _filaSubtotal(double val, int i) {
    final notaSub = (i >= 0 && i < _lineas.length) ? _lineas[i].notaSub : null;
    final tieneNota = notaSub != null && notaSub.isNotEmpty;
    return InkWell(
      onTap: () => _editarNotaLinea(i, sub: true),
      borderRadius: BorderRadius.circular(6),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 150,
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: const Color(0xFFCED4DC),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: tieneNota
                      ? Text(
                          notaSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.blue1,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.add_comment_outlined,
                              size: 12,
                              color: AppColors.blue1.withValues(alpha: 0.35)),
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  _money(val),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Separador de bloque (corte): el bloque siguiente parte de cero.
  Widget _filaCorte() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(
            child: Divider(height: 1, thickness: 1, color: Color(0xFFCBD3DE)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'nuevo bloque',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.grey.withValues(alpha: 0.9),
              ),
            ),
          ),
          const Expanded(
            child: Divider(height: 1, thickness: 1, color: Color(0xFFCBD3DE)),
          ),
        ],
      ),
    );
  }

  Widget _tecladoCinta() {
    return Column(
      children: [
        _fila([
          _tecla('+IGV', tipo: _TeclaTipo.igv, onTap: () => _cintaIgv(true)),
          _tecla('−IGV', tipo: _TeclaTipo.igv, onTap: () => _cintaIgv(false)),
          _botonBloque(),
        ]),
        _fila([
          _tecla('C', tipo: _TeclaTipo.funcion, onTap: _cintaClear),
          _tecla('⌫', tipo: _TeclaTipo.funcion, onTap: _cintaBorrar),
          _tecla('%', tipo: _TeclaTipo.funcion, onTap: _cintaPorcentaje),
          _tecla('÷', tipo: _TeclaTipo.operador, onTap: () => _cintaOperar('÷')),
        ]),
        _fila([
          _tecla('7', onTap: () => _cintaDigito('7')),
          _tecla('8', onTap: () => _cintaDigito('8')),
          _tecla('9', onTap: () => _cintaDigito('9')),
          _tecla('×', tipo: _TeclaTipo.operador, onTap: () => _cintaOperar('×')),
        ]),
        _fila([
          _tecla('4', onTap: () => _cintaDigito('4')),
          _tecla('5', onTap: () => _cintaDigito('5')),
          _tecla('6', onTap: () => _cintaDigito('6')),
          _tecla('−', tipo: _TeclaTipo.operador, onTap: () => _cintaOperar('−')),
        ]),
        _fila([
          _tecla('1', onTap: () => _cintaDigito('1')),
          _tecla('2', onTap: () => _cintaDigito('2')),
          _tecla('3', onTap: () => _cintaDigito('3')),
          _tecla('+', tipo: _TeclaTipo.operador, onTap: () => _cintaOperar('+')),
        ]),
        _fila([
          _tecla('0', flex: 2, onTap: () => _cintaDigito('0')),
          _tecla('.', onTap: _cintaDecimal),
          _tecla('=', tipo: _TeclaTipo.igual, onTap: _cintaIgual),
        ]),
      ],
    );
  }

  // ── Pantalla NORMAL ───────────────────────────────────────────────────

  Widget _pantalla() {
    final preview = _valorPlano;
    final mostrarPreview =
        !_error && !_recienIgual && preview != null && _tieneOperacion(_expr);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_historial.isNotEmpty) ...[
            Expanded(child: _cintaHistorial()),
            const Divider(height: 12, color: Color(0xFFE4E8EE)),
          ] else
            const Spacer(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _expr.isEmpty ? '0' : _prettyExpr(_expr),
              maxLines: 1,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: _error ? AppColors.red : AppColors.blue1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: _error
                ? const Text(
                    'Expresión no válida',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : mostrarPreview
                    ? Text(
                        '= ${_pretty(preview)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _cintaHistorial() {
    return ListView.builder(
        controller: _histCtrl,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: _historial.length,
        itemBuilder: (_, i) {
          final c = _historial[i];
          final tieneNota = c.nota != null && c.nota!.isNotEmpty;
          return InkWell(
            onTap: () => _editarNota(i),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: tieneNota
                        ? Row(
                            children: [
                              const Icon(Icons.sell_outlined,
                                  size: 12, color: AppColors.blue1),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  c.nota!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.blue1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(Icons.add_comment_outlined,
                                  size: 12,
                                  color: AppColors.grey.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                'nota',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.grey.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 7,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '${c.expr} =',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _pretty(c.resultado),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.blueGrey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
    );
  }

  Widget _teclado() {
    return Column(
      children: [
        _fila([
          _tecla('(', tipo: _TeclaTipo.funcion, onTap: _parenAbre),
          _tecla(')', tipo: _TeclaTipo.funcion, onTap: _parenCierra),
          _tecla('+IGV', tipo: _TeclaTipo.igv, onTap: () => _igv(true)),
          _tecla('−IGV', tipo: _TeclaTipo.igv, onTap: () => _igv(false)),
        ]),
        _fila([
          _tecla('C', tipo: _TeclaTipo.funcion, onTap: _clear),
          _tecla('⌫', tipo: _TeclaTipo.funcion, onTap: _borrar),
          _tecla('%', tipo: _TeclaTipo.funcion, onTap: _porcentaje),
          _tecla('÷', tipo: _TeclaTipo.operador, onTap: () => _operador('÷')),
        ]),
        _fila([
          _tecla('7', onTap: () => _digito('7')),
          _tecla('8', onTap: () => _digito('8')),
          _tecla('9', onTap: () => _digito('9')),
          _tecla('×', tipo: _TeclaTipo.operador, onTap: () => _operador('×')),
        ]),
        _fila([
          _tecla('4', onTap: () => _digito('4')),
          _tecla('5', onTap: () => _digito('5')),
          _tecla('6', onTap: () => _digito('6')),
          _tecla('−', tipo: _TeclaTipo.operador, onTap: () => _operador('−')),
        ]),
        _fila([
          _tecla('1', onTap: () => _digito('1')),
          _tecla('2', onTap: () => _digito('2')),
          _tecla('3', onTap: () => _digito('3')),
          _tecla('+', tipo: _TeclaTipo.operador, onTap: () => _operador('+')),
        ]),
        _fila([
          _tecla('0', flex: 2, onTap: () => _digito('0')),
          _tecla('.', onTap: _punto),
          _tecla('=', tipo: _TeclaTipo.igual, onTap: _igual),
        ]),
      ],
    );
  }

  Widget _fila(List<Widget> teclas) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: teclas),
    );
  }

  /// Botón "nuevo bloque" del modo cinta.
  Widget _botonBloque() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: AppColors.blue1.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              _cintaNuevoBloque();
            },
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.subdirectory_arrow_left,
                      size: 16, color: AppColors.blue1),
                  SizedBox(width: 4),
                  Text(
                    'Bloque',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tecla(
    String label, {
    required VoidCallback onTap,
    _TeclaTipo tipo = _TeclaTipo.digito,
    int flex = 1,
  }) {
    late final Color bg;
    late final Color fg;
    switch (tipo) {
      case _TeclaTipo.digito:
        bg = const Color(0xFFF5F7FA);
        fg = AppColors.black87;
        break;
      case _TeclaTipo.funcion:
        bg = const Color(0xFFEDEFF3);
        fg = label == 'C' ? AppColors.red : AppColors.blueGrey;
        break;
      case _TeclaTipo.operador:
        bg = AppColors.blue1.withValues(alpha: 0.10);
        fg = AppColors.blue1;
        break;
      case _TeclaTipo.igv:
        bg = AppColors.green.withValues(alpha: 0.12);
        fg = AppColors.greendark;
        break;
      case _TeclaTipo.igual:
        bg = AppColors.blue1;
        fg = Colors.white;
        break;
    }
    final esGrande = tipo == _TeclaTipo.operador || tipo == _TeclaTipo.igual;
    final esIgv = tipo == _TeclaTipo.igv;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: esIgv ? 13 : (esGrande ? 23 : 21),
                  fontWeight: esIgv ? FontWeight.w800 : FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TeclaTipo { digito, funcion, operador, igv, igual }

/// Un cálculo resuelto en el historial del modo NORMAL.
class _Calculo {
  final String expr;
  final String resultado;
  String? nota;

  _Calculo({required this.expr, required this.resultado, this.nota});
}

/// Una línea de la CINTA (modo CalcTape): operador + valor + nota opcional.
/// Si [esPct], [valor] es un PORCENTAJE (ej. 18) que se resuelve sobre el
/// total corriente anterior a la línea.
class _Linea {
  final String op;
  final double valor;
  final bool esPct;

  /// Corte de bloque: reinicia el acumulador. El nuevo bloque no toma en
  /// cuenta las líneas anteriores. [op]/[valor] se ignoran.
  final bool esCorte;

  /// Etiqueta de la línea de entrada.
  String? nota;

  /// Etiqueta del subtotal que aparece DESPUÉS de esta entrada.
  String? notaSub;

  _Linea({
    required this.op,
    required this.valor,
    this.esPct = false,
    this.esCorte = false,
    this.nota,
    this.notaSub,
  });
}

/// Ítem de render de la cinta: entrada del usuario, subtotal corriente
/// (calculado) o corte de bloque.
class _ItemCinta {
  final bool esSub;
  final bool esCorte;
  final int idx;
  final double val;
  final double? pctSigned;

  _ItemCinta.entrada(this.idx, this.pctSigned)
      : esSub = false,
        esCorte = false,
        val = 0;
  _ItemCinta.subtotal(this.val, this.idx)
      : esSub = true,
        esCorte = false,
        pctSigned = null;
  _ItemCinta.corte()
      : esSub = false,
        esCorte = true,
        idx = -1,
        val = 0,
        pctSigned = null;
}

/// Parser de descenso recursivo con precedencia (modo NORMAL):
///   expr    := term  (('+' | '−') term)*
///   term    := unary (('×' | '÷') unary)*
///   unary   := ('−' | '+') unary | postfix
///   postfix := primary ('%')*
///   primary := number | '(' expr ')'
class _Parser {
  final List<String> t;
  int pos = 0;

  _Parser(this.t);

  bool get atEnd => pos >= t.length;
  String? get _cur => atEnd ? null : t[pos];

  double parseExpr() {
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
    final d = double.tryParse(c);
    if (d == null) throw FormatException('número inválido: $c');
    pos++;
    return d;
  }
}
