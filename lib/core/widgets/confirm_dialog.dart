import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/gradient_container.dart';

/// Tipo semántico del dialog. Determina el color del borde, sombra,
/// header e icono por defecto.
enum ConfirmDialogType {
  /// Acción irreversible / borrar (rojo).
  destructive,

  /// Advertencia / confirmar acción riesgosa (naranja).
  warning,

  /// Confirmación de operación exitosa o positiva (verde).
  success,

  /// Información o neutro (azul).
  info,
}

/// Dialog de confirmación con `GradientContainer` + borde y sombra
/// coloreada según el tipo, header con ícono coloreado, mensaje y
/// botones Cancelar / Confirmar.
///
/// Replica el estilo del cierre de caja (`cerrar_caja_page.dart`).
///
/// Uso básico:
/// ```dart
/// final ok = await ConfirmDialog.show(
///   context: context,
///   type: ConfirmDialogType.destructive,
///   title: 'Eliminar producto',
///   message: '¿Estás seguro? Esta acción no se puede deshacer.',
///   confirmText: 'Eliminar',
/// );
/// ```
///
/// Para casos con contenido custom (bullets, info boxes, TextField),
/// usar `customContent` en vez de `message`:
/// ```dart
/// final ok = await ConfirmDialog.show(
///   context: context,
///   type: ConfirmDialogType.warning,
///   title: 'Convertir a variantes',
///   customContent: Column(children: [...]),
///   confirmText: 'Convertir',
/// );
/// ```
class ConfirmDialog {
  /// Muestra el dialog y devuelve `true` si el usuario confirmó,
  /// `false` o `null` si canceló o cerró con el barrier.
  static Future<bool?> show({
    required BuildContext context,
    required ConfirmDialogType type,
    required String title,
    String? message,
    Widget? customContent,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    final accent = _accentColor(type);
    final defaultIcon = _defaultIcon(type);

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GradientContainer(
          borderColor: accent.withValues(alpha: 0.4),
          borderWidth: 1,
          customShadows: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
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
              // Header con icono + título coloreado por el tipo.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon ?? defaultIcon,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              if (message != null || customContent != null) ...[
                const SizedBox(height: 10),
                if (customContent != null)
                  customContent
                else
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.blue3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(true),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentColor(ConfirmDialogType type) {
    switch (type) {
      case ConfirmDialogType.destructive:
        return AppColors.red;
      case ConfirmDialogType.warning:
        return AppColors.orange;
      case ConfirmDialogType.success:
        return AppColors.green;
      case ConfirmDialogType.info:
        return AppColors.blue3;
    }
  }

  static IconData _defaultIcon(ConfirmDialogType type) {
    switch (type) {
      case ConfirmDialogType.destructive:
        return Icons.delete_outline_rounded;
      case ConfirmDialogType.warning:
        return Icons.warning_amber_rounded;
      case ConfirmDialogType.success:
        return Icons.check_circle_outline_rounded;
      case ConfirmDialogType.info:
        return Icons.info_outline_rounded;
    }
  }
}
