
import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';


// CLASE PARA GRADIENTES REUTILIZABLES
class AppGradients {
  // Prevenir instanciación
  AppGradients._();

  // GRADIENTE PRINCIPAL 
  static LinearGradient get fondo => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),  // blanco
      Color(0xFFD2EDFF),  // azul claro
      Color(0xFFF8CCFF),  // rosa claro
    ],
    stops: [0.0, 0.9, 1.0],
  );

   static LinearGradient get fondopollo => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.white,  // blanco
      AppColors.white,
      AppColors.white,// rosa claro
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // VARIACIONES DEL GRADIENTE PRINCIPAL
  static LinearGradient fondoVertical() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),  // blanco
      Color(0xFFD2EDFF),  // azul claro
      Color(0xFFF8CCFF),  // rosa claro
    ],
    stops: [0.0, 0.7, 1.0],
  );

  static LinearGradient fondoHorizontal() => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFFFFF),  // blanco
      Color(0xFFD2EDFF),  // azul claro
      Color(0xFFF8CCFF),  // rosa claro
    ],
    stops: [0.0, 0.8, 1.0],
  );

 static LinearGradient blueWhiteBlue() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(255, 223, 238, 253), // Azul claro superior
      Color(0xFFFFFFFF),                   // Blanco centro (AppColors.white)
      Color.fromARGB(255, 223, 238, 253), // Azul claro inferior
    ],
    stops: [0.0, 0.7, 1.0],
  );

  static LinearGradient blueWhiteDialog() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDDF0F8), // Azul claro superior
      Color(0xFFEFF7FA), // Azul muy claro
      Colors.white,
    ],
    stops: [0.0, 0.35, 1.0],
  );

  // static const Color amberShadow = Color(0x33FFC107);

  static LinearGradient orangeWhiteBlue() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFC107), // Azul claro superior
      Color(0xFFFFFFFF),                   // Blanco centro (AppColors.white)
      Color(0x33FFC107), // Azul claro inferior
    ],
    stops: [0.0, 0.7, 1.0],
  );

  static LinearGradient orangeOrange() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFC107), // Azul claro superior
      Color(0x33FFC107),                   // Blanco centro (AppColors.white)
      Color(0x33FFC107), // Azul claro inferior
    ],
    stops: [0.0, 0.7, 1.0],
  );

  static LinearGradient blueWhitegreen() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.green.withValues(alpha: 0.2), // Azul claro superior
      Color(0xFFFFFFFF),                   // Blanco centro (AppColors.white)
      Colors.green.withValues(alpha: 0.2), // Azul claro inferior
    ],
    stops: [0.0, 0.7, 1.0],
  );

  static LinearGradient gray() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEEEEE), 
      Color(0xFFFFFFFF),                   // Blanco centro (AppColors.white)
      Color(0xFFEEEEEE), 
    ],
    stops: [0.0, 0.7, 1.0],
  );

 
  // GRADIENTE PERSONALIZABLE
  static LinearGradient custom({
    required Color startColor,
    required Color middleColor, 
    required Color endColor,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, middleColor, endColor],
      stops: stops ?? [0.0, 0.7, 1.0],
    );
  }

  static LinearGradient get sinfondo => const LinearGradient(
    colors: [
    Color(0xFFFFFFFF),  // blanco
    Color(0xFFFFFFFF),  // blanco
  ],
  );
}

// EXTENSION PARA FACILITAR EL USO
extension GradientExtension on Widget {
  Widget withGradientBackground(LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: this,
    );
  }
}


enum ShadowStyle {
  none,        // Sin sombra
  neumorphic,  // Estilo neumórfico
  colorful,    // Sombra colorida basada en borderColor
  glow,        // Efecto de brillo/glow
}

