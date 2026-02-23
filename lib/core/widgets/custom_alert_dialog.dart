import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Diálogo de alerta reutilizable y personalizable.
///
/// Uso básico:
/// ```dart
/// final result = await CustomAlertDialog.show<bool>(
///   context: context,
///   title: '¿Descartar cambios?',
///   content: 'Tienes cambios sin guardar.',
///   cancelText: 'Cancelar',
///   confirmText: 'Descartar',
///   confirmColor: Colors.red,
/// );
/// ```
class CustomAlertDialog extends StatelessWidget {
  /// Título como String (se convierte a Text internamente)
  final String? titleText;

  /// Título como Widget (tiene prioridad sobre titleText)
  final Widget? title;

  /// Contenido como String (se convierte a Text internamente)
  final String? contentText;

  /// Contenido como Widget (tiene prioridad sobre contentText)
  final Widget? content;

  /// Acciones personalizadas (tiene prioridad sobre cancel/confirm)
  final List<Widget>? actions;

  /// Texto del botón cancelar
  final String cancelText;

  /// Texto del botón confirmar
  final String? confirmText;

  /// Color del texto del botón cancelar
  final Color? cancelColor;

  /// Color del texto del botón confirmar
  final Color? confirmColor;

  /// Valor retornado al presionar cancelar
  final dynamic cancelValue;

  /// Valor retornado al presionar confirmar
  final dynamic confirmValue;

  /// Color de fondo del diálogo
  final Color? backgroundColor;

  /// Color del borde
  final Color? borderColor;

  /// Ancho del borde
  final double borderWidth;

  /// Radio de las esquinas
  final double borderRadius;

  /// Padding del contenido
  final EdgeInsets? contentPadding;

  /// Padding de las acciones
  final EdgeInsets? actionsPadding;

  /// Estilo del texto del título
  final TextStyle? titleTextStyle;

  /// Estilo del texto del contenido
  final TextStyle? contentTextStyle;

  /// Elevación del diálogo
  final double? elevation;

  /// Ícono opcional junto al título
  final IconData? titleIcon;

  /// Color del ícono del título
  final Color? titleIconColor;

  /// Tamaño del ícono del título
  final double titleIconSize;

  const CustomAlertDialog({
    super.key,
    this.titleText,
    this.title,
    this.contentText,
    this.content,
    this.actions,
    this.cancelText = 'Cancelar',
    this.confirmText,
    this.cancelColor,
    this.confirmColor,
    this.cancelValue = false,
    this.confirmValue = true,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 16.0,
    this.contentPadding,
    this.actionsPadding,
    this.titleTextStyle,
    this.contentTextStyle,
    this.elevation,
    this.titleIcon,
    this.titleIconColor,
    this.titleIconSize = 24,
  });

  /// Método estático para mostrar el diálogo de forma sencilla.
  static Future<T?> show<T>({
    required BuildContext context,
    String? titleText,
    Widget? title,
    String? contentText,
    Widget? content,
    List<Widget>? actions,
    String cancelText = 'Cancelar',
    String? confirmText,
    Color? cancelColor,
    Color? confirmColor,
    dynamic cancelValue = false,
    dynamic confirmValue = true,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 16.0,
    EdgeInsets? contentPadding,
    EdgeInsets? actionsPadding,
    TextStyle? titleTextStyle,
    TextStyle? contentTextStyle,
    double? elevation,
    IconData? titleIcon,
    Color? titleIconColor,
    double titleIconSize = 24,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => CustomAlertDialog(
        titleText: titleText,
        title: title,
        contentText: contentText,
        content: content,
        actions: actions,
        cancelText: cancelText,
        confirmText: confirmText,
        cancelColor: cancelColor,
        confirmColor: confirmColor,
        cancelValue: cancelValue,
        confirmValue: confirmValue,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
        titleTextStyle: titleTextStyle,
        contentTextStyle: contentTextStyle,
        elevation: elevation,
        titleIcon: titleIcon,
        titleIconColor: titleIconColor,
        titleIconSize: titleIconSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolver título
    Widget? resolvedTitle;
    if (title != null) {
      resolvedTitle = title;
    } else if (titleText != null) {
      final textWidget = Text(
        titleText!,
        style: titleTextStyle,
      );
      if (titleIcon != null) {
        resolvedTitle = Row(
          children: [
            Icon(titleIcon, color: titleIconColor, size: titleIconSize),
            const SizedBox(width: 10),
            Expanded(child: textWidget),
          ],
        );
      } else {
        resolvedTitle = textWidget;
      }
    }

    // Resolver contenido
    Widget? resolvedContent;
    if (content != null) {
      resolvedContent = content;
    } else if (contentText != null) {
      resolvedContent = Text(
        contentText!,
        style: contentTextStyle,
      );
    }

    // Resolver acciones
    final resolvedActions = actions ??
        [
          TextButton(
            onPressed: () => Navigator.of(context).pop(cancelValue),
            child: Text(
              cancelText,
              style: cancelColor != null ? TextStyle(color: cancelColor) : null,
            ),
          ),
          if (confirmText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(confirmValue),
              style: confirmColor != null
                  ? TextButton.styleFrom(foregroundColor: confirmColor)
                  : null,
              child: Text(confirmText!),
            ),
        ];

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: borderColor != null
          ? BorderSide(color: borderColor!, width: borderWidth)
          : BorderSide.none,
    );

    return AlertDialog(
      backgroundColor: backgroundColor ?? AppColors.white,
      elevation: elevation,
      shape: shape,
      title: resolvedTitle,
      titleTextStyle: titleTextStyle,
      content: resolvedContent,
      contentTextStyle: contentTextStyle,
      contentPadding: contentPadding ??
          const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: actionsPadding ??
          const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: resolvedActions,
    );
  }
}
