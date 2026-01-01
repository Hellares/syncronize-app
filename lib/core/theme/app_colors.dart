import 'package:flutter/material.dart';

class AppColors {
  // Prevenir instanciación
  AppColors._();

  // Colores principales
  static const Color white = Color(0xFFFFFFFF);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  // static const Color red = Color(0xFFD32F2F);
  static const Color red = Color(0xFFF54D85);
  static const Color blue = Color(0xFF1976D2);
  static const Color blueborder = Color(0xFF81B3E6);
  static const Color blue3 = Color.fromARGB(255, 4, 50, 97);
  static const Color blue2 = Color.fromARGB(255, 7, 93, 179);
  static const Color blue1 = Color(0xFF004A94);
  static const Color bluechip = Color(0x1A2196F3);
  static const Color blueGrey = Color(0xFF607D8B);
  static const Color green = Color.fromARGB(255, 43, 175, 71);
  static const Color orange = Color(0xFFDD8A3B);
  static const Color yellow = Color.fromARGB(255, 255, 226, 94);

  // Fondos
  static const Color scaffoldBackground = white;
  static const Color surfaceBackground = white;
  static const Color cardBackground = white;
  static const Color primaryContainer = white;

  // Textos
  static const Color textPrimary = black87;
  static const Color textSecondary = black54;
  static const Color textHint = grey;
  static const Color textOnPrimary = white;

  // Bordes y contornos
  static const Color borderPrimary = grey;
  static const Color borderFocused = black87;
  static const Color borderError = red;

  // Sombras (para widgets neumórficos)
  static Color get shadowLight => white;
  static Color get shadowDark => Colors.black.withValues(alpha: 0.06);
  static Color get shadowSubtle => Colors.black.withValues(alpha: 0.025);
  static Color get shadowMedium => Colors.black.withValues(alpha: 0.12);

  // Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = red;
  static const Color info = blue;

  // Botones
  static const Color buttonPrimary = white;
  static const Color buttonSecondary = grey;
  static const Color buttonText = black87;
}