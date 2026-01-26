import 'package:flutter/material.dart';

import '../fonts/app_fonts.dart';
import '../theme/app_colors.dart';

class InfoChip extends StatelessWidget {
  final IconData? icon;
  final String text;

  /// Color del texto e ícono
  final Color textColor;

  /// Color de fondo del chip
  final Color backgroundColor;

  /// Radio del borde
  final double borderRadius;

  /// Color del borde (opcional)
  final Color? borderColor;

  /// Ancho del borde (opcional)
  final double borderWidth;

  /// Altura del chip (opcional)
  final double? height;

  /// Ancho del chip (opcional)
  final double? width;

  final double? fontSize;

  /// Peso de la fuente (opcional)
  final FontWeight? fontWeight;

  /// Fuente usando AppFont (opcional)
  final AppFont? font;

  /// Familia de fuente como String (opcional)
  final String? fontFamily;

  // Parámetros nuevos para funcionalidad selectable (como FilterChip)
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? selectedBackgroundColor;
  final Color? selectedTextColor;
  final Color? selectedBorderColor;
  final bool showCheckmark;
  final EdgeInsets? contentPadding;
  final double? iconSize; // Tamaño explícito para ícono leading y check (opcional)

  const InfoChip({
    super.key,
    this.icon,
    required this.text,
    this.textColor = AppColors.blue2,
    this.backgroundColor = AppColors.bluechip,
    this.borderRadius = 12,
    this.borderColor,
    this.borderWidth = 0,
    this.height,
    this.width,
    this.fontSize,
    this.fontWeight,
    this.font,
    this.fontFamily,
    this.selected = false,
    this.onSelected,
    this.selectedBackgroundColor,
    this.selectedTextColor,
    this.selectedBorderColor,
    this.showCheckmark = false,
    this.contentPadding,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final String? resolvedFontFamily = font != null
        ? AppFonts.getFontFamily(font!)
        : fontFamily;

    final bool isInteractive = onSelected != null;

    final Color currentBg = selected
        ? (selectedBackgroundColor ?? backgroundColor)
        : backgroundColor;
    final Color currentText = selected
        ? (selectedTextColor ?? textColor)
        : textColor;
    final Color currentBorder = selected
        ? (selectedBorderColor ?? borderColor ?? Colors.transparent)
        : (borderColor ?? Colors.transparent);

    final double resolvedFontSize = fontSize ?? 10;
    final double resolvedIconSize = iconSize ?? resolvedFontSize + 6;

    final EdgeInsets padding = contentPadding ??
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    final Widget content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: currentText, size: resolvedIconSize),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: currentText,
              fontSize: resolvedFontSize,
              fontWeight: fontWeight,
              fontFamily: resolvedFontFamily,
            ),
          ),
          if (showCheckmark && selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, color: currentText, size: resolvedIconSize + 2),
          ],
        ],
      ),
    );

    final Widget chip = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: currentBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: (borderColor != null || selectedBorderColor != null)
            ? Border.all(color: currentBorder, width: borderWidth)
            : null,
      ),
      child: content,
    );

    if (isInteractive) {
      return InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => onSelected!(!selected),
        child: chip,
      );
    }

    return chip;
  }
}