import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 🚀 ENUMS PARA ESTADOS DEL BOTÓN
enum ButtonState {
  idle, // Estado normal
  loading, // Cargando (muestra CircularProgressIndicator)
  success, // Éxito (opcional, muestra ícono de check)
  error, // Error (opcional, muestra ícono de error)
}

// 🚀 CONSTANTES
class CustomButtonConstants {
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 18.0;
  static const double defaultHeight = 30.0;
}

// 🚀 SUPER CUSTOM BUTTON - FUSIÓN COMPLETA
// ✅ Base: core/widgets (4 estados, gradientes, animaciones complejas)
// ✅ Nuevas características de auth/widgets:
//    - Soporte SVG/PNG (iconPath)
//    - Variante Outlined (isOutlined)
//    - Glow Effect (enableGlow, glowOnPressOnly, glowColor, glowIntensity)
class CustomButton extends StatefulWidget {
  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES BÁSICAS
  // ═══════════════════════════════════════════════════════════════════════
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE ESTADO Y LOADING
  // ═══════════════════════════════════════════════════════════════════════
  final ButtonState buttonState;
  final String? loadingText;
  final String? successText;
  final String? errorText;
  final Color? loadingIndicatorColor;
  final double? loadingIndicatorSize;
  final Duration? stateResetDuration;

  // 🆕 COMPATIBILIDAD: Alternativa simple al buttonState para loading
  final bool isLoading;

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE ESTILO
  // ═══════════════════════════════════════════════════════════════════════
  final Gradient? gradient;
  final Color? backgroundColor; // Para un fondo sólido
  final Color? borderColor;
  final double borderWidth;
  final double? width;
  final double? height;
  final double? borderRadius;

  // 🆕 VARIANTE OUTLINED (del auth/widgets)
  final bool isOutlined;

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE ÍCONOS
  // ═══════════════════════════════════════════════════════════════════════

  /// Widget personalizado para el ícono (tiene prioridad sobre iconPath)
  /// Se muestra solo en estado idle
  final Widget? icon;

  /// 🆕 Ruta del asset del ícono (soporta PNG y SVG)
  /// Ejemplo: 'assets/logos/google_logo.png' o 'assets/icons/icon.svg'
  final String? iconPath;

  /// 🆕 Tamaño del ícono cuando se usa iconPath
  final double iconSize;

  final Color? iconColor;

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE TEXTO
  // ═══════════════════════════════════════════════════════════════════════
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? textColor;
  final FontWeight? fontWeight;
  final double? fontSize;
  final String? fontFamily;

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE ANIMACIÓN Y FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════
  final Duration animationDuration;
  final bool showHapticFeedback;

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE SOMBRAS
  // ═══════════════════════════════════════════════════════════════════════
  final bool enableShadows;

  /// 🆕 Glow (neón suave) que se adapta al borde (del auth/widgets)
  final bool enableGlow;

  /// 🆕 Solo activar glow al presionar
  final bool glowOnPressOnly;

  /// 🆕 Color del glow (si no se especifica, usa borderColor)
  final Color? glowColor;

  /// 🆕 Intensidad del glow (0.0 - 1.0 recomendado)
  final double glowIntensity;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,

    // Estado
    this.enabled = true,
    this.buttonState = ButtonState.idle,
    this.isLoading = false, // 🆕 Compatibilidad simple
    this.loadingText,
    this.successText,
    this.errorText,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize,
    this.stateResetDuration,

    // Estilo
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.borderRadius,
    this.isOutlined = false, // 🆕

    // Íconos
    this.icon,
    this.iconPath, // 🆕
    this.iconSize = 18, // 🆕
    this.iconColor,

    // Texto
    this.padding,
    this.textStyle,
    this.textColor,
    this.fontWeight,
    this.fontSize,
    this.fontFamily, // 🆕

    // Animación
    this.animationDuration = CustomButtonConstants.defaultAnimationDuration,
    this.showHapticFeedback = true,

    // Sombras y Glow
    this.enableShadows = true,
    this.enableGlow = false, // 🆕
    this.glowOnPressOnly = false, // 🆕
    this.glowColor, // 🆕
    this.glowIntensity = 0.65, // 🆕
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isFlashing = false;

