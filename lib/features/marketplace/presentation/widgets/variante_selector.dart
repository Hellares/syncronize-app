import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Selector de variantes híbrido:
/// - **B (atributos)**: si todas las variantes comparten el mismo conjunto de
///   atributos (Color, Tamaño…), muestra un selector por eje ("Color: [Negro]
///   [Blanco]") y deshabilita las opciones sin stock según lo ya elegido.
/// - **A (fallback)**: si las variantes no tienen atributos consistentes, cae a
///   chips por nombre de variante.
///
/// Notifica al padre la variante elegida (o `null` si aún no está completa) vía
/// [onChanged].
class VarianteSelector extends StatefulWidget {
  final List<dynamic> variantes;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const VarianteSelector({
    super.key,
    required this.variantes,
    required this.onChanged,
  });

  @override
  State<VarianteSelector> createState() => _VarianteSelectorState();
}

class _VarianteSelectorState extends State<VarianteSelector> {
  /// Selección por eje (modo B): { 'Color': 'Negro', 'Tamaño': 'M' }.
  final Map<String, String> _sel = {};

  /// Variante elegida directamente (modo A).
  String? _selId;

  late final List<Map<String, dynamic>> _variantes =
      widget.variantes.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ── Derivación de ejes (modo B) ────────────────────────────────────────────
  Map<String, String> _attrs(Map<String, dynamic> v) {
    final out = <String, String>{};
    for (final a in (v['atributos'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(a as Map);
      final n = m['nombre']?.toString();
      final val = m['valor']?.toString();
      if (n != null && n.isNotEmpty && val != null) out[n] = val;
    }
    return out;
  }

  late final List<String> _ejes = _calcularEjes();

  List<String> _calcularEjes() {
    if (_variantes.isEmpty) return [];
    final sets = _variantes.map((v) => _attrs(v).keys.toSet()).toList();
    final first = sets.first;
    // B solo si TODAS las variantes tienen exactamente los mismos ejes (y ≥1).
    final consistente = first.isNotEmpty &&
        sets.every((s) => s.length == first.length && s.containsAll(first));
    if (!consistente) return [];
    // Orden estable: según aparición en la primera variante.
    return _attrs(_variantes.first).keys.toList();
  }

  bool get _usarB => _ejes.isNotEmpty;

  /// Opciones distintas para un eje (en orden de aparición).
  List<String> _opciones(String eje) {
    final vistos = <String>[];
    for (final v in _variantes) {
      final val = _attrs(v)[eje];
      if (val != null && !vistos.contains(val)) vistos.add(val);
    }
    return vistos;
  }

  /// ¿Hay alguna variante EN STOCK con este valor en [eje], compatible con lo
  /// ya elegido en los otros ejes?
  bool _opcionDisponible(String eje, String valor) {
    return _variantes.any((v) {
      final at = _attrs(v);
      if (at[eje] != valor) return false;
      for (final e in _sel.entries) {
        if (e.key == eje) continue;
        if (at[e.key] != e.value) return false;
      }
      return v['hayStock'] == true;
    });
  }

  Map<String, dynamic>? get _varianteElegida {
    if (_usarB) {
      if (_sel.length < _ejes.length) return null;
      for (final v in _variantes) {
        final at = _attrs(v);
        if (_ejes.every((e) => at[e] == _sel[e])) return v;
      }
      return null;
    }
    if (_selId == null) return null;
    for (final v in _variantes) {
      if (v['id'] == _selId) return v;
    }
    return null;
  }

  void _pickB(String eje, String valor) {
    setState(() {
      if (_sel[eje] == valor) {
        _sel.remove(eje); // toggle: deseleccionar
      } else {
        _sel[eje] = valor;
      }
    });
    widget.onChanged(_varianteElegida);
  }

  void _pickA(Map<String, dynamic> v) {
    setState(() => _selId = _selId == v['id'] ? null : v['id'] as String);
    widget.onChanged(_varianteElegida);
  }

  @override
  Widget build(BuildContext context) {
    return _usarB ? _buildB() : _buildA();
  }

  // ── Modo B: selector por atributo ──────────────────────────────────────────
  Widget _buildB() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final eje in _ejes) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: '$eje: '),
                  TextSpan(
                    text: _sel[eje] ?? 'Elige una opción',
                    style: TextStyle(
                      color: _sel[eje] != null ? AppColors.blue2 : Colors.grey.shade500,
                      fontWeight: _sel[eje] != null ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final op in _opciones(eje))
                _chip(
                  label: op,
                  selected: _sel[eje] == op,
                  disabled: !_opcionDisponible(eje, op),
                  onTap: () => _pickB(eje, op),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ── Modo A: chips por nombre de variante ───────────────────────────────────
  Widget _buildA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, top: 4),
          child: Text('Elegí una opción',
              style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in _variantes)
              _chip(
                label: v['nombre']?.toString() ?? '',
                selected: _selId == v['id'],
                disabled: v['hayStock'] != true,
                onTap: () => _pickA(v),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final Color border;
    final Color bg;
    final Color fg;
    if (selected) {
      border = AppColors.blue1;
      bg = AppColors.blue1;
      fg = Colors.white;
    } else if (disabled) {
      border = Colors.grey.shade200;
      bg = Colors.grey.shade50;
      fg = Colors.grey.shade400;
    } else {
      border = Colors.grey.shade300;
      bg = Colors.white;
      fg = Colors.black87;
    }
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border, width: selected ? 1 : 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: fg,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            decoration: disabled ? TextDecoration.lineThrough : null,
            decorationColor: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
