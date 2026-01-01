import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/animated_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';

/// Dialog de confirmación con borde animado
///
/// Ejemplo de uso:
/// ```dart
/// AnimatedConfirmDialog.show(
///   context: context,
///   title: 'Eliminar producto',
///   message: '¿Estás seguro de eliminar este producto?',
///   confirmText: 'Eliminar',
///   onConfirm: () {
///     // Acción de confirmación
///   },
/// );
/// ```
class AnimatedConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? cancelText;
  final String? confirmText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showConfirmButton;

  // Configuración del borde animado
  final double borderRadius;
  final double borderWidth;
  final List<Color>? borderColors;
  final Duration animationDuration;
  final bool enableGlow;

  // Configuración de colores de botones
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;
  final Color? titleColor;

  // Configuración del dialog
  final double maxWidth;
  final Color barrierColor;

  // Highlight (franja brillante que recorre el borde)
  final bool enableHighlight;
  final double highlightWidth; // 0..1 (ancho de la franja)
  final double highlightOpacity; // 0..1 (intensidad)

  const AnimatedConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText,
    this.confirmText,
    this.onConfirm,
    this.onCancel,
    this.showConfirmButton = true,
    // Borde animado
    this.borderRadius = 14,
    this.borderWidth = 1.5,
    this.borderColors,
    this.animationDuration = const Duration(seconds: 5),
    this.enableGlow = false,
    // Colores
    this.confirmButtonColor,
    this.cancelButtonColor,
    this.titleColor,
    // Dialog
    this.maxWidth = 420,
    this.barrierColor = const Color(
      0x1A000000,
    ), // Colors.black.withValues(alpha: 0.1)

    this.enableHighlight = true,
    this.highlightWidth = 0.12,
    this.highlightOpacity = 0.85,
  });

  /// Método estático para mostrar el dialog fácilmente
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showConfirmButton = true,
    double borderRadius = 14,
    double borderWidth = 1.3,
    List<Color>? borderColors,
    Duration animationDuration = const Duration(seconds: 5),
    bool enableGlow = false,
    Color? confirmButtonColor,
    Color? cancelButtonColor,
    Color? titleColor,
    double maxWidth = 420,
    Color barrierColor = const Color(0x1A000000),
    bool enableHighlight = true,
    double highlightWidth = 0.12,
    double highlightOpacity = 0.9,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: barrierColor,
      builder: (dialogContext) => AnimatedConfirmDialog(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showConfirmButton: showConfirmButton,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderColors: borderColors,
        animationDuration: animationDuration,
        enableGlow: enableGlow,
        confirmButtonColor: confirmButtonColor,
        cancelButtonColor: cancelButtonColor,
        titleColor: titleColor,
        maxWidth: maxWidth,
        barrierColor: barrierColor,
        enableHighlight: enableHighlight,
        highlightWidth: highlightWidth,
        highlightOpacity: highlightOpacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedNeonBorder(
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        padding: EdgeInsets.all(borderWidth),
        enableGlow: enableGlow,
        enableHighlight: enableHighlight,
        highlightWidth: highlightWidth,
        highlightOpacity: highlightOpacity,
        duration: animationDuration,
        colors: borderColors ?? _defaultBorderColors,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              AppTitle(
                title,
                fontSize: 14,
                color: titleColor ?? AppColors.blue1,
              ),
              const SizedBox(height: 12),

              // Mensaje/Contenido
              AppLabelText(message, fontSize: 11),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón Cancelar
                  CustomButton(
                    text: cancelText ?? 'Cancelar',
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      }
                      Navigator.of(context).pop(false);
                    },
                    backgroundColor: Colors.transparent,
                    borderColor: cancelButtonColor ?? AppColors.blue3,
                    borderWidth: 0.6,
                    textColor: cancelButtonColor ?? AppColors.blue3,
                    enableShadows: false,
                  ),

                  if (showConfirmButton) ...[
                    const SizedBox(width: 8),
                    // Botón Confirmar
                    CustomButton(
                      text: confirmText ?? 'Confirmar',
                      onPressed: () {
                        if (onConfirm != null) {
                          onConfirm!();
                        }
                        Navigator.of(context).pop(true);
                      },
                      backgroundColor: confirmButtonColor ?? AppColors.red,
                      borderColor: confirmButtonColor ?? AppColors.red,
                      borderWidth: 0.6,
                      textColor: Colors.white,
                      enableShadows: false,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Colores por defecto del borde animado
  static const List<Color> _defaultBorderColors = [
    Color(0xFF00E5FF),
    Color(0xFF2979FF),
    Color(0xFF00E676),
  ];
}
