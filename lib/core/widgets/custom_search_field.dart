import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Widget de búsqueda personalizado con diseño consistente a CustomTextField
/// Permite agregar botones personalizados (limpiar, filtros, etc.)
class CustomSearchField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onClear;
  
  // Estilo y diseño (idéntico a CustomTextField)
  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final Color? iconColor;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool filled;
  final FocusNode? focusNode;
  final double? height;
  final double? borderWidth;
  
  // Iconos y acciones personalizadas
  final IconData searchIcon;
  final IconData? clearIcon;
  final bool showClearButton;
  final List<Widget>? actionButtons; // Botones adicionales (ej: filtros)
  
  // Comportamiento
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Duration debounceDelay;
  
  const CustomSearchField({
    super.key,
    this.label,
    this.hintText = 'Buscar...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.backgroundColor = const Color.fromARGB(255, 255, 255, 255),
    this.borderColor,
    this.borderRadius = 6.0,
    this.iconColor,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.filled = true,
    this.focusNode,
    this.height = 35.0,
    this.borderWidth = 0.5,
    this.searchIcon = Icons.search_rounded,
    this.clearIcon = Icons.close_rounded,
    this.showClearButton = true,
    this.actionButtons,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.debounceDelay = const Duration(milliseconds: 500),
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _hasText = false;
  Timer? _debounceTimer;
  String _lastSearchText = ''; // Para evitar búsquedas duplicadas

  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Cache para optimización
  Color? _cachedBorderColor;
  TextStyle? _cachedTextStyle;
  TextStyle? _cachedHintStyle;
  TextStyle? _cachedLabelStyle;
  BorderRadius? _cachedBorderRadius;
  EdgeInsetsGeometry? _cachedContentPadding;
  List<BoxShadow>? _shadowsCache;
  bool _lastFocusState = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    if (widget.controller != null) {
      _hasText = widget.controller!.text.isNotEmpty;
      _lastSearchText = widget.controller!.text; // Inicializar con el valor actual
      widget.controller!.addListener(_onTextChanged);
    }
  }

  @override
  void didUpdateWidget(CustomSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Invalidar cachés si las propiedades relacionadas con estilos cambiaron
    if (widget.borderColor != oldWidget.borderColor) {
      _cachedBorderColor = null;
      _shadowsCache = null;
    }

    if (widget.textStyle != oldWidget.textStyle) {
      _cachedTextStyle = null;
    }

    if (widget.hintStyle != oldWidget.hintStyle) {
      _cachedHintStyle = null;
    }

    if (widget.labelStyle != oldWidget.labelStyle) {
      _cachedLabelStyle = null;
    }

    if (widget.borderRadius != oldWidget.borderRadius) {
      _cachedBorderRadius = null;
    }

    if (widget.contentPadding != oldWidget.contentPadding) {
      _cachedContentPadding = null;
    }

    // Actualizar listener del controlador si cambió
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      if (widget.controller != null) {
        _hasText = widget.controller!.text.isNotEmpty;
        _lastSearchText = widget.controller!.text; // Actualizar el último texto
        widget.controller!.addListener(_onTextChanged);
      }
    }

    // Actualizar listener del focusNode si cambió
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode.removeListener(_onFocusChange);

      if (widget.focusNode == null) {
        _focusNode.dispose();
        _focusNode = FocusNode();
      } else {
        _focusNode = widget.focusNode!;
      }

      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller != null) {
      widget.controller!.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    
    setState(() {
      _isFocused = _focusNode.hasFocus;
      _cachedBorderColor = null; // Resetear cache del color del borde
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChanged() {
    if (!mounted) return;

    final currentText = widget.controller!.text;
    final hasText = currentText.isNotEmpty;

    // Actualizar estado visual del botón clear
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // Solo disparar onChanged si el texto realmente cambió
    if (currentText == _lastSearchText) {
      return; // No hacer nada si el texto es el mismo
    }

    _lastSearchText = currentText; // Actualizar el último texto

    // Implementar debounce
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDelay, () {
      if (mounted) {
        try {
          widget.onChanged?.call(currentText);
        } catch (e) {
          debugPrint('Error en CustomSearchField.onChanged: $e');
        }
      }
    });
  }

  void _handleClear() {
    widget.controller?.clear();
    _lastSearchText = ''; // Resetear el último texto

    try {
      widget.onClear?.call();
    } catch (e) {
      debugPrint('Error en CustomSearchField.onClear: $e');
    }

    try {
      widget.onChanged?.call('');
    } catch (e) {
      debugPrint('Error en CustomSearchField.onChanged (clear): $e');
    }

    _focusNode.requestFocus();
  }

  void _handleSubmitted(String value) {
    try {
      widget.onSubmitted?.call(value);
    } catch (e) {
      debugPrint('Error en CustomSearchField.onSubmitted: $e');
    }
  }

  // Métodos de estilo (idénticos a CustomTextField)
  Color _getCachedBorderColor() {
    return _cachedBorderColor ??= _getBorderColor();
  }

  Color _getBorderColor() {
    return widget.borderColor ??
        (_isFocused
            ? const Color(0xFFE0E0E0)
            : const Color(0xFFF0F0F0));
  }

  TextStyle _getCachedTextStyle() {
    return _cachedTextStyle ??=
        widget.textStyle ??
        TextStyle(
          color: widget.enabled ? AppColors.blue2 : AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Oxygen-Regular',
        );
  }

  TextStyle _getCachedHintStyle() {
    return _cachedHintStyle ??=
        widget.hintStyle ??
        TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
          fontWeight: FontWeight.w400,
          height: 1.2,
        );
  }

  TextStyle _getCachedLabelStyle() {
    return _cachedLabelStyle ??=
        widget.labelStyle ??
        const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.blue,
        );
  }

  BorderRadius _getCachedBorderRadius() {
    return _cachedBorderRadius ??= BorderRadius.circular(widget.borderRadius);
  }

  EdgeInsetsGeometry _getCachedContentPadding() {
    return _cachedContentPadding ??=
        widget.contentPadding ?? _getDefaultContentPadding();
  }

  EdgeInsetsGeometry _getDefaultContentPadding() {
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 0);
  }

  List<BoxShadow> _getCachedShadows() {
    if (_shadowsCache == null || _lastFocusState != _isFocused) {
      _shadowsCache = _buildShadows();
      _lastFocusState = _isFocused;
    }
    return _shadowsCache!;
  }

  List<BoxShadow> _buildShadows() {
    final borderColor = _getCachedBorderColor();
    Color shadowColor = _getShadowColorFromBorder(borderColor);
    
    // Sombras más pronunciadas cuando está enfocado
    double blurRadius = _isFocused ? 8 : 4;
    double spreadRadius = _isFocused ? 0 : 0;
    double opacity = _isFocused ? 0.15 : 0.08;

    return [
      BoxShadow(
        color: shadowColor.withValues(alpha:opacity),
        blurRadius: blurRadius,
        offset: Offset(0, spreadRadius / 2),
        spreadRadius: spreadRadius,
      ),
    ];
  }

  Color _getShadowColorFromBorder(Color borderColor) {
    // Usar la misma lógica que CustomTextField
    if (borderColor == AppColors.blue ||
        borderColor == const Color(0xFF1976D2)) {
      return const Color(0xFF0D47A1);
    } else if (borderColor == Colors.red ||
        borderColor == const Color(0xFFD32F2F)) {
      return const Color(0xFF8D1E1E);
    } else if (borderColor == Colors.green ||
        borderColor == const Color(0xFF4CAF50)) {
      return const Color(0xFF1B5E20);
    } else if (borderColor == Colors.purple ||
        borderColor == const Color(0xFF9C27B0)) {
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

  Widget _buildIconWrapper(Widget icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: IconTheme(
        data: IconThemeData(
          color: widget.iconColor ??
              widget.borderColor ??
              (_isFocused ? const Color(0xFF666666) : Colors.grey[600]),
          size: 20,
        ),
        child: icon,
      ),
    );
  }

  Widget _buildPrefixIcon() {
    return _buildIconWrapper(Icon(widget.searchIcon));
  }

  Widget? _buildSuffixIcon() {
    List<Widget> suffixWidgets = [];

    // Agregar botón de limpiar si hay texto
    if (widget.showClearButton && _hasText) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            widget.clearIcon,
            size: 18,
            color: Colors.grey[600],
          ),
          onPressed: _handleClear,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          splashRadius: 16,
        ),
      );
    }

    // Agregar botones de acción personalizados
    if (widget.actionButtons != null && widget.actionButtons!.isNotEmpty) {
      suffixWidgets.addAll(widget.actionButtons!);
    }

    if (suffixWidgets.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: suffixWidgets,
    );
  }

  Widget _buildSearchField() {
    final borderRadius = _getCachedBorderRadius();

    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.filled ? widget.backgroundColor : Colors.transparent,
          borderRadius: borderRadius,
          boxShadow: widget.filled ? _getCachedShadows() : null,
          border: Border.all(
            color: _getCachedBorderColor(),
            width: widget.borderWidth ?? 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.text,
            enabled: widget.enabled,
            maxLines: 1,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (value) {
              // El debounce se maneja en _onTextChanged
              // No llamar directamente a onChanged aquí para evitar sobrecarga
            },
            onSubmitted: _handleSubmitted,
            style: _getCachedTextStyle(),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              prefixIcon: _buildPrefixIcon(),
              suffixIcon: _buildSuffixIcon(),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: _getCachedContentPadding(),
              hintStyle: _getCachedHintStyle(),
              counterText: '',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget searchField = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => _buildSearchField(),
      ),
    );

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            Text(widget.label!, style: _getCachedLabelStyle()),
            const SizedBox(height: 4),
          ],
          searchField,
        ],
      ),
    );
  }
}

