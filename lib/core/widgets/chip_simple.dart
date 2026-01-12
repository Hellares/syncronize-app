import 'package:flutter/material.dart';

class ChipSimple extends StatelessWidget {
  const ChipSimple({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 8,
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
    this.borderRadius = 12,
    this.opacity = 0.1,
    this.borderOpacity = 0.3,
    this.textOpacity = 0.9,
    this.fontWeight = FontWeight.w500,
  });

  final String label;
  final Color color;

  // Personalización opcional
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double opacity;
  final double borderOpacity;
  final double textOpacity;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: borderOpacity),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: textOpacity),
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