  late AnimationController _animationController;
  late AnimationController _flashController;
  late Animation<double> _shadowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _flashBorderAnimation;
  late Animation<double> _borderWidthAnimation;
  late Animation<double> _flashBorderWidthAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _borderColorAnimation =
        ColorTween(
          begin: widget.borderColor,
          end: _getPressedBorderColor(),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _flashBorderAnimation =
        ColorTween(
          begin: widget.borderColor,
          end: _getPressedBorderColor(),
        ).animate(
          CurvedAnimation(
            parent: _flashController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _borderWidthAnimation =
        Tween<double>(
          begin: widget.borderWidth,
          end: widget.borderWidth * 1.5,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _flashBorderWidthAnimation =
        Tween<double>(
          begin: widget.borderWidth,
          end: widget.borderWidth * 1.5,
        ).animate(
          CurvedAnimation(
            parent: _flashController,
            curve: Curves.fastOutSlowIn,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONSTRUCCIÓN DEL CONTENIDO POR ESTADO
  // ═══════════════════════════════════════════════════════════════════════

  ButtonState get _effectiveState {
    // Compatibilidad: isLoading tiene prioridad si está en true
    if (widget.isLoading) return ButtonState.loading;
    return widget.buttonState;
  }

  Widget _buildButtonContent() {
    switch (_effectiveState) {
      case ButtonState.loading:
        return _buildLoadingContent();
      case ButtonState.success:
        return _buildSuccessContent();
      case ButtonState.error:
        return _buildErrorContent();
      case ButtonState.idle:
        return _buildIdleContent();
    }
  }

  Widget _buildIdleContent() {
    final textWidget = Text(
      widget.text,
      style: _getTextStyle(),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );

    // 🆕 Soporte para íconos custom (widget, SVG, PNG)
    final iconWidget = _buildIcon();
    if (iconWidget == null) return textWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Flexible(child: textWidget),
      ],
    );
  }

  /// 🆕 Construye el widget del ícono basándose en icon o iconPath
  Widget? _buildIcon() {
    // Prioridad 1: Widget personalizado
    if (widget.icon != null) return widget.icon;

    // Prioridad 2: iconPath (SVG/PNG)
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

  Widget _buildLoadingContent() {
    final loadingText = widget.loadingText ?? widget.text;
    final indicatorSize = widget.loadingIndicatorSize ?? 16.0;
    final indicatorColor = widget.loadingIndicatorColor ?? Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            loadingText,
            style: _getTextStyle(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    final successText = widget.successText ?? widget.text;
    final textStyle = _getTextStyle();
    final iconColor = widget.iconColor ?? Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            successText,
            style: textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    final errorText = widget.errorText ?? widget.text;
    final textStyle = _getTextStyle();
    final iconColor = widget.iconColor ?? Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            errorText,
            style: textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MANEJO DE EVENTOS
  // ═══════════════════════════════════════════════════════════════════════

  bool _isButtonEnabled() {
    return widget.enabled && _effectiveState == ButtonState.idle;
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isButtonEnabled()) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    if (!_isButtonEnabled()) return;

    if (widget.showHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _triggerFlashEffect();
    widget.onPressed?.call();
  }

  void _triggerFlashEffect() {
    setState(() => _isFlashing = true);

    _flashController.forward().then((_) {
      _flashController.reverse().then((_) {
        if (mounted) {
          setState(() => _isFlashing = false);
        }
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // 🆕 Soporte para variante outlined
    if (widget.isOutlined) {
      return _buildOutlinedButton();
    }
    return _buildFilledButton();
  }

  /// Botón filled (original)
  Widget _buildFilledButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _flashController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? CustomButtonConstants.defaultHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? CustomButtonConstants.defaultBorderRadius,
              ),
              boxShadow: _buildShadows(),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? CustomButtonConstants.defaultBorderRadius,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleTap,
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.enabled
                          ? widget.gradient
                          : _getDisabledGradient(),
                      border: widget.borderColor != null
                          ? Border.all(
                              color: _getCurrentBorderColor(),
                              width: _getCurrentBorderWidth(),
                            )
                          : null,
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius ?? CustomButtonConstants.defaultBorderRadius,
                      ),
                      color: widget.backgroundColor ?? Colors.white,
                    ),
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(child: _buildButtonContent()),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🆕 Botón outlined
  Widget _buildOutlinedButton() {
    // final borderColor = widget.borderColor ?? Colors.blue;

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _flashController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? CustomButtonConstants.defaultHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? CustomButtonConstants.defaultBorderRadius,
              ),
              boxShadow: _buildShadows(),
            ),
            child: OutlinedButton(
              onPressed: _isButtonEnabled() ? _handleTap : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _getCurrentBorderColor(),
                  width: _getCurrentBorderWidth(),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? CustomButtonConstants.defaultBorderRadius,
                  ),
                ),
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.transparent,
              ),
              child: _buildButtonContent(),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS DE ESTILO
  // ═══════════════════════════════════════════════════════════════════════

  Gradient _getDisabledGradient() {
    return LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]);
  }

  TextStyle _getTextStyle() {
    final defaultStyle = TextStyle(
      fontSize: widget.fontSize ?? 10,
      fontWeight: widget.fontWeight ?? FontWeight.w600,
      fontFamily: widget.fontFamily,
      color: widget.textColor ??
          (widget.enabled ? Colors.white : Colors.grey.shade600),
      height: 1.2,
    );

    return widget.textStyle != null
        ? defaultStyle.merge(widget.textStyle)
        : defaultStyle;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SOMBRAS Y GLOW
  // ═══════════════════════════════════════════════════════════════════════

  List<BoxShadow>? _buildShadows() {
    if (!widget.enabled) return null;

    final List<BoxShadow> shadows = [];

    // 🆕 GLOW EFFECT (del auth/widgets)
    final shouldGlow = widget.enableGlow && (!widget.glowOnPressOnly || _isPressed);
    if (shouldGlow) {
      final glowBase = widget.glowColor ?? widget.borderColor ?? Colors.blue;
      final t = widget.glowIntensity.clamp(0.0, 1.0);
      final pressBoost = _isPressed ? 1.15 : 1.0;

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

    // SOMBRAS NORMALES (solo si enableShadows está activo)
    if (widget.enableShadows) {
      final double intensity = _shadowAnimation.value;
      final Color shadowColor = _getShadowColorFromBorder();

      if (_isPressed) {
        shadows.addAll([
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35 + (intensity * 0.15)),
            offset: const Offset(0, 2),
            blurRadius: 6 + (intensity * 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            offset: const Offset(-1, -1),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ]);
      } else {
        shadows.addAll([
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            offset: const Offset(3, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.5),
            offset: const Offset(1, 1),
            blurRadius: 4,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-2, -2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ]);
      }
    }

    return shadows.isEmpty ? null : shadows;
  }

  Color _getShadowColorFromBorder() {
    if (widget.borderColor != null) {
      final borderColor = widget.borderColor!;

      // Colores específicos predefinidos
      if (borderColor == Colors.blue || borderColor == const Color(0xFF1976D2)) {
        return const Color(0xFF0D47A1);
      } else if (borderColor == Colors.red || borderColor == const Color(0xFFD32F2F)) {
        return const Color(0xFF8D1E1E);
      } else if (borderColor == Colors.green || borderColor == const Color(0xFF4CAF50)) {
        return const Color(0xFF1B5E20);
      } else if (borderColor == Colors.purple || borderColor == const Color(0xFF9C27B0)) {
        return const Color(0xFF4A148C);
      } else {
        HSLColor hsl = HSLColor.fromColor(borderColor);
        return HSLColor.fromAHSL(
          1.0,
          hsl.hue,
          (hsl.saturation * 0.9).clamp(0.0, 1.0),
          (hsl.lightness * 0.25).clamp(0.0, 0.4),
        ).toColor();
      }
    }

    if (widget.gradient is LinearGradient) {
      final linearGradient = widget.gradient as LinearGradient;
      final firstColor = linearGradient.colors.first;

      HSLColor hsl = HSLColor.fromColor(firstColor);
      return HSLColor.fromAHSL(
        1.0,
        hsl.hue,
        (hsl.saturation * 0.9).clamp(0.0, 1.0),
        (hsl.lightness * 0.25).clamp(0.0, 0.4),
      ).toColor();
    }

    return const Color(0xFF424242);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS DE BORDE
  // ═══════════════════════════════════════════════════════════════════════

  double _getCurrentBorderWidth() {
    if (_isFlashing) {
      return _flashBorderWidthAnimation.value;
    }

    if (_isPressed) {
      return _borderWidthAnimation.value;
    }

    return widget.borderWidth;
  }

  Color _getCurrentBorderColor() {
    if (widget.borderColor == null) return Colors.transparent;

    if (_isFlashing) {
      return _flashBorderAnimation.value ?? widget.borderColor!;
    }

    if (_isPressed) {
      return _borderColorAnimation.value ?? widget.borderColor!;
    }

    return widget.borderColor!;
  }

  Color? _getPressedBorderColor() {
    if (widget.borderColor == null) return null;
    return Colors.green;
  }
}
