import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import '../../../core/theme/app_colors.dart'; // Descomenta según tu estructura

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

// 🚀 WIDGET PRINCIPAL - CON CONTROL DE SOMBRAS
class CustomButton extends StatefulWidget {
  // Propiedades básicas
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  // Propiedades de estado y loading
  final ButtonState buttonState;
  final String? loadingText;
  final String? successText;
  final String? errorText;
  final Color? loadingIndicatorColor;
  final double? loadingIndicatorSize;
  final Duration? stateResetDuration;

  // Propiedades de estilo
  final Gradient? gradient;
  final Color? backgroundColor; // Para un fondo sólido
  final Color? borderColor;
  final double borderWidth;
  final double? width;
  final double? height;
  final double? borderRadius;

  // Propiedades opcionales
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Duration animationDuration;
  final bool showHapticFeedback;

  // 🚀 NUEVA PROPIEDAD PARA CONTROLAR SOMBRAS
  final bool enableShadows;

  // 🚀 PROPIEDADES DE TEXTO PERSONALIZABLES
  final Color? textColor;
  final FontWeight? fontWeight;
  final double? fontSize;

  // 🚀 PROPIEDADES DE ÍCONOS PERSONALIZABLES
  final Color? iconColor;

  const CustomButton({
    super.key,
    required this.text,
    this.gradient,
    this.backgroundColor,
    this.onPressed,
    
    this.enabled = true,
    // Propiedades de estado
    this.buttonState = ButtonState.idle,
    this.loadingText,
    this.successText,
    this.errorText,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize,
    this.stateResetDuration,
    // Propiedades de estilo
    this.borderColor,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.animationDuration = CustomButtonConstants.defaultAnimationDuration,
    this.showHapticFeedback = true,
    // 🚀 CONTROL DE SOMBRAS (POR DEFECTO HABILITADAS)
    this.enableShadows = true,
    // 🚀 PROPIEDADES DE TEXTO PERSONALIZABLES
    this.textColor,
    this.fontWeight,
    this.fontSize,
    // 🚀 PROPIEDADES DE ÍCONOS PERSONALIZABLES
    this.iconColor,
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
          end: widget.borderWidth * 1.5, // 50% más grueso al presionar
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _flashBorderWidthAnimation =
        Tween<double>(
          begin: widget.borderWidth,
          end: widget.borderWidth * 1.5, // 50% más grueso en flash
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

  Widget _buildButtonContent() {
    switch (widget.buttonState) {
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
    return Text(
      widget.text,
      style: _getTextStyle(),
      textAlign: TextAlign.center,
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

  bool _isButtonEnabled() {
    return widget.enabled && widget.buttonState == ButtonState.idle;
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

  @override
  Widget build(BuildContext context) {
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
              // 🚀 SOMBRAS SOLO SI enableShadows ES TRUE
              boxShadow: widget.enableShadows ? _buildShadows() : null,
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

  Gradient _getDisabledGradient() {
    return LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]);
  }

  TextStyle _getTextStyle() {
    final defaultStyle = TextStyle(
      fontSize: widget.fontSize ?? 10,
      fontWeight: widget.fontWeight ?? FontWeight.w600,
      color: widget.textColor ??
          (widget.enabled ? Colors.white : Colors.grey.shade600),
      height: 1.2,
    );

    return widget.textStyle != null
        ? defaultStyle.merge(widget.textStyle)
        : defaultStyle;
  }

  // 🚀 MÉTODO DE SOMBRAS MODIFICADO - RETORNA NULL SI enableShadows ES FALSE
  List<BoxShadow>? _buildShadows() {
    // Si las sombras están deshabilitadas, retornar null
    if (!widget.enableShadows || !widget.enabled) return null;

    final double intensity = _shadowAnimation.value;
    final Color shadowColor = _getShadowColorFromBorder();

    if (_isPressed) {
      return [
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
      ];
    } else {
      return [
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
      ];
    }
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

  double _getCurrentBorderWidth() {
    if (_isFlashing) {
      return _flashBorderWidthAnimation.value;
    }

    if (_isPressed) {
      return _borderWidthAnimation.value;
    }

    // Usar el borderWidth del widget como valor base
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