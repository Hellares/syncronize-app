import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/mini_formula_eval.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';

/// Mini hoja de cálculo (tab "Hoja"). Tabla estructurada: 1ª columna de texto
/// + N columnas numéricas o de FÓRMULA (letras A, B, C…). Funciones/SI, footer
/// configurable por columna, formato, ancho redimensionable, columna fija,
/// reordenar columnas (remapea fórmulas), duplicar/insertar filas, compartir
/// texto o pantallazo PNG. Persiste en SharedPreferences.
///
/// Nota: TextField liviano por celda (no CustomText) por rendimiento.
class HojaCalculoView extends StatefulWidget {
  const HojaCalculoView({super.key});

  @override
  State<HojaCalculoView> createState() => _HojaCalculoViewState();
}

class _HojaCalculoViewState extends State<HojaCalculoView> {
  static const String _prefsKey = 'calculadora_hoja';
  static const double _wIndex = 30;
  static const double _rowH = 32;
  static const Color _linea = Color(0xFFDCE1E8);

  final GlobalKey _capKey = GlobalKey();
  final ScrollController _vCtrl = ScrollController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _formulaCtrl = TextEditingController();

  String _colTexto = 'Detalle';
  double _anchoTexto = 150;
  List<_Columna> _columnas = [];
  final List<_FilaHoja> _filas = [];

