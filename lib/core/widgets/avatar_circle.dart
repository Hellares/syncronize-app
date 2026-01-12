import 'package:flutter/material.dart';

class AvatarCircle extends StatelessWidget {
  final String? text; // Nombre o texto del que sacamos la inicial (opcional si se usa customChild)
  final double size;
  final String? imageUrl; // ✅ Imagen opcional
  final List<Color>? colors;
  final double fontSize;
  final Widget? customChild; // ✅ Widget personalizado (ej: icono)
  final bool enableShadow;
  final Color? shadowColor;

  const AvatarCircle({
    super.key,
    this.text,
    this.size = 20,
    this.imageUrl,
    this.colors,
    this.fontSize = 10,
    this.customChild,
    this.enableShadow = true,
    this.shadowColor,
  }) : assert(
          text != null || customChild != null,
          'Debe proporcionar text o customChild',
        );

  /// Extrae las dos iniciales del texto
  String _getInitials() {
    if (text == null || text!.isEmpty) return '?';

    final words = text!.trim().split(RegExp(r'\s+'));

    if (words.isEmpty) return '?';

    if (words.length == 1) {
      // Si solo hay una palabra, tomar las dos primeras letras
      final word = words[0];
      if (word.length >= 2) {
        return '${word[0]}${word[1]}'.toUpperCase();
      } else {
        return word[0].toUpperCase();
      }
    } else {
      // Si hay dos o más palabras, tomar la primera letra de las dos primeras palabras
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _getInitials();

    // Determinar el color de la sombra
    final effectiveShadowColor = shadowColor ??
        (colors != null && colors!.isNotEmpty
            ? colors!.first
            : Colors.blue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: colors != null
            ? LinearGradient(
                colors: colors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.blue[400]!,
                  Colors.blue[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color: effectiveShadowColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: customChild ??
                  Text(
                    displayText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            )
          : null,
    );
  }
}
