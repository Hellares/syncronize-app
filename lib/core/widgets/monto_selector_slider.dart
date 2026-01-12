import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';

/// MontoSelectorSlider - Selector de monto con Slider deslizante
class MontoSelectorSlider extends StatefulWidget {
  final String title;
  final IconData icon;
  final double? selectedMonto;
  final ValueChanged<double?> onMontoChanged;
  final TextEditingController? controller;

  // Configuración del Slider
  final double minMonto;
  final double maxMonto;
  final int? divisions; // Número de divisiones discretas (null = continuo)
  final double step; // Incremento del slider (solo si divisions es null)

  final String moneda;

  // Mostrar marcas de referencia en el slider
  final List<double>? marcasReferencia;
  final bool showMarcasReferencia; // Control explícito para mostrar/ocultar badges

  // Estilo del contenedor
  final LinearGradient? gradient;
  final ShadowStyle shadowStyle;
  final bool enableShadow;
  final List<BoxShadow>? customShadows;
  final BorderRadius? containerBorderRadius;

  // Estilo de los elementos internos
  final Color? primaryColor;
  final Color? borderColor;
  final Color? cardBg;
  final Color? sliderActiveColor;
  final Color? sliderInactiveColor;

  const MontoSelectorSlider({
    super.key,
    required this.title,
    required this.icon,
    required this.selectedMonto,
    required this.onMontoChanged,
    this.controller,
    this.minMonto = 0,
    this.maxMonto = 20000,
    this.divisions,
    this.step = 100, // Por defecto, incrementos de 100
    this.moneda = 'S/',
    this.marcasReferencia,
    this.showMarcasReferencia = true, // Por defecto, mostrar badges si hay marcas
    // Estilo del contenedor
    this.gradient,
    this.shadowStyle = ShadowStyle.none,
    this.enableShadow = true,
    this.customShadows,
    this.containerBorderRadius,
    // Estilo de elementos internos
    this.primaryColor,
    this.borderColor,
    this.cardBg,
    this.sliderActiveColor,
    this.sliderInactiveColor,
  });

  @override
  State<MontoSelectorSlider> createState() => _MontoSelectorSliderState();
}

class _MontoSelectorSliderState extends State<MontoSelectorSlider> {
  late TextEditingController _controller;
  bool _ownsController = false;

  // Valor interno del slider
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();

    // Inicializar slider value
    _sliderValue = (widget.selectedMonto ?? widget.minMonto).clamp(
      widget.minMonto,
      widget.maxMonto,
    );

