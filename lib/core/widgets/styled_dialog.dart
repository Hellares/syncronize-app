import 'package:flutter/material.dart';
import '../theme/gradient_container.dart';

/// Dialog estilizado reutilizable con GradientContainer, borde de color
/// y sombra sutil. Mismo estilo que los dialogs de cierre de caja.
///
/// Uso:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => StyledDialog(
///     accentColor: AppColors.blue1,
///     icon: Icons.discount_outlined,
///     titulo: 'Aplicar Descuento',
///     content: [...widgets...],
///     actions: [...buttons...],
///   ),
/// );
/// ```
///
/// Los tamaños del encabezado (`iconSize`, `tituloSize`, `subtituloSize`)
/// vienen con el default de siempre y se pasan solo cuando un diálogo puntual
/// necesita otra cosa.
class StyledDialog extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String titulo;

  /// Segunda línea del encabezado, en gris y chica. Para el contexto que el
  /// título no puede cargar sin volverse ilegible: de qué producto es la
  /// variante que se está editando, de qué cliente la deuda, etc.
  final String? subtitulo;

  final List<Widget> content;
  final List<Widget> actions;
  final bool barrierDismissible;

  /// Fondo sólido opcional (p.ej. blanco para que el acento resalte).
  /// Null = gradiente default del GradientContainer.
  final Color? backgroundColor;

  /// Tamaños del encabezado. Los defaults son los de siempre; se tocan cuando
  /// un diálogo puntual lo pide —un título largo que necesita respirar, o uno
  /// muy corto al que le queda bien más presencia—.
  ///
  /// 🔑 La caja tintada del ícono NO se fija: envuelve al ícono con su padding,
  /// así que crece y se achica sola con [iconSize] y no hay dos números que
  /// mantener en sincronía.
  final double iconSize;
  final double tituloSize;
  final double subtituloSize;

  /// Ancho fijo del diálogo.
  ///
  /// `null` (default) = **lo decide el contenido**: el diálogo se encoge hasta
  /// el hijo más ancho, que es por lo que a veces sale angosto sin que nadie
  /// lo haya pedido. Para que ocupe todo lo que da la pantalla:
  /// `ancho: double.infinity`.
  ///
  /// ⚠️ Por debajo de 280 no baja: ese mínimo lo impone el `Dialog` de
  /// Material, no este widget.
  final double? ancho;

  /// Cuánto aire queda a cada costado. Es el TECHO real del ancho: bajarlo es
  /// la forma de ganar pantalla cuando [ancho] queda en null.
  final double margenHorizontal;

  const StyledDialog({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.titulo,
    this.subtitulo,
    required this.content,
    this.actions = const [],
    this.barrierDismissible = true,
    this.backgroundColor,
    this.iconSize = 18,
    this.tituloSize = 13,
    this.subtituloSize = 11,
    this.ancho,
    this.margenHorizontal = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: margenHorizontal,
        vertical: 20,
      ),
      // Con `ancho` en null el SizedBox deja pasar las restricciones tal cual,
      // así que no cambia nada de lo que ya existía.
      child: SizedBox(
        width: ancho,
        child: GradientContainer(
        // GradientContainer no acepta color sólido: se simula con un
        // gradiente plano del mismo color.
        gradient: backgroundColor != null
            ? LinearGradient(colors: [backgroundColor!, backgroundColor!])
            : null,
        borderColor: accentColor.withValues(alpha: 0.4),
        borderWidth: 1,
        customShadows: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.only(top: 8, bottom: 15, left: 10, right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: iconSize),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: tituloSize,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitulo != null)
                        Text(
                          subtitulo!,
                          style: TextStyle(
                            fontSize: subtituloSize,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Content (scrollable: evita overflow cuando aparece el teclado;
            // el header y las acciones quedan fijos).
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
              ),
            ),
            // Actions
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: actions
                    .expand((a) => [a, const SizedBox(width: 8)])
                    .toList()
                  ..removeLast(),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Color accentColor,
    required IconData icon,
    required String titulo,
    String? subtitulo,
    required List<Widget> content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    Color? backgroundColor,
    double iconSize = 18,
    double tituloSize = 13,
    double subtituloSize = 11,
    double? ancho,
    double margenHorizontal = 24,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => StyledDialog(
        accentColor: accentColor,
        icon: icon,
        titulo: titulo,
        subtitulo: subtitulo,
        content: content,
        actions: actions,
        backgroundColor: backgroundColor,
        iconSize: iconSize,
        tituloSize: tituloSize,
        subtituloSize: subtituloSize,
        ancho: ancho,
        margenHorizontal: margenHorizontal,
      ),
    );
  }
}
