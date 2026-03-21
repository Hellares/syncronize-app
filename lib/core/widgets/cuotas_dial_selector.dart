import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Selector de cuotas tipo dial compacto.
///
/// Un botón circular que muestra el número actual de cuotas.
/// - Tap: abre un picker tipo rueda (wheel) para seleccionar
/// - Botones +/- para ajuste rápido
///
/// ```dart
/// CuotasDialSelector(
///   value: _numeroCuotas,
///   onChanged: (v) => setState(() => _numeroCuotas = v),
/// )
/// ```
class CuotasDialSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final Color? activeColor;
  final String? label;

  const CuotasDialSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 48,
    this.activeColor,
    this.label,
  });

  Color get _color => activeColor ?? AppColors.blue1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
          const SizedBox(width: 10),
        ],
        // Botón -
        _roundButton(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 4),
        // Dial central (tap para abrir picker)
        GestureDetector(
          onTap: () => _showWheelPicker(context),
          child: Container(
            width: 45,
            height: 35,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  value == 1 ? 'mes' : 'meses',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Botón +
        _roundButton(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _roundButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? _color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? _color.withValues(alpha: 0.3) : Colors.grey[300]!,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _color : Colors.grey[400],
        ),
      ),
    );
  }

  void _showWheelPicker(BuildContext context) {
    int tempValue = value;
    final controller = FixedExtentScrollController(
      initialItem: value - min,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: 280,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    Text('Cuotas (meses)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _color)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onChanged(tempValue);
                      },
                      child: Text('Listo', style: TextStyle(fontWeight: FontWeight.w700, color: _color)),
                    ),
                  ],
                ),
              ),
              // Wheel
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 44,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 1.5,
                  perspective: 0.003,
                  onSelectedItemChanged: (index) {
                    setSheetState(() => tempValue = index + min);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: max - min + 1,
                    builder: (context, index) {
                      final n = index + min;
                      final selected = n == tempValue;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontSize: selected ? 22 : 15,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                            color: selected ? _color : Colors.grey[400],
                          ),
                          child: Text(
                            '$n ${n == 1 ? 'mes' : 'meses'}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
