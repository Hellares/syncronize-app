import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  final Color? backgroundColor;
  final Color? textColor;

  final Color? borderColor;
  final double borderWidth;

  final double? width;
  final double height;

  /// Widget personalizado para el ícono (tiene prioridad sobre iconPath)
  final Widget? icon;

  /// Ruta del asset del ícono (soporta PNG y SVG)
  /// Ejemplo: 'assets/logos/google_logo.png' o 'assets/icons/icon.svg'
  final String? iconPath;

  /// Tamaño del ícono cuando se usa iconPath
  final double iconSize;

  final bool enableHaptics;

  /// Sombra “normal” (más material)
  final bool enableShadow;

  /// ✅ Glow (neón suave) que se adapta al borde
  final bool enableGlow;
  final bool glowOnPressOnly;
  final Color? glowColor;
  final double glowIntensity; // 0.0 - 1.0 recomendado

  final Duration animationDuration;

  final double borderRadius;
  final double fontSize;
  final String? fontFamily;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 2,
    this.width,
    this.height = 40,
    this.icon,
    this.iconPath,
    this.iconSize = 20,
    this.enableHaptics = true,
    this.enableShadow = true,

    // ✅ Glow
    this.enableGlow = false,
    this.glowOnPressOnly = false,
    this.glowColor,
    this.glowIntensity = 0.65,
    this.borderRadius = 20,
    this.fontSize = 12,
    this.fontFamily,
    this.animationDuration = const Duration(milliseconds: 160),
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool v) {
    if (!_enabled) return;
    setState(() => _pressed = v);
  }

  void _tap() {
    if (!_enabled) return;
    if (widget.enableHaptics) HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primary = widget.backgroundColor ?? theme.primaryColor;
    final onPrimary = widget.textColor ?? Colors.white;

    final btnWidth = widget.width ?? double.infinity;
    final borderRadius = BorderRadius.circular(widget.borderRadius);

    final effectiveBorderColor = widget.borderColor ?? primary;
    final effectiveTextColor =
        widget.isOutlined ? (widget.textColor ?? effectiveBorderColor) : onPrimary;

    final filledStyle = ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      disabledBackgroundColor: primary.withValues(alpha: 0.45),
      disabledForegroundColor: onPrimary.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );

    final outlinedStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: effectiveBorderColor, width: widget.borderWidth),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );

    Widget innerButton;
    if (widget.isOutlined) {
      innerButton = OutlinedButton(
        onPressed: _enabled ? _tap : null,
        style: outlinedStyle,
        child: _AnimatedContent(
          isLoading: widget.isLoading,
          duration: widget.animationDuration,
          loaderColor: effectiveBorderColor,
          child: _buildContent(effectiveTextColor),
        ),
      );
    } else {
      innerButton = ElevatedButton(
        onPressed: _enabled ? _tap : null,
        style: filledStyle,
        child: _AnimatedContent(
          isLoading: widget.isLoading,
          duration: widget.animationDuration,
          loaderColor: onPrimary,
          child: _buildContent(effectiveTextColor),
        ),
      );
    }

    // Filled puede tener borde externo si se pasa borderColor
    final shouldDrawOuterBorder = !widget.isOutlined && widget.borderColor != null;

    final boxShadows = _buildShadows(
      enabled: _enabled,
      isOutlined: widget.isOutlined,
      primary: primary,
      borderColor: effectiveBorderColor,
    );

    return SizedBox(
  width: btnWidth,
  height: widget.height,
  child: AnimatedScale(
    scale: _pressed ? 0.985 : 1.0,
    duration: widget.animationDuration,
    curve: Curves.easeOut,
    child: Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: DecoratedBox(
        // ✅ glow + sombras atrás
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadows,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ Clip del contenido/botón
            ClipRRect(
              borderRadius: borderRadius,
              child: Padding(
                // ✅ si hay borde externo, separa el botón para que NO lo tape
                padding: shouldDrawOuterBorder
                    ? EdgeInsets.all(widget.borderWidth)
                    : EdgeInsets.zero,
                child: innerButton,
              ),
            ),

            // ✅ borde externo por encima (no lo tapa el botón)
            if (shouldDrawOuterBorder)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: effectiveBorderColor,
                      width: widget.borderWidth,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  ),
);

  }

  List<BoxShadow>? _buildShadows({
    required bool enabled,
    required bool isOutlined,
    required Color primary,
    required Color borderColor,
  }) {
    if (!enabled) return null;

    final List<BoxShadow> shadows = [];

    // ✅ Glow adaptado al borde (o color custom si lo pasas)
    final shouldGlow = widget.enableGlow && (!widget.glowOnPressOnly || _pressed);
    if (shouldGlow) {
      final glowBase = widget.glowColor ?? borderColor;

      // Glow intensity ajustada + un poquito más si está presionado
      final t = widget.glowIntensity.clamp(0.0, 1.0);
      final pressBoost = _pressed ? 1.15 : 1.0;

      // capas: una grande suave + una más concentrada
      shadows.addAll([
        BoxShadow(
          color: glowBase.withValues(alpha: (0.22 * t) * pressBoost),
          blurRadius: (22.0 + 18.0 * t) * pressBoost,
          spreadRadius: (1.5 + 2.0 * t) * pressBoost,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: glowBase.withValues(alpha: (0.14 * t) * pressBoost),
          blurRadius: (10.0 + 10.0 * t) * pressBoost,
          spreadRadius: (0.6 + 1.2 * t) * pressBoost,
          offset: const Offset(0, 0),
        ),
      ]);
    }

    // Sombra "material" solo para filled (opcional)
    if (!isOutlined && widget.enableShadow) {
      shadows.add(
        BoxShadow(
          color: Colors.black.withValues(alpha: _pressed ? 0.08 : 0.12),
          blurRadius: _pressed ? 10 : 14,
          offset: Offset(0, _pressed ? 3 : 6),
        ),
      );
    }

    return shadows.isEmpty ? null : shadows;
  }

  Widget _buildContent(Color color) {
    final textWidget = Text(
      widget.text,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w500,
        fontFamily: widget.fontFamily,
        color: color,
        height: 1.1,
      ),
      overflow: TextOverflow.ellipsis,
    );

    // Prioridad: widget.icon > iconPath
    final iconWidget = _buildIcon();
    if (iconWidget == null) return textWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Flexible(child: textWidget),
      ],
    );
  }

  /// Construye el widget del ícono basándose en icon o iconPath
  Widget? _buildIcon() {
    // Si se proporciona un widget personalizado, usarlo primero
    if (widget.icon != null) return widget.icon;

    // Si no hay iconPath, retornar null
    if (widget.iconPath == null) return null;

    final path = widget.iconPath!;
    final size = widget.iconSize;

    // Detectar si es SVG por la extensión
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    // Para PNG, JPG, etc.
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _AnimatedContent extends StatelessWidget {
  final bool isLoading;
  final Duration duration;
  final Color loaderColor;
  final Widget child;

  const _AnimatedContent({
    required this.isLoading,
    required this.duration,
    required this.loaderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (w, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
          child: w,
        ),
      ),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loader'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
              ),
            )
          : SizedBox(
              key: const ValueKey('content'),
              child: child,
            ),
    );
  }
}


