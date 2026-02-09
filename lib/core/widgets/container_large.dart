import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';

class ContainerLarge extends StatelessWidget {
  // Propiedades requeridas
  final String leftText;
  final String? rightText;

  final AppFont? fontLeft;       // ← nuevo
  final AppFont? fontRight;      // ← nuevo

  // Propiedades opcionales / personalizables
  final IconData? leftIcon;
  final IconData? rightIcon;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color textAndIconColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double iconSize;
  final double fontSize;
  final double? fontSizeRight;
  

  const ContainerLarge({
    super.key,
    required this.leftText,
    this.rightText = '',
    this.leftIcon,
    this.rightIcon,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFFE3F2FD), // blue.shade50
    this.borderColor = const Color(0xFFBBDEFB),     // blue.shade200
    this.borderWidth = 0.6,
    this.textAndIconColor = const Color(0xFF1565C0), // blue.shade700
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.all(8.0),
    this.iconSize = 16.0,
    this.fontSize = 12.0,
    this.fontSizeRight,
    this.fontLeft,               // ← nuevo
    this.fontRight,              // ← nuevo
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono izquierdo (si existe)
          if (leftIcon != null) ...[
            Icon(
              leftIcon,
              size: iconSize,
              color: textAndIconColor,
            ),
            const SizedBox(width: 8),
          ],

          // Texto izquierdo
          Text(
            leftText,
            style: (fontLeft ?? AppFont.oxygenRegular).style(   // ← aquí
              fontSize: fontSize,
              // fontWeight: fontWeight,
              color: textAndIconColor,
            ),
          ),

          const Spacer(),

          // Texto derecho
          Text(
            rightText!,
            style: (fontRight ?? AppFont.oxygenRegular).style(  // ← aquí
              fontSize: fontSizeRight ?? fontSize,
              // fontWeight: fontWeight,
              color: textAndIconColor,
            ),
          ),

          // Icono derecho (si existe)
          if (rightIcon != null) ...[
            const SizedBox(width: 8),
            Icon(
              rightIcon,
              size: iconSize,
              color: textAndIconColor,
            ),
          ],
        ],
      ),
    );
  }
}