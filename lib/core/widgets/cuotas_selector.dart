import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Selector visual de número de cuotas (meses).
///
/// Muestra chips con valores comunes y permite seleccionar rápidamente.
/// Si el valor seleccionado no está en los predefinidos, muestra un campo custom.
///
/// ```dart
/// CuotasSelector(
///   value: _numeroCuotas,
///   onChanged: (v) => setState(() => _numeroCuotas = v),
/// )
/// ```
class CuotasSelector extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final List<int> opciones;
  final Color? activeColor;

  const CuotasSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.opciones = const [1, 2, 3, 4, 5, 6, 10, 12, 14, 16, 18, 20, 25, 30, 32, 36],
    this.activeColor,
  });

  @override
  State<CuotasSelector> createState() => _CuotasSelectorState();
}

class _CuotasSelectorState extends State<CuotasSelector> {
  Color get _color => widget.activeColor ?? AppColors.blue1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: widget.opciones.map((n) => _chip(n)).toList(),
        ),
      ],
    );
  }

  Widget _chip(int n) {
    final selected = widget.value == n;
    return GestureDetector(
      onTap: () => widget.onChanged(n),
      child: Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: selected ? _color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _color : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

}