  bool _cargado = false;
  bool _capturando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.dispose();
    }
    _vCtrl.dispose();
    _nombreCtrl.dispose();
    _formulaCtrl.dispose();
    super.dispose();
  }

  int get _nCols => _columnas.length;
  String _letra(int i) => String.fromCharCode(65 + i);

  // ── Persistencia ──────────────────────────────────────────────────────

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _colTexto = (data['ct'] as String?) ?? 'Detalle';
        _anchoTexto = (data['wt'] as num?)?.toDouble() ?? 150;
        _columnas = (data['cols'] as List).map((e) {
          if (e is String) return _Columna(nombre: e);
          final m = e as Map;
          return _Columna(
            nombre: m['n'] as String,
            esFormula: m['f'] == true,
            formula: (m['fo'] as String?) ?? '',
            formato: (m['ft'] as String?) ?? 'num',
            decimales: (m['dc'] as int?) ?? 2,
            ancho: (m['w'] as num?)?.toDouble() ?? 92,
            footer: (m['ff'] as String?) ?? 'suma',
          );
        }).toList();
        if (data['tot'] == true &&
            !_columnas.any((c) => c.esFormula) &&
            _columnas.length >= 2) {
          _columnas
              .add(_Columna(nombre: 'Total', esFormula: true, formula: 'A*B'));
        }
        final filas = (data['filas'] as List)
            .map((e) => _FilaHoja(
                  (e['t'] as String?) ?? '',
                  (e['c'] as List).map((x) => x as String).toList(),
                ))
            .toList();
        for (final f in _filas) {
          f.dispose();
        }
        _filas
          ..clear()
          ..addAll(filas);
      }
    } catch (_) {
      // Datos corruptos → plantilla.
    }
    if (_columnas.isEmpty) _aplicarPlantilla();
    for (final f in _filas) {
      f.ajustar(_nCols);
    }
    if (_filas.isEmpty) _filas.add(_FilaHoja('', List.filled(_nCols, '')));
    if (mounted) setState(() => _cargado = true);
  }

  Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'ct': _colTexto,
        'wt': _anchoTexto,
        'cols': _columnas
            .map((c) => {
                  'n': c.nombre,
                  'f': c.esFormula,
                  'fo': c.formula,
                  'ft': c.formato,
                  'dc': c.decimales,
                  'w': c.ancho,
                  'ff': c.footer,
                })
            .toList(),
        'filas': _filas
            .map((f) => {
                  't': f.texto.text,
                  'c': f.celdas.map((c) => c.text).toList(),
                })
            .toList(),
      };
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (_) {}
  }

  /// Plantilla de ejemplo (cotización). Reemplaza filas/columnas.
  void _aplicarPlantilla() {
    for (final f in _filas) {
      f.dispose();
    }
    _filas.clear();
    _colTexto = 'Producto';
    _columnas = [
      _Columna(nombre: 'Cant'),
      _Columna(nombre: 'P. Unit', formato: 'sol'),
      _Columna(nombre: 'Subtotal', esFormula: true, formula: 'A*B', formato: 'sol'),
      _Columna(nombre: 'IGV', esFormula: true, formula: 'C*18%', formato: 'sol'),
      _Columna(nombre: 'Total', esFormula: true, formula: 'C+D', formato: 'sol'),
    ];
    _filas
      ..add(_FilaHoja('Foco LED', ['3', '12', '', '', '']))
      ..add(_FilaHoja('Cable 2m', ['10', '5.5', '', '', '']));
  }

  // ── Cálculos ──────────────────────────────────────────────────────────

  double _num(String s) => double.tryParse(s.trim()) ?? 0;

  double _valorColumna(_FilaHoja f, int j, [Set<int>? visit]) {
    final col = _columnas[j];
    if (!col.esFormula) return _num(f.celdas[j].text);
    final v = visit ?? <int>{};
    if (v.contains(j)) return 0;
    v.add(j);
    final vars = <String, double>{};
    for (var k = 0; k < _nCols; k++) {
      vars[_letra(k)] = _valorColumna(f, k, v);
    }
    final r = evaluarFormula(
      col.formula,
      vars: vars,
      columna: (letra) {
        final k = letra.codeUnitAt(0) - 65;
        if (k < 0 || k >= _nCols) return const <double>[];
        return [for (final g in _filas) _valorColumna(g, k, v)];
      },
    );
    v.remove(j);
    return r ?? 0;
  }

  /// Texto del pie de la columna [j] según su función (suma/prom/…).
  String _footerTexto(int j) {
    final col = _columnas[j];
    if (col.footer == 'ninguno') return '';
    if (col.footer == 'cuenta') {
      final n = col.esFormula
          ? _filas.length
          : _filas.where((f) => f.celdas[j].text.trim().isNotEmpty).length;
      return '# $n';
    }
    final vals = [for (final f in _filas) _valorColumna(f, j)];
    if (vals.isEmpty) return '';
    late double v;
    var pref = '';
    switch (col.footer) {
      case 'prom':
        v = vals.reduce((a, b) => a + b) / vals.length;
        pref = '∅ ';
        break;
      case 'min':
        v = vals.reduce(math.min);
        pref = '↓ ';
        break;
      case 'max':
        v = vals.reduce(math.max);
        pref = '↑ ';
        break;
      default:
        v = vals.reduce((a, b) => a + b);
        break;
    }
    return '$pref${_fmtCol(v, col)}';
  }

  // ── Formato ───────────────────────────────────────────────────────────

  String _numFmt(double v, int dec) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(dec);
    final p = s.split('.');
    final buf = StringBuffer();
    for (var i = 0; i < p[0].length; i++) {
      if (i > 0 && (p[0].length - i) % 3 == 0) buf.write(',');
      buf.write(p[0][i]);
    }
    return '${neg ? '−' : ''}${buf.toString()}${p.length > 1 ? '.${p[1]}' : ''}';
  }

  String _fmtCol(double v, _Columna col) {
    switch (col.formato) {
      case 'pct':
        return '${_numFmt(v * 100, col.decimales)}%';
      case 'sol':
        return 'S/ ${_numFmt(v, col.decimales)}';
      default:
        return _numFmt(v, col.decimales);
    }
  }

  // ── Filas ─────────────────────────────────────────────────────────────

  void _agregarFila() {
    setState(() => _filas.add(_FilaHoja('', List.filled(_nCols, ''))));
    _guardar();
    HapticFeedback.selectionClick();
  }

  void _insertarFila(int pos) {
    setState(() => _filas.insert(pos, _FilaHoja('', List.filled(_nCols, ''))));
    _guardar();
    HapticFeedback.selectionClick();
  }

  void _duplicarFila(int i) {
    final o = _filas[i];
    final copia = _FilaHoja(o.texto.text, [for (final c in o.celdas) c.text]);
    setState(() => _filas.insert(i + 1, copia));
    _guardar();
    HapticFeedback.selectionClick();
  }

  Future<void> _eliminarFila(int i) async {
    if (_filas.length <= 1) {
      setState(() => _filas[i].limpiar());
      _guardar();
      return;
    }
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Eliminar fila',
      message: '¿Eliminar esta fila?',
      confirmText: 'Eliminar',
    );
    if (ok != true || !mounted) return;
    setState(() {
      _filas[i].dispose();
      _filas.removeAt(i);
    });
    _guardar();
  }

  void _accionFila(int i, String acc) {
    switch (acc) {
      case 'ins_arriba':
        _insertarFila(i);
        break;
      case 'ins_abajo':
        _insertarFila(i + 1);
        break;
      case 'dup':
        _duplicarFila(i);
        break;
      case 'del':
        _eliminarFila(i);
        break;
    }
  }

  // ── Columnas ──────────────────────────────────────────────────────────

  Future<void> _dialogoColumna({int? idx}) async {
    final editar = idx != null;
    final col = editar ? _columnas[idx] : null;
    _nombreCtrl.text = col?.nombre ?? '';
    _formulaCtrl.text = col?.formula ?? '';
    var esFormula = col?.esFormula ?? false;
    var formato = col?.formato ?? 'num';
    var decimales = col?.decimales ?? 2;
    var footer = col?.footer ?? 'suma';
    final propioIdx = idx ?? _nCols;

    await StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.view_column_outlined,
      titulo: editar ? 'Editar columna' : 'Nueva columna',
      content: [
        if (editar)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                _btnMover(Icons.chevron_left, 'Mover izq.',
                    idx > 0 ? () => _moverDesdeDialogo(idx, idx - 1) : null),
                const SizedBox(width: 8),
                _btnMover(Icons.chevron_right, 'Mover der.',
                    idx < _nCols - 1
                        ? () => _moverDesdeDialogo(idx, idx + 1)
                        : null),
              ],
            ),
          ),
        CustomText(controller: _nombreCtrl, hintText: 'Nombre', maxLength: 14),
        const SizedBox(height: 12),
        StatefulBuilder(
          builder: (_, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _selectorTipo(esFormula, (f) => setLocal(() => esFormula = f)),
                if (esFormula) ...[
                  const SizedBox(height: 12),
                  CustomText(
                    controller: _formulaCtrl,
                    hintText:
                        'Ej. A*B · SI(B>=10; A*0.9; A) · REDONDEAR(A/C; 2)',
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 8),
                  _chipsFormula(propioIdx, () => setLocal(() {})),
                  _preview(formato, decimales),
                ],
                const SizedBox(height: 14),
                _label('Formato'),
                const SizedBox(height: 6),
                _selectorFormato(formato, (v) => setLocal(() => formato = v)),
                const SizedBox(height: 10),
                _selectorDecimales(
                    decimales, (d) => setLocal(() => decimales = d)),
                const SizedBox(height: 14),
                _label('Pie (fila TOTAL)'),
                const SizedBox(height: 6),
                _selectorFooter(footer, (v) => setLocal(() => footer = v)),
              ],
            );
          },
        ),
      ],
      actions: [
        if (editar)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _nCols <= 1
                  ? null
                  : () {
                      Navigator.of(context).maybePop();
                      _eliminarColumna(idx);
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
              _guardarColumna(idx, esFormula, formato, decimales, footer);
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

  Widget _btnMover(IconData icon, String label, VoidCallback? onTap) {
    final on = onTap != null;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: on ? AppColors.blue1 : AppColors.greyLight,
          side: BorderSide(
              color: (on ? AppColors.blue1 : AppColors.greyLight)
                  .withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  void _moverDesdeDialogo(int from, int to) {
    Navigator.of(context).maybePop();
    _moverColumna(from, to);
  }

  /// Mueve la columna [from] a [to] y REMAPEA las letras en todas las
  /// fórmulas para que sigan apuntando a las mismas columnas.
  void _moverColumna(int from, int to) {
    if (to < 0 || to >= _nCols || from == to) return;
    final orden = List.generate(_nCols, (i) => i);
    final m = orden.removeAt(from);
    orden.insert(to, m);
    final oldToNew = <int, int>{};
    for (var ni = 0; ni < orden.length; ni++) {
      oldToNew[orden[ni]] = ni;
    }
    final nuevas = [for (final oi in orden) _columnas[oi]];
    for (final c in nuevas) {
      if (c.esFormula) c.formula = _remapFormula(c.formula, oldToNew);
    }
    setState(() {
      _columnas = nuevas;
      for (final f in _filas) {
        final nc = [for (final oi in orden) f.celdas[oi]];
        f.celdas
          ..clear()
          ..addAll(nc);
      }
    });
    _guardar();
    HapticFeedback.selectionClick();
  }

  String _remapFormula(String f, Map<int, int> oldToNew) {
    return f.replaceAllMapped(RegExp(r'[A-Za-z]+'), (m) {
      final id = m.group(0)!;
      if (id.length == 1) {
        final oi = id.toUpperCase().codeUnitAt(0) - 65;
        final ni = oldToNew[oi];
        return ni != null ? String.fromCharCode(65 + ni) : id;
      }
      return id; // función → intacta
    });
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey));

  Map<String, double> _sampleVars() {
    final vars = <String, double>{};
    final f = _filas.isNotEmpty ? _filas.first : null;
    for (var k = 0; k < _nCols; k++) {
      vars[_letra(k)] = f != null ? _valorColumna(f, k) : 1.0;
    }
    return vars;
  }

  List<double> Function(String) _previewResolver() => (letra) {
        final k = letra.codeUnitAt(0) - 65;
        if (k < 0 || k >= _nCols) return const <double>[];
        return [for (final g in _filas) _valorColumna(g, k)];
      };

  Widget _preview(String formato, int decimales) {
    final txt = _formulaCtrl.text.trim();
    if (txt.isEmpty) return const SizedBox.shrink();
    final r =
        evaluarFormula(txt, vars: _sampleVars(), columna: _previewResolver());
    final invalido = r == null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(invalido ? Icons.error_outline : Icons.check_circle_outline,
              size: 14, color: invalido ? AppColors.red : AppColors.greendark),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              invalido
                  ? 'Fórmula inválida'
                  : 'ejemplo (fila 1): ${_fmtCol(r, _Columna(nombre: '', formato: formato, decimales: decimales))}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: invalido ? AppColors.red : AppColors.greendark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorTipo(bool esFormula, void Function(bool) onSel) {
    Widget seg(String label, IconData icon, bool valor) {
      final activo = esFormula == valor;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSel(valor),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: activo
                  ? AppColors.blue1.withValues(alpha: 0.12)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: activo
                  ? Border.all(color: AppColors.blue1.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 14, color: activo ? AppColors.blue1 : AppColors.grey),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activo ? AppColors.blue1 : AppColors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(children: [
      seg('Numérica', Icons.pin_outlined, false),
      seg('Fórmula', Icons.functions, true),
    ]);
  }

  Widget _chipsFormula(int propioIdx, VoidCallback onInsert) {
    final chips = <Widget>[];
    void addChip(String texto, {Color? color, String? insertar}) {
      chips.add(InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          _formulaCtrl.text += insertar ?? texto;
          _formulaCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _formulaCtrl.text.length));
          onInsert();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: (color ?? AppColors.blue1).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(texto,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.blue1)),
        ),
      ));
    }

    for (var k = 0; k < _nCols; k++) {
      if (k == propioIdx) continue;
      addChip('${_letra(k)} · ${_columnas[k].nombre}',
          color: AppColors.greendark, insertar: _letra(k));
    }
    for (final op in ['+', '−', '×', '÷', '(', ')', '%']) {
      addChip(op);
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _selectorFormato(String sel, void Function(String) onSel) {
    Widget seg(String label, String valor) {
      final activo = sel == valor;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSel(valor),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: activo
                  ? AppColors.blue1.withValues(alpha: 0.12)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: activo
                  ? Border.all(color: AppColors.blue1.withValues(alpha: 0.5))
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activo ? AppColors.blue1 : AppColors.grey)),
          ),
        ),
      );
    }

    return Row(children: [
      seg('Número', 'num'),
      seg('%', 'pct'),
      seg('S/', 'sol'),
    ]);
  }

  Widget _selectorDecimales(int dec, void Function(int) onSel) {
    Widget btn(IconData icon, VoidCallback onTap, bool enabled) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 16, color: enabled ? AppColors.blue1 : AppColors.greyLight),
        ),
      );
    }

    return Row(children: [
      _label('Decimales'),
      const Spacer(),
      btn(Icons.remove, () => onSel(dec - 1), dec > 0),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('$dec',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.blue1)),
      ),
      btn(Icons.add, () => onSel(dec + 1), dec < 4),
    ]);
  }

  Widget _selectorFooter(String sel, void Function(String) onSel) {
    const ops = {
      'suma': 'Suma',
      'prom': 'Prom',
      'cuenta': 'Cuenta',
      'min': 'Mín',
      'max': 'Máx',
      'ninguno': 'Ninguno',
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ops.entries.map((e) {
        final activo = sel == e.key;
        return GestureDetector(
          onTap: () => onSel(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: activo
                  ? AppColors.blue1.withValues(alpha: 0.12)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: activo
                  ? Border.all(color: AppColors.blue1.withValues(alpha: 0.5))
                  : null,
            ),
            child: Text(e.value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activo ? AppColors.blue1 : AppColors.grey)),
          ),
        );
      }).toList(),
    );
  }

  void _guardarColumna(
      int? idx, bool esFormula, String formato, int decimales, String footer) {
    final nombre = _nombreCtrl.text.trim();
    final formula = _formulaCtrl.text.trim();
    setState(() {
      final col = _Columna(
        nombre: nombre.isEmpty ? 'Col ${(idx ?? _nCols) + 1}' : nombre,
        esFormula: esFormula,
        formula: formula,
        formato: formato,
        decimales: decimales,
        footer: footer,
        ancho: idx != null ? _columnas[idx].ancho : 92,
      );
      if (idx == null) {
        _columnas.add(col);
        for (final f in _filas) {
          f.celdas.add(TextEditingController());
        }
      } else {
        _columnas[idx] = col;
      }
    });
    _guardar();
  }

  void _eliminarColumna(int j) {
    setState(() {
      _columnas.removeAt(j);
      for (final f in _filas) {
        if (j < f.celdas.length) {
          f.celdas[j].dispose();
          f.celdas.removeAt(j);
        }
      }
    });
    _guardar();
  }

  Future<void> _editarColTexto() async {
    _nombreCtrl.text = _colTexto;
    await StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.edit_outlined,
      titulo: 'Nombre de la columna',
      content: [
        CustomText(
            controller: _nombreCtrl,
            hintText: 'Ej. Producto, Detalle…',
            maxLength: 14),
      ],
      actions: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final t = _nombreCtrl.text.trim();
              setState(() => _colTexto = t.isEmpty ? 'Detalle' : t);
              _guardar();
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

  Future<void> _restablecer() async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Restablecer hoja',
      message:
          'Se borrará todo (filas y columnas) y volverá a la plantilla de ejemplo. ¿Continuar?',
      confirmText: 'Restablecer',
      icon: Icons.restart_alt,
    );
    if (ok != true || !mounted) return;
    setState(_aplicarPlantilla);
    _guardar();
    HapticFeedback.mediumImpact();
  }

  // ── Compartir ─────────────────────────────────────────────────────────

  void _compartirTexto() {
    final buf = StringBuffer();
    buf.writeln([_colTexto, ..._columnas.map((c) => c.nombre)].join('\t'));
    for (final f in _filas) {
      buf.writeln([
        f.texto.text,
        for (var j = 0; j < _nCols; j++)
          _columnas[j].esFormula
              ? _fmtCol(_valorColumna(f, j), _columnas[j])
              : f.celdas[j].text,
      ].join('\t'));
    }
    buf.writeln([
      'TOTAL',
      for (var j = 0; j < _nCols; j++) _footerTexto(j),
    ].join('\t'));
    Share.share(buf.toString().trim());
  }

  Future<void> _pantallazo() async {
    setState(() => _capturando = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _capKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/hoja_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar la imagen')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_cargado) {
      return const Center(
        child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            _toolbar(),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: _display(),
              ),
            ),
          ],
        ),
        // Capa OFF-SCREEN para el pantallazo: tabla completa (sin scroll,
        // sin columna fija) con tamaño exacto para capturar todo aunque no
        // esté a la vista.
        if (_capturando)
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(-40000, -40000),
              child: RepaintBoundary(
                key: _capKey,
                // +2 en cada eje por el borde de 1px del Container (inserta
                // padding a cada lado) — evita overflow de 2px.
                child: SizedBox(
                  width: _anchoTotal() + 2,
                  height: _altoTotal() + 2,
                  child: _tablaUnificada(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _btnTool(Icons.add, 'Fila', _agregarFila),
          const SizedBox(width: 6),
          _btnTool(
              Icons.view_column_outlined, 'Columna', () => _dialogoColumna()),
          const SizedBox(width: 6),
          _btnIcono(
              Icons.text_snippet_outlined, _compartirTexto, 'Compartir texto'),
          _btnIcono(Icons.image_outlined, _pantallazo, 'Pantallazo'),
          const SizedBox(width: 6),
          _btnTool(Icons.restart_alt, 'Restablecer', _restablecer,
              color: AppColors.red),
        ],
      ),
    );
  }

  Widget _btnTool(IconData icon, String label, VoidCallback onTap,
      {Color color = AppColors.blue1}) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btnIcono(IconData icon, VoidCallback onTap, String tooltip,
      {Color color = AppColors.blueGrey}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  // ── Tabla (columna fija + bloque scrolleable) ─────────────────────────

  /// Vista interactiva: la columna de índice + texto queda FIJA a la
  /// izquierda; las columnas de datos se desplazan horizontalmente. Ambas
  /// comparten el scroll vertical.
  Widget _display() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: _linea)),
      child: SingleChildScrollView(
        controller: _vCtrl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bloqueFijo(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _bloqueScroll(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bloqueFijo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hdrFija(),
        for (var i = 0; i < _filas.length; i++) _rowFija(i),
        _totFija(),
      ],
    );
  }

  Widget _bloqueScroll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hdrScroll(),
        for (var i = 0; i < _filas.length; i++) _rowScroll(i),
        _totScroll(),
      ],
    );
  }

  /// Ancho/alto totales de la tabla para dimensionar la captura.
  double _anchoTotal() =>
      _wIndex +
      _anchoTexto +
      _columnas.fold(0.0, (a, c) => a + c.ancho);

  double _altoTotal() => 44 + (_filas.length + 1) * _rowH;

  /// Tabla COMPLETA (sin fijar/scroll) para el pantallazo, con celdas de
  /// solo lectura (evita compartir controllers con la vista editable).
  Widget _tablaUnificada() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: _linea)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [_hdrFija(), _hdrScroll()]),
          for (var i = 0; i < _filas.length; i++)
            Row(children: [_rowFija(i, cap: true), _rowScroll(i, cap: true)]),
          Row(children: [_totFija(), _totScroll()]),
        ],
      ),
    );
  }

  // Encabezados
  Widget _hdrFija() {
    return Row(children: [
      _celdaHeaderTexto('#', _wIndex, centrado: true),
      _celdaHeaderTexto(_colTexto, _anchoTexto,
          onTap: _editarColTexto,
          onResize: (dx) =>
              setState(() => _anchoTexto = (_anchoTexto + dx).clamp(70, 340))),
    ]);
  }

  Widget _hdrScroll() {
    return Row(children: [
      for (var j = 0; j < _nCols; j++) _celdaHeaderCol(j),
    ]);
  }

  Widget _dragHandle(void Function(double) onResize) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => onResize(d.delta.dx),
        onHorizontalDragEnd: (_) => _guardar(),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: SizedBox(
            width: 16,
            child: Center(
                child: Container(
                    width: 1.5,
                    height: 22,
                    color: Colors.white.withValues(alpha: 0.4))),
          ),
        ),
      ),
    );
  }

  Widget _celdaHeaderTexto(String texto, double w,
      {bool centrado = false,
      VoidCallback? onTap,
      void Function(double)? onResize}) {
    return SizedBox(
      width: w,
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: onTap,
              child: Container(
                alignment: centrado ? Alignment.center : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                    color: AppColors.blue1,
                    border:
                        Border(right: BorderSide(color: Color(0x33FFFFFF)))),
                child: Text(texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
          if (onResize != null) _dragHandle(onResize),
        ],
      ),
    );
  }

  Widget _celdaHeaderCol(int j) {
    final col = _columnas[j];
    final superior = col.esFormula ? '=${col.formula}' : _letra(j);
    return SizedBox(
      width: col.ancho,
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => _dialogoColumna(idx: j),
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                    color: AppColors.blue1,
                    border:
                        Border(right: BorderSide(color: Color(0x33FFFFFF)))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(superior,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: col.esFormula
                                ? const Color(0xFFB9E6C4)
                                : Colors.white.withValues(alpha: 0.6))),
                    Text(col.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          _dragHandle((dx) =>
              setState(() => col.ancho = (col.ancho + dx).clamp(56, 340))),
        ],
      ),
    );
  }

  // Filas de datos
  Widget _rowFija(int i, {bool cap = false}) {
    final f = _filas[i];
    final par = i.isEven;
    return Container(
      color: par ? Colors.white : const Color(0xFFF7F9FC),
      child: Row(children: [
        _celdaIndice(i, cap: cap),
        _celdaTexto(f.texto, _anchoTexto, cap: cap),
      ]),
    );
  }

  Widget _rowScroll(int i, {bool cap = false}) {
    final f = _filas[i];
    final par = i.isEven;
    return Container(
      color: par ? Colors.white : const Color(0xFFF7F9FC),
      child: Row(children: [
        for (var j = 0; j < _nCols; j++)
          _columnas[j].esFormula
              ? _celdaFormula(f, j)
              : _celdaInput(f.celdas[j], _columnas[j].ancho, cap: cap),
      ]),
    );
  }

  Widget _celdaIndice(int i, {bool cap = false}) {
    final contenido = Container(
      width: _wIndex,
      height: _rowH,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
            right: BorderSide(color: _linea),
            bottom: BorderSide(color: _linea)),
      ),
      child: Text('${i + 1}',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.grey)),
    );
    if (cap) return contenido;
    return PopupMenuButton<String>(
      tooltip: '',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (v) => _accionFila(i, v),
      itemBuilder: (_) => [
        _menuItem('ins_arriba', Icons.arrow_upward, 'Insertar arriba'),
        _menuItem('ins_abajo', Icons.arrow_downward, 'Insertar abajo'),
        _menuItem('dup', Icons.copy_all_outlined, 'Duplicar'),
        _menuItem('del', Icons.delete_outline, 'Eliminar', color: AppColors.red),
      ],
      child: contenido,
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {Color color = AppColors.black87}) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ]),
    );
  }

  Widget _celdaTexto(TextEditingController ctrl, double width,
      {bool cap = false}) {
    return Container(
      width: width,
      height: _rowH,
      decoration: const BoxDecoration(
        border: Border(
            right: BorderSide(color: _linea),
            bottom: BorderSide(color: _linea)),
      ),
      alignment: cap ? Alignment.centerLeft : null,
      padding: cap ? const EdgeInsets.symmetric(horizontal: 8) : null,
      child: cap
          ? Text(ctrl.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.black87))
          : TextField(
              controller: ctrl,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (_) {
                setState(() {});
                _guardar();
              },
              style: const TextStyle(fontSize: 11, color: AppColors.black87),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.blue1, width: 0.6),
                ),
              ),
            ),
    );
  }

  Widget _celdaInput(TextEditingController ctrl, double width,
      {bool cap = false}) {
    return Container(
      width: width,
      height: _rowH,
      decoration: const BoxDecoration(
        border: Border(
            right: BorderSide(color: _linea),
            bottom: BorderSide(color: _linea)),
      ),
      alignment: cap ? Alignment.centerRight : null,
      padding: cap ? const EdgeInsets.symmetric(horizontal: 8) : null,
      child: cap
          ? Text(ctrl.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.black87))
          : TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (_) {
                setState(() {});
                _guardar();
              },
              style: const TextStyle(fontSize: 11, color: AppColors.black87),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.blue1, width: 0.6),
                ),
              ),
            ),
    );
  }

  Widget _celdaFormula(_FilaHoja f, int j) {
    return InkWell(
      onTap: () => _dialogoColumna(idx: j),
      child: Container(
        width: _columnas[j].ancho,
        height: _rowH,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: Color(0x0A2B7A2B),
          border: Border(
              right: BorderSide(color: _linea),
              bottom: BorderSide(color: _linea)),
        ),
        child: Text(
          _fmtCol(_valorColumna(f, j), _columnas[j]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.greendark),
        ),
      ),
    );
  }

  // Fila TOTAL
  Widget _totFija() {
    return Container(
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(children: [
        const SizedBox(width: _wIndex, height: _rowH),
        Container(
          width: _anchoTexto,
          height: _rowH,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Text('TOTAL',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue1)),
        ),
      ]),
    );
  }

  Widget _totScroll() {
    return Container(
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(children: [
        for (var j = 0; j < _nCols; j++)
          Container(
            width: _columnas[j].ancho,
            height: _rowH,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _footerTexto(j),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _columnas[j].esFormula
                      ? AppColors.greendark
                      : AppColors.blue1),
            ),
          ),
      ]),
    );
  }
}

/// Definición de una columna. [footer]: suma/prom/cuenta/min/max/ninguno.
class _Columna {
  String nombre;
  bool esFormula;
  String formula;
  String formato;
  int decimales;
  double ancho;
  String footer;

  _Columna({
    required this.nombre,
    this.esFormula = false,
    this.formula = '',
    this.formato = 'num',
    this.decimales = 2,
    this.ancho = 92,
    this.footer = 'suma',
  });
}

/// Una fila: controller de texto + controllers por columna.
class _FilaHoja {
  final TextEditingController texto;
  final List<TextEditingController> celdas;

  _FilaHoja(String t, List<String> vals)
      : texto = TextEditingController(text: t),
        celdas = vals.map((v) => TextEditingController(text: v)).toList();

  void ajustar(int n) {
    while (celdas.length < n) {
      celdas.add(TextEditingController());
    }
    while (celdas.length > n) {
      celdas.removeLast().dispose();
    }
  }

  void limpiar() {
    texto.clear();
    for (final c in celdas) {
      c.clear();
    }
  }

  void dispose() {
    texto.dispose();
    for (final c in celdas) {
      c.dispose();
    }
  }
}
