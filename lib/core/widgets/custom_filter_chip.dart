import 'package:flutter/material.dart';

import '../fonts/app_fonts.dart';
import '../theme/app_colors.dart';

class CustomFilterChip extends StatelessWidget {
  /// Texto del chip
  final String label;

  /// Ícono opcional a la izquierda del texto
  final IconData? icon;

  /// Tamaño del ícono
  final double? iconSize;

  /// Estado de selección
  final bool selected;

  /// Callback al seleccionar/deseleccionar
  final VoidCallback? onSelected;

  /// Color de fondo cuando no está seleccionado
  final Color backgroundColor;

  /// Color de fondo cuando está seleccionado
  final Color selectedBackgroundColor;

  /// Color del texto cuando no está seleccionado
  final Color textColor;

  /// Color del texto cuando está seleccionado
  final Color selectedTextColor;

  /// Tamaño de la fuente
  final double fontSize;

  /// Peso de la fuente
  final FontWeight? fontWeight;

  /// Familia de fuente como String
  final String? fontFamily;

  /// Fuente usando AppFont
  final AppFont? font;

  /// Color del borde cuando no está seleccionado
  final Color borderColor;

  /// Color del borde cuando está seleccionado
  final Color? selectedBorderColor;

  /// Ancho del borde
  final double borderWidth;

  /// Radio del borde
  final double borderRadius;

  /// Altura del chip
  final double? height;

  /// Padding interno del contenido
  final EdgeInsets? contentPadding;

  /// Mostrar checkmark cuando está seleccionado
  final bool showCheckmark;

  /// Si el chip está habilitado
  final bool enabled;

  const CustomFilterChip({
    super.key,
    required this.label,
    this.icon,
    this.iconSize,
    this.selected = false,
    required this.onSelected,
    this.backgroundColor = Colors.white,
    this.selectedBackgroundColor = AppColors.blue1,
    this.textColor = AppColors.blue2,
    this.selectedTextColor = Colors.white,
    this.fontSize = 10,
    this.fontWeight,
    this.fontFamily,
    this.font,
    this.borderColor = AppColors.blue1,
    this.selectedBorderColor,
    this.borderWidth = 0.5,
    this.borderRadius = 4,
    this.height,
    this.contentPadding,
    this.showCheckmark = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final String? resolvedFontFamily =
        font != null ? AppFonts.getFontFamily(font!) : fontFamily;

    final Color currentBg =
        selected ? selectedBackgroundColor : backgroundColor;
    final Color currentText = selected ? selectedTextColor : textColor;
    final Color currentBorder =
        selected ? (selectedBorderColor ?? borderColor) : borderColor;

    final double resolvedIconSize = iconSize ?? fontSize + 4;

    final EdgeInsets padding =
        contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    const duration = Duration(milliseconds: 200);

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: currentText, size: resolvedIconSize),
          const SizedBox(width: 4),
        ],
        // El color del texto acompaña la animación del fondo (antes el fondo
        // hacía fade de 200ms pero el texto saltaba en seco).
        AnimatedDefaultTextStyle(
          duration: duration,
          curve: Curves.easeInOut,
          style: TextStyle(
            color: currentText,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: resolvedFontFamily,
          ),
          child: Text(label),
        ),
        if (showCheckmark && selected) ...[
          const SizedBox(width: 6),
          Icon(Icons.check, color: currentText, size: resolvedIconSize),
        ],
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOut,
        height: height,
        decoration: BoxDecoration(
          color: currentBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: currentBorder, width: borderWidth),
        ),
        // Material transparente DENTRO del container: el ripple del InkWell
        // se dibuja sobre el fondo animado (encima del Material quedaría
        // tapado y el chip no daría feedback al toque).
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onSelected : null,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              // Con altura fija el contenido queda centrado en vez de
              // pegado arriba.
              child: height != null ? Center(child: content) : content,
            ),
          ),
        ),
      ),
    );
  }
}
