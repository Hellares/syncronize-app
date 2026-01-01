import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Forzar todos los fondos a blanco
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      cardColor: Colors.white,
      
      // ColorScheme optimizado para blanco
      colorScheme: _whiteColorScheme,
      
      // Configuraciones específicas de componentes
      appBarTheme: _appBarTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _fabTheme,
      textTheme: _textTheme,
    );
  }

  

  // ColorScheme personalizado para fondo blanco
  static const ColorScheme _whiteColorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: Colors.black87,
    onPrimary: Colors.white,
    primaryContainer: Colors.white,
    onPrimaryContainer: Colors.black87,
    secondary: Colors.grey,
    onSecondary: Colors.white,
    secondaryContainer: Colors.white,
    onSecondaryContainer: Colors.black87,
    tertiary: Colors.blueGrey,
    onTertiary: Colors.white,
    tertiaryContainer: Colors.white,
    onTertiaryContainer: Colors.black87,
    error: Colors.red,
    onError: Colors.white,
    errorContainer: Color(0xFFFFEBEE),
    onErrorContainer: Colors.red,
    surface: Colors.white,
    onSurface: Colors.black87,
    onSurfaceVariant: Colors.black54,
    outline: Colors.grey,
    outlineVariant: Colors.grey,
    shadow: Colors.black12,
    scrim: Colors.black54,
    inverseSurface: Colors.black87,
    onInverseSurface: Colors.white,
    inversePrimary: Colors.white,
  );

  // Configuración del AppBar
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(
      color: Colors.black87,
      size: 24,
    ),
  );

  // Botones elevados
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // Botones de texto
  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black87,
      backgroundColor: Colors.transparent,
    ),
  );

  // Botones con borde
  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      side: const BorderSide(color: Colors.grey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // Campos de texto
  static const InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.black87, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.red),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  // Navegación inferior
  static const BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.black87,
    unselectedItemColor: Colors.grey,
    elevation: 8,
    type: BottomNavigationBarType.fixed,
  );

  // Botón flotante
  static const FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 4,
    shape: CircleBorder(
      side: BorderSide(color: Colors.grey, width: 0.5),
    ),
  );

  // Tipografía
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(color: Colors.black87),
    displayMedium: TextStyle(color: Colors.black87),
    displaySmall: TextStyle(color: Colors.black87),
    headlineLarge: TextStyle(color: Colors.black87),
    headlineMedium: TextStyle(color: Colors.black87),
    headlineSmall: TextStyle(color: Colors.black87),
    titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54),
    labelLarge: TextStyle(color: Colors.black87),
    labelMedium: TextStyle(color: Colors.black87),
    labelSmall: TextStyle(color: Colors.black54),
  );
}