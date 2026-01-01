

import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Enum que representa las fuentes disponibles
enum AppFont {
  airstrike3d,
  airstrikeBold3d,
  orbitronMedium,
  orbitronRegular,
  pirulentBold,
  jetbrains,
  cascadia,
  oxygenBold,
  oxygenLight,
  oxygenRegular,
  fonartoXt,
}

/// Clase que contiene el mapeo de fuentes y métodos de estilo
class AppFonts {
  static const Map<AppFont, String> _fontMap = {
    AppFont.airstrike3d: 'Airstrike3D',
    AppFont.airstrikeBold3d: 'AirstrikeBold3D',
    AppFont.orbitronMedium: 'Orbitron-Medium',
    AppFont.orbitronRegular: 'Orbitron-Regular',
    AppFont.pirulentBold: 'Pirulent',
    AppFont.jetbrains: 'jetbrains-mono.medium-medium',
    AppFont.cascadia: 'Cascadia',
    AppFont.oxygenBold: 'Oxygen-Bold',
    AppFont.oxygenLight: 'Oxygen-Light',
    AppFont.oxygenRegular: 'Oxygen-Regular',
    AppFont.fonartoXt: 'fonarto.xt',
  };

  static String getFontFamily(AppFont font) => _fontMap[font] ?? 'oxygenRegular';

  static TextStyle getTextStyle(
    AppFont font, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: getFontFamily(font),
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static List<AppFont> getAvailableFonts() => AppFont.values;

  static String getFontDisplayName(AppFont font) =>
      _fontMap[font] ?? 'Unknown Font';
}

/// Extensión original para uso manual del estilo
extension AppFontExtension on AppFont {
  String get fontFamily => AppFonts.getFontFamily(this);

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return AppFonts.getTextStyle(
      this,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }
}

/// Extensión con estilos predefinidos como .label, .title, etc.
extension AppFontPresetStyles on AppFont {
  TextStyle get label => style(
        fontSize: 9,
        // fontWeight: FontWeight.w400,
        color: Colors.black87,
        
      );

  TextStyle get title => style(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.blue3,
      );

  TextStyle get subtitle => style(
        fontSize: 10,
        // fontWeight: FontWeight.bold,
        color: AppColors.blue3,
      );


  TextStyle get heading => style(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey[900],
      );

  TextStyle get caption => style(
        fontSize: 9,
        fontWeight: FontWeight.w300,
        color: Colors.grey[700],
      );

  TextStyle get button => style(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  TextStyle get link => style(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      );
}
