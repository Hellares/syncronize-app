import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class FloatingButtonText extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  // Tamaño
  final double height;
  final double width;

  // Estilo
  final double borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double iconSize;
  final Color? borderColor;

  const FloatingButtonText({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.height = 35,
    this.width = 140,
    this.borderRadius = 6,
    this.backgroundColor = AppColors.blue1,
    this.foregroundColor = Colors.white,
    this.fontSize = 10,
    this.fontWeight = FontWeight.w600,
    this.iconSize = 16,
    this.borderColor = AppColors.blue1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        elevation: 0,
        icon: Icon(icon, size: iconSize, color: foregroundColor),
        label: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: foregroundColor,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor ?? foregroundColor)
        ),
      ),
    );
  }
}
