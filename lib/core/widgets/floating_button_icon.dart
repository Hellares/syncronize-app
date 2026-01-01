import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class FloatingButtonIcon extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  // Tamaño
  final double size; // ancho y alto

  // Estilo
  final double borderRadius;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  const FloatingButtonIcon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 40,
    this.borderRadius = 8,
    this.backgroundColor = AppColors.blue1,
    this.iconColor = Colors.white,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
