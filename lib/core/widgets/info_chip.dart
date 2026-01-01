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

  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.textColor = AppColors.blue2,
    this.backgroundColor = AppColors.bluechip,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: AppCaption(
        items: [
          CaptionItem(
            icon: icon,
            text: text,
          ),
        ],
        color: textColor,
        fontSize: 9,
      ),
    );
  }
}
