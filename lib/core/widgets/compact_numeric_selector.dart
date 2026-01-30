import 'package:flutter/material.dart';

/// Widget selector numérico compacto con botones - / +
/// Ideal para campos de formulario donde se necesita seleccionar un número
/// dentro de un rango específico (ej: longitud de código, cantidad, etc.)
class CompactNumericSelector extends StatefulWidget {
  /// El valor mínimo que se puede seleccionar
  final int minValue;

  /// El valor máximo que se puede seleccionar
  final int maxValue;

  /// El valor inicial
  final int initialValue;

  /// Callback cuando el valor cambia
  final ValueChanged<int> onChanged;

  /// Texto de la etiqueta
  final String? label;

  /// Texto de ayuda debajo del selector
  final String? helperText;

  /// Si el selector está habilitado
  final bool enabled;

  /// Prefijo a mostrar antes del valor (ej: "$", "kg", etc.)
  final String? prefix;

  /// Sufijo a mostrar después del valor (ej: "dígitos", "unidades", etc.)
  final String? suffix;

  /// Intervalo de cambio
  final int step;

  const CompactNumericSelector({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onChanged,
    this.label,
    this.helperText,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.step = 1,
  })  : assert(minValue <= maxValue, 'minValue debe ser <= maxValue'),
        assert(initialValue >= minValue && initialValue <= maxValue,
            'initialValue debe estar entre minValue y maxValue');

  @override
  State<CompactNumericSelector> createState() => _CompactNumericSelectorState();
}

class _CompactNumericSelectorState extends State<CompactNumericSelector> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(CompactNumericSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el initialValue cambia desde fuera, actualizar
    if (oldWidget.initialValue != widget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  void _increment() {
    if (!widget.enabled) return;
    if (_currentValue + widget.step <= widget.maxValue) {
      setState(() {
        _currentValue += widget.step;
      });
      widget.onChanged(_currentValue);
    }
  }

  void _decrement() {
    if (!widget.enabled) return;
    if (_currentValue - widget.step >= widget.minValue) {
      setState(() {
        _currentValue -= widget.step;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final canDecrement = _currentValue > widget.minValue && widget.enabled;
    final canIncrement = _currentValue < widget.maxValue && widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Selector principal
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.enabled
                  ? colorScheme.outline
                  : colorScheme.outline.withValues(alpha:0.38),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: widget.enabled
                ? colorScheme.surface
                : colorScheme.surface.withValues(alpha:0.5),
          ),
          child: Row(
            children: [
              // Botón decrementar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canDecrement ? _decrement : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outline.withValues(alpha:0.38),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 20,
                      color: canDecrement
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),

              // Valor actual
              Expanded(
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.prefix != null) ...[
                        Text(
                          widget.prefix!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _currentValue.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (widget.suffix != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          widget.suffix!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Botón incrementar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canIncrement ? _increment : null,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colorScheme.outline.withValues(alpha:0.38),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: canIncrement
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Helper text
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
