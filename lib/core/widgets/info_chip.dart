// import 'package:flutter/material.dart';

// import '../fonts/app_text_widgets.dart';
// import '../theme/app_colors.dart';

// class InfoChip extends StatelessWidget {
//   final IconData icon;
//   final String text;

//   const InfoChip({
//     super.key,
//     required this.icon,
//     required this.text,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: AppColors.bluechip,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: AppCaption(
//         items: [
//           CaptionItem(icon: icon, text: text),
//         ],
//         color: AppColors.blue2,
//         fontSize: 9,
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

import '../fonts/app_text_widgets.dart';
import '../fonts/app_fonts.dart';
import '../theme/app_colors.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  /// Color del texto e ícono
  final Color textColor;

  /// Color de fondo del chip
  final Color backgroundColor;

  /// Radio del borde (opcional)
  final double borderRadius;

  /// Color del borde (opcional)
  final Color? borderColor;

  /// Ancho del borde (opcional)
  final double borderWidth;

  /// Altura del chip (opcional)
  final double? height;

  final double? width;

  final double? fontSize;

  /// Peso de la fuente (opcional)
  final FontWeight? fontWeight;

  /// Fuente usando AppFont (opcional, recomendado)
  final AppFont? font;

  /// Familia de fuente como String (opcional, para fuentes custom)
  final String? fontFamily;

  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.textColor = AppColors.blue2,
    this.backgroundColor = AppColors.bluechip,
    this.borderRadius = 12,
    this.borderColor,
    this.borderWidth = 0,
    this.height,
    this.fontWeight,
    this.font,
    this.fontFamily,
    this.fontSize,
    this.width,

  });

  @override
  Widget build(BuildContext context) {
    // Si se especificó font (AppFont), convertirlo a String
    final String? resolvedFontFamily = font != null
        ? AppFonts.getFontFamily(font!)
        : fontFamily;

    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth,
              )
            : null,
      ),
      child: AppCaption(
        items: [
          CaptionItem(
            icon: icon,
            text: text,
          ),
        ],
        color: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: resolvedFontFamily,
      ),
    );
  }
}
