import 'package:flutter/material.dart';

/// Un widget selector numérico horizontal que permite a los usuarios seleccionar un número
/// dentro de un rango determinado deslizando el dedo hacia la izquierda o la derecha.
///
/// Es altamente personalizable en apariencia, comportamiento y estilo.
class HorizontalNumericSelector extends StatefulWidget {
  // --- Parámetros Principales ---
  /// El valor mínimo que se puede seleccionar.
  final int minValue;

  /// El valor máximo que se puede seleccionar.
  final int maxValue;

  /// El intervalo de paso entre los valores seleccionables.
  final int step;

  /// El valor inicial seleccionado cuando el widget se renderiza por primera vez.
  final int initialValue;

  /// Función de callback que se activa cuando el valor seleccionado cambia.
  final ValueChanged<int> onValueChanged;

  // --- Parámetros de UI y Comportamiento ---
  /// La fracción del viewport para el `PageView`, afecta cuánto de los
  /// valores siguientes y anteriores son visibles. Un valor común es 0.4.
  final double viewPortFraction;

  /// La altura del área del selector.
  final double itemExtent;

  /// Si se debe mostrar el valor seleccionado debajo del selector.
  final bool showSelectedValue;

  /// Si se debe mostrar una etiqueta debajo del valor seleccionado.
  final bool showLabel;

  /// El texto de la etiqueta que se muestra debajo del valor seleccionado (si está habilitado).
  final String? label;

  // --- Parámetros de Estilo ---
  /// El estilo de texto para el valor seleccionado DENTRO del selector.
  final TextStyle? selectedTextStyle;

  /// El estilo de texto para los valores no seleccionados DENTRO del selector.
  final TextStyle? unselectedTextStyle;

  /// El estilo de texto para el valor mostrado DEBAJO del selector.
  final TextStyle? displayTextStyle;

  /// El estilo de texto para la etiqueta opcional.
  final TextStyle? labelTextStyle;

  /// El color de fondo del selector numérico.
  final Color? backgroundColor;

  /// El radio del borde para redondear los bordes del selector.
  final BorderRadius? borderRadius;

  /// Crea un selector numérico horizontal.
  const HorizontalNumericSelector({
    super.key,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
    required this.initialValue,
    required this.onValueChanged,
    this.viewPortFraction = 0.4,
    this.itemExtent = 50.0,
    this.showSelectedValue = true,
    this.showLabel = false,
    this.label,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.displayTextStyle,
    this.labelTextStyle,
    this.backgroundColor,
    this.borderRadius,
  })  : assert(minValue <= maxValue, 'minValue no puede ser mayor que maxValue'),
        assert(step > 0, 'El paso (step) debe ser mayor que 0'),
        assert(initialValue >= minValue && initialValue <= maxValue,
            'initialValue debe estar dentro del rango [minValue, maxValue]');

  @override
  State<HorizontalNumericSelector> createState() =>
      _HorizontalNumericSelectorState();
}

class _HorizontalNumericSelectorState
    extends State<HorizontalNumericSelector> {
  late final PageController _pageController;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _initializePageController();
  }

  void _initializePageController() {
    final initialPage = (_selectedValue - widget.minValue) ~/ widget.step;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: widget.viewPortFraction,
    );
  }

  @override
  void didUpdateWidget(covariant HorizontalNumericSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el rango o el paso cambian, es más seguro reiniciar el controlador.
    if (oldWidget.minValue != widget.minValue ||
        oldWidget.maxValue != widget.maxValue ||
        oldWidget.step != widget.step ||
        oldWidget.viewPortFraction != widget.viewPortFraction) {
      
      // Actualizar el valor seleccionado si está fuera del nuevo rango
      if (_selectedValue < widget.minValue) {
        _selectedValue = widget.minValue;
      } else if (_selectedValue > widget.maxValue) {
        _selectedValue = widget.maxValue;
      }
      
      _pageController.dispose();
      _initializePageController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultSelectedStyle = theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        );
    final defaultUnselectedStyle = theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer.withValues(alpha:0.6),
        );
    final defaultDisplayStyle = theme.textTheme.headlineMedium;
    final defaultLabelStyle = theme.textTheme.bodyMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Selector Principal ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? theme.colorScheme.primaryContainer,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: widget.itemExtent,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: _calculateItemCount(),
              onPageChanged: (index) {
                final newValue = widget.minValue + index * widget.step;
                if (_selectedValue != newValue) {
                  setState(() {
                    _selectedValue = newValue;
                  });
                  widget.onValueChanged(_selectedValue);
                }
              },
              itemBuilder: (context, index) {
                final value = widget.minValue + index * widget.step;
                final isSelected = _selectedValue == value;

                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: isSelected
                        ? (widget.selectedTextStyle ?? defaultSelectedStyle!)
                        : (widget.unselectedTextStyle ?? defaultUnselectedStyle!),
                    child: Text(value.toString()),
                  ),
                );
              },
            ),
          ),
        ),

        // --- Valor Seleccionado y Etiqueta (Opcional) ---
        if (widget.showSelectedValue) ...[
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                _selectedValue.toString(),
                style: widget.displayTextStyle ?? defaultDisplayStyle!,
              ),
              if (widget.showLabel && widget.label != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.label!,
                  style: widget.labelTextStyle ?? defaultLabelStyle!,
                ),
              ]
            ],
          ),
        ]
      ],
    );
  }

  /// Calcula el número total de elementos en el PageView.
  int _calculateItemCount() {
    return ((widget.maxValue - widget.minValue) / widget.step).floor() + 1;
  }
}