    // Inicializar controller si hay monto
    if (widget.selectedMonto != null && widget.selectedMonto! > 0) {
      _controller.text = widget.selectedMonto!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MontoSelectorSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sincronizar si el monto cambió externamente
    if (widget.selectedMonto != oldWidget.selectedMonto) {
      final newValue = (widget.selectedMonto ?? widget.minMonto).clamp(
        widget.minMonto,
        widget.maxMonto,
      );

      if (_sliderValue != newValue) {
        setState(() {
          _sliderValue = newValue;
        });
      }

      if (widget.selectedMonto != null && widget.selectedMonto! > 0) {
        _controller.text = widget.selectedMonto!.toStringAsFixed(2);
      }
    }
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
    });

    // Actualizar el controller
    _controller.text = value.toStringAsFixed(2);

    // Notificar al parent
    widget.onMontoChanged(value > 0 ? value : null);
  }

  void _onCurrencyChanged(double value) {
    // Asegurar que el valor esté en el rango
    final clampedValue = value.clamp(widget.minMonto, widget.maxMonto);

    setState(() {
      _sliderValue = clampedValue;
    });

    widget.onMontoChanged(value > 0 ? value : null);
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrimaryColor = widget.primaryColor ?? AppColors.blueborder;
    final effectiveBorderColor = widget.borderColor ?? AppColors.blueborder;
    // final effectiveCardBg = widget.cardBg ?? Colors.white;
    final effectiveSliderActive = widget.sliderActiveColor ?? AppColors.blueborder;
    final effectiveSliderInactive = widget.sliderInactiveColor ?? Colors.grey[300]!;

    return GradientContainer(
      padding: const EdgeInsets.all(10),
      borderColor: effectiveBorderColor,
      gradient: widget.gradient ?? AppGradients.blueWhiteBlue(),
      borderWidth: 0.6,
      shadowStyle: widget.shadowStyle,
      enableShadow: widget.enableShadow,
      customShadows: widget.customShadows,
      borderRadius: widget.containerBorderRadius ?? const BorderRadius.all(Radius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(widget.icon, size: 16, color: effectivePrimaryColor),
              const SizedBox(width: 5),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Campo de texto con CurrencyTextField
          CurrencyTextField(
            controller: _controller,
            borderColor: effectiveBorderColor,
            label: 'Monto (${widget.moneda})',
            hintText: '0.00',
            allowZero: true,
            minAmount: widget.minMonto,
            maxAmount: widget.maxMonto,
            onChanged: _onCurrencyChanged,
          ),

          const SizedBox(height: 10),

          // Display del monto actual con el slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: effectivePrimaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajustar con deslizador:',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${widget.moneda} ${_sliderValue.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: effectivePrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Slider con marcas de regla
          Column(
            children: [
              // Slider principal
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: effectiveSliderActive,
                  inactiveTrackColor: effectiveSliderInactive,
                  thumbColor: effectiveSliderActive,
                  overlayColor: effectiveSliderActive.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                  trackHeight: 6,
                  valueIndicatorColor: effectiveSliderActive,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  // Mostrar tick marks si hay marcas de referencia
                  tickMarkShape: widget.marcasReferencia != null && widget.marcasReferencia!.isNotEmpty
                      ? const RoundSliderTickMarkShape(tickMarkRadius: 3)
                      : null,
                  activeTickMarkColor: effectiveSliderActive.withValues(alpha: 0.7),
                  inactiveTickMarkColor: effectiveSliderInactive.withValues(alpha: 0.6),
                ),
                child: Slider(
                  value: _sliderValue,
                  min: widget.minMonto,
                  max: widget.maxMonto,
                  divisions: widget.divisions ?? _calculateDivisions(),
                  label: '${widget.moneda} ${_sliderValue.toStringAsFixed(0)}',
                  onChanged: _onSliderChanged,
                ),
              ),

              // Marcas de regla con labels
              if (widget.marcasReferencia != null && widget.marcasReferencia!.isNotEmpty)
                _RulerMarks(
                  marcas: widget.marcasReferencia!,
                  min: widget.minMonto,
                  max: widget.maxMonto,
                  moneda: widget.moneda,
                  color: effectivePrimaryColor,
                  currentValue: _sliderValue,
                )
              else
                // Labels de min/max cuando no hay marcas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.moneda} ${widget.minMonto.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${widget.moneda} ${widget.maxMonto.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Marcas de referencia opcionales
          if (widget.showMarcasReferencia &&
              widget.marcasReferencia != null &&
              widget.marcasReferencia!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Montos sugeridos:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.marcasReferencia!.map((m) {
                final isSelected = (_sliderValue - m).abs() < widget.step / 2;
                return _MontoBadge(
                  label: '${widget.moneda} ${m.toStringAsFixed(0)}',
                  isSelected: isSelected,
                  color: effectivePrimaryColor,
                  onTap: () => _onSliderChanged(m),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  int _calculateDivisions() {
    // Calcular divisiones basadas en el step
    final range = widget.maxMonto - widget.minMonto;
    return (range / widget.step).round();
  }
}

/// Widget que dibuja las marcas de regla debajo del slider
class _RulerMarks extends StatelessWidget {
  final List<double> marcas;
  final double min;
  final double max;
  final String moneda;
  final Color color;
  final double currentValue;

  const _RulerMarks({
    required this.marcas,
    required this.min,
    required this.max,
    required this.moneda,
    required this.color,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return SizedBox(
            height: 30,
            child: Stack(
              children: [
                // Línea base de la regla
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                ),

                // Marcas de la regla
                ...marcas.map((marca) {
                  final position = _calculatePosition(marca, width);
                  final isActive = currentValue >= marca;
                  final isCurrent = (currentValue - marca).abs() < (max - min) * 0.02;

                  return Positioned(
                    left: position - 1.5, // Centrar la marca
                    top: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Línea vertical de la marca
                        Container(
                          width: isCurrent ? 3 : 2,
                          height: isCurrent ? 12 : 8,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? color
                                : isActive
                                    ? color.withValues(alpha: 0.6)
                                    : Colors.grey[400],
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Label del monto
                        Text(
                          _formatMonto(marca),
                          style: TextStyle(
                            fontSize: isCurrent ? 9 : 8,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? color
                                : isActive
                                    ? color.withValues(alpha: 0.7)
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Marca de inicio (0)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: 6,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Marca de final (max)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: 6,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatMonto(max),
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculatePosition(double marca, double width) {
    // Calcular la posición proporcional en el ancho disponible
    final proportion = (marca - min) / (max - min);
    return proportion * width;
  }

  String _formatMonto(double monto) {
    if (monto >= 1000) {
      return '${(monto / 1000).toStringAsFixed(monto % 1000 == 0 ? 0 : 1)}k';
    }
    return monto.toStringAsFixed(0);
  }
}

class _MontoBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MontoBadge({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? color : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
