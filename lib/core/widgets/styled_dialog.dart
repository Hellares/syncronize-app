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
class StyledDialog extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String titulo;
  final List<Widget> content;
  final List<Widget> actions;
  final bool barrierDismissible;

  const StyledDialog({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.titulo,
    required this.content,
    this.actions = const [],
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GradientContainer(
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
        padding: const EdgeInsets.all(18),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Color accentColor,
    required IconData icon,
    required String titulo,
    required List<Widget> content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => StyledDialog(
        accentColor: accentColor,
        icon: icon,
        titulo: titulo,
        content: content,
        actions: actions,
      ),
    );
  }
}
