import 'package:flutter/material.dart';

/// Enum para definir los diferentes estilos de gradient
enum GradientStyle {
  /// Gradient original suave con azul cielo
  skyBlue,

  /// Gradient profesional con transiciones suaves
  professional,

  /// Gradient más vibrante con azul intenso
  vibrant,

  /// Gradient tipo océano con tonos agua
  ocean,

  /// Gradient pastel suave
  pastel,

  /// Gradient con tono turquesa
  turquoise,

  /// Gradient minimalista casi blanco
  minimal,

  /// Gradient dramático con más contraste
  dramatic,

  /// Gradient drawer
  gdrawer,

  gjayli,
}

/// Widget reutilizable para fondos con gradient
///
/// Uso:
/// ```dart
/// GradientBackground(
///   style: GradientStyle.ocean,
///   child: YourContent(),
/// )
/// ```
class GradientBackground extends StatelessWidget {
  /// El contenido que se mostrará sobre el gradient
  final Widget child;

  /// El estilo de gradient a usar
  final GradientStyle style;

  /// Punto de inicio del gradient (opcional)
  final AlignmentGeometry? begin;

  /// Punto final del gradient (opcional)
  final AlignmentGeometry? end;

  const GradientBackground({
    super.key,
    required this.child,
    this.style = GradientStyle.skyBlue,
    this.begin,
    this.end,
  });

  /// Retorna el gradient según el estilo seleccionado
  LinearGradient _getGradient() {
    final gradientBegin = begin ?? Alignment.topCenter;
    final gradientEnd = end ?? Alignment.bottomCenter;

    switch (style) {
      case GradientStyle.skyBlue:
        // Gradient original - azul cielo suave
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFFB8E3F5), // Azul claro superior
            Color(0xFFE8F6FC), // Azul muy claro
            Colors.white, // Blanco en la parte inferior
          ],
          stops: const [0.0, 0.4, 1.0],
        );

      case GradientStyle.professional:
        // Gradient suave y profesional con 4 paradas
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFFB8E3F5), // Azul claro
            Color(0xFFE8F6FC), // Azul muy claro
            Color(0xFFF5FBFD), // Casi blanco con tinte azul
            Colors.white,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case GradientStyle.vibrant:
        // Gradient más vibrante con azul intenso
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFF88CFEB), // Azul más intenso
            Color(0xFFB8E3F5), // Azul claro
            Color(0xFFE8F6FC), // Azul muy claro
            Colors.white,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case GradientStyle.ocean:
        // Gradient tipo océano con tonos agua
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFF70C5E6), // Azul agua intenso
            Color(0xFFB0E0E6), // Powder blue
            Color(0xFFE0F4F7), // Casi blanco
            Colors.white,
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        );

      case GradientStyle.pastel:
        // Gradient pastel muy suave
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFFBBDEFB), // Blue 100 Material
            Color(0xFFD0EEF9), // Azul pastel
            Color(0xFFEDF7FB), // Azul muy claro
            Colors.white,
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        );

      case GradientStyle.turquoise:
        // Gradient con tono turquesa
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFFAFEEEE), // Pale Turquoise
            Color(0xFFB3E5FC), // Light Blue
            Color(0xFFE1F5FE), // Muy claro
            Colors.white,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case GradientStyle.minimal:
        // Gradient minimalista casi blanco
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFFE5F5FC), // Muy claro, casi blanco
            Color(0xFFF0F9FC), // Casi blanco
            Color(0xFFF8FCFE), // Super claro
            Colors.white,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case GradientStyle.dramatic:
        // Gradient dramático con más contraste
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
            Color(0xFF58BBE1), // Azul muy intenso
            Color(0xFF88CFEB), // Azul intenso
            Color(0xFFB8E3F5), // Azul medio
            Color(0xFFE8F6FC), // Azul claro
            Colors.white,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

      case GradientStyle.gdrawer:
        // Gradient dramático con más contraste
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: [
            Colors.blue.shade700, // Azul muy intenso
            Colors.blue.shade500, // Azul intenso
            Color(0xFFB8E3F5), // Azul medio
            Color(0xFFE8F6FC), // Azul claro
            Colors.white,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

      case GradientStyle.gjayli:
        // Gradient más vibrante con azul intenso
        return LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: const [
  Color.fromARGB(255, 7, 93, 179), // Azul base intenso
  Color(0xFF075DB3), // Transición suave
  // Color(0xFF365FBC), // Azul claro
  Color.fromARGB(255, 255, 255, 255), // Azul muy claro
  Color.fromARGB(255, 255, 255, 255), // Casi blanco
],
stops: const [0.0, 0.45,  0.95, 1.0],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: _getGradient()),
      child: child,
    );
  }
}

/// Widget de preview para mostrar todos los gradients disponibles
/// Útil para desarrollo y selección de estilo
class GradientPreviewGrid extends StatelessWidget {
  const GradientPreviewGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gradient Previews'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: GradientStyle.values.length,
        itemBuilder: (context, index) {
          final style = GradientStyle.values[index];
          return _GradientPreviewCard(style: style);
        },
      ),
    );
  }
}

class _GradientPreviewCard extends StatelessWidget {
  final GradientStyle style;

  const _GradientPreviewCard({required this.style});

  String _getStyleName() {
    switch (style) {
      case GradientStyle.skyBlue:
        return 'Sky Blue\n(Original)';
      case GradientStyle.professional:
        return 'Professional';
      case GradientStyle.vibrant:
        return 'Vibrant';
      case GradientStyle.ocean:
        return 'Ocean';
      case GradientStyle.pastel:
        return 'Pastel';
      case GradientStyle.turquoise:
        return 'Turquoise';
      case GradientStyle.minimal:
        return 'Minimal';
      case GradientStyle.dramatic:
        return 'Dramatic';
      case GradientStyle.gdrawer:
        return 'GDrawer';
      case GradientStyle.gjayli:
        return 'GJayli';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${_getStyleName()}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GradientBackground(
            style: style,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStyleName(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