/// Helper class para crear CustomSearchField con configuraciones comunes
class CustomSearchFieldHelpers {
  /// Crea un campo de búsqueda con configuraciones personalizadas
  ///
  /// Ejemplos de uso:
  /// ```dart
  /// // Básico
  /// CustomSearchFieldHelpers.create(controller: myController)
  ///
  /// // Con filtros
  /// CustomSearchFieldHelpers.create(
  ///   controller: myController,
  ///   actionButtons: [FilterButton()],
  /// )
  ///
  /// // Sin botón de limpiar
  /// CustomSearchFieldHelpers.create(
  ///   controller: myController,
  ///   showClearButton: false,
  /// )
  ///
  /// // Con debounce personalizado
  /// CustomSearchFieldHelpers.create(
  ///   controller: myController,
  ///   debounceDelay: Duration(milliseconds: 500),
  /// )
  /// ```
  static CustomSearchField create({
    required TextEditingController controller,
    String? hintText,
    String? label,
    Color? borderColor,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    Function()? onClear,
    List<Widget>? actionButtons,
    bool showClearButton = true,
    Duration? debounceDelay,
    bool enabled = true,
    double? height,
    Color? backgroundColor,
    double? borderRadius,
    FocusNode? focusNode,
  }) {
    return CustomSearchField(
      controller: controller,
      hintText: hintText ?? 'Buscar...',
      label: label,
      borderColor: borderColor,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
      actionButtons: actionButtons,
      showClearButton: showClearButton,
      debounceDelay: debounceDelay ?? const Duration(milliseconds: 500),
      enabled: enabled,
      height: height,
      backgroundColor: backgroundColor ?? const Color.fromARGB(255, 255, 255, 255),
      borderRadius: borderRadius ?? 6.0,
      focusNode: focusNode,
    );
  }
}