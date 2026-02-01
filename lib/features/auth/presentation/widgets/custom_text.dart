import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/fonts/app_fonts.dart';

// -------------------- Enums --------------------
enum FieldType { text, email, number, password }

enum TextCase { normal, upper, lower }

/// UX PRO: controla cuándo validar y cuándo mostrar errores
enum AutovalidateModeX {
  disabled, // nunca (solo manual)
  onUserInteraction, // después de dirty/touched
  onUnfocus, // al perder foco (recomendado)
  afterSubmit, // solo tras intento de submit
  always, // siempre (ruidoso)
}

typedef HelperTextBuilder = String? Function(String value, bool isFocused);

// -------------------- Validation State (sealed) --------------------
sealed class ValidationState {
  const ValidationState();
}

class ValidationNone extends ValidationState {
  const ValidationNone();
}

class ValidationLoading extends ValidationState {
  const ValidationLoading();
}

class ValidationValid extends ValidationState {
  const ValidationValid();
}

class ValidationInvalid extends ValidationState {
  final String error;
  const ValidationInvalid(this.error);
}

// -------------------- Constants --------------------
class CustomTextFieldConstants {
  static const Duration defaultValidationDelay = Duration(milliseconds: 650);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 180);

  static const double defaultHeight = 33.0;
  static const double defaultBorderRadius = 6.0;
  static const double defaultBorderWidth = 0.5;

  static const Color defaultBackgroundColor = Color(0xFFFFFFFF);
  static const Color defaultFocusedBorderColor = Color(0xFFE0E0E0);
  static const Color defaultBorderColor = Color(0xFFF0F0F0);

  static const Widget loadingIndicator = SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(strokeWidth: 1),
  );

  static const Widget validIcon = Icon(
    Icons.check_circle,
    color: Colors.green,
    size: 16,
  );

  static const Widget invalidIcon = Icon(
    Icons.error,
    color: Colors.red,
    size: 16,
  );
}

// -------------------- Validators --------------------
class FieldValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Escribe un correo válido (ej: nombre@dominio.com)';
    }

    if (value.length > 254) return 'Email demasiado largo';
    if (value.contains('..')) return 'Email inválido';

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    if (value.length < 6) return 'Usa al menos 6 caracteres';
    return null;
  }

  static String? validateNumber(
    String? value, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.isEmpty) return null;

    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (minLength != null && digitsOnly.length < minLength) {
      return 'Debe tener al menos $minLength dígitos';
    }
    if (maxLength != null && digitsOnly.length > maxLength) {
      return 'No puede exceder $maxLength dígitos';
    }

    return null;
  }
}

// -------------------- Number formatter --------------------
class NumberFormatter extends TextInputFormatter {
  final int? maxLength;
  NumberFormatter({this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    var digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (maxLength != null && digitsOnly.length > maxLength!) {
      digitsOnly = digitsOnly.substring(0, maxLength);
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}

// -------------------- Validation Manager (async-safe) --------------------
class ValidationManager {
  Timer? _timer;
  int _seq = 0;
  bool _disposed = false;

  final ValueNotifier<ValidationState> state = ValueNotifier(
    const ValidationNone(),
  );
  final ValueNotifier<String?> error = ValueNotifier(null);

  void clear() {
    if (_disposed) return;
    _timer?.cancel();
    _seq++;
    state.value = const ValidationNone();
    error.value = null;
  }

  Future<String?> validateNow({
    required String value,
    required FieldType type,
    required bool required,
    String? Function(String?)? validator,
    Future<String?> Function(String)? asyncValidator,
  }) async {
    if (_disposed) return 'Widget disposed';
    final currentSeq = ++_seq;

    state.value = const ValidationLoading();

    final result = await _validate(
      value,
      type,
      required,
      validator,
      asyncValidator,
    );
    if (_disposed || currentSeq != _seq) return result;

    if (result != null) {
      state.value = ValidationInvalid(result);
      error.value = result;
    } else {
      state.value = const ValidationValid();
      error.value = null;
    }

    return result;
  }

  Future<String?> validateDebounced({
    required String value,
    required FieldType type,
    required bool required,
    required Duration delay,
    String? Function(String?)? validator,
    Future<String?> Function(String)? asyncValidator,
  }) {
    if (_disposed) return Future.value('Widget disposed');

    _timer?.cancel();
    final currentSeq = ++_seq;

    state.value = const ValidationLoading();

    final completer = Completer<String?>();
    _timer = Timer(delay, () async {
      if (_disposed || currentSeq != _seq) {
        completer.complete('Widget disposed');
        return;
      }

      final result = await _validate(
        value,
        type,
        required,
        validator,
        asyncValidator,
      );
      if (_disposed || currentSeq != _seq) {
        completer.complete(result);
        return;
      }

      if (result != null) {
        state.value = ValidationInvalid(result);
        error.value = result;
      } else {
        state.value = const ValidationValid();
        error.value = null;
      }

      completer.complete(result);
    });

    return completer.future;
  }

  Future<String?> _validate(
    String value,
    FieldType type,
    bool required,
    String? Function(String?)? validator,
    Future<String?> Function(String)? asyncValidator,
  ) async {
    if (required && value.isEmpty) return 'Este campo es obligatorio';

    String? err;

    switch (type) {
      case FieldType.email:
        if (value.isEmpty && !required) break;
        err = FieldValidators.validateEmail(value);
        break;
      case FieldType.password:
        if (value.isEmpty && !required) break;
        err = FieldValidators.validatePassword(value);
        break;
      case FieldType.number:
        err = FieldValidators.validateNumber(value);
        break;
      case FieldType.text:
        break;
    }

    if (err == null && validator != null) {
      err = validator(value);
    }

    if (err == null && asyncValidator != null && value.isNotEmpty) {
      try {
        err = await asyncValidator(value);
      } catch (_) {
        err = 'No pudimos validar. Intenta de nuevo.';
      }
    }

    return err;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    state.dispose();
    error.dispose();
  }
}

// -------------------- MAIN WIDGET (UX PRO + helper) --------------------
class CustomText extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;

  final String? Function(String?)? validator;
  final Future<String?> Function(String)? asyncValidator;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  final List<TextInputFormatter>? inputFormatters;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;

  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double? borderWidth;
  final Color? colorIcon;
  final EdgeInsetsGeometry? contentPadding;

  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;

  final bool filled;
  final FocusNode? focusNode;
  final double? height;

  final TextCase textCase;
  final FieldType fieldType;

  // UX PRO
  final bool required;
  final AutovalidateModeX autovalidateMode;
  final bool validateOnChangeAfterError;
  final int minCharsBeforeValidate;
  final Duration validationDelay;

  final bool showValidationIndicator;
  final bool showSuccessIndicator;

  final String? externalError;
  final ValueListenable<bool>? submitSignal;

  // Helper text (premium)
  final String? helperText;
  final HelperTextBuilder? helperBuilder;
  final bool showHelperOnlyOnFocus;
  final TextStyle? helperStyle;

  const CustomText({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.asyncValidator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    bool? obscureText,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.backgroundColor = CustomTextFieldConstants.defaultBackgroundColor,
    this.borderColor,
    this.borderRadius = CustomTextFieldConstants.defaultBorderRadius,
    this.borderWidth = CustomTextFieldConstants.defaultBorderWidth,
    this.colorIcon,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.filled = true,
    this.focusNode,
    this.height = CustomTextFieldConstants.defaultHeight,
    this.fieldType = FieldType.text,
    this.textCase = TextCase.normal,

    // UX defaults pro
    this.required = false,
    this.autovalidateMode = AutovalidateModeX.onUnfocus,
    this.validateOnChangeAfterError = true,
    this.minCharsBeforeValidate = 1,
    this.validationDelay = CustomTextFieldConstants.defaultValidationDelay,
    this.showValidationIndicator = true,
    this.showSuccessIndicator = false,
    this.externalError,
    this.submitSignal,

    // helper defaults
    this.helperText,
    this.helperBuilder,
    this.showHelperOnlyOnFocus = true,
    this.helperStyle,
  }) : obscureText = fieldType == FieldType.password
           ? true
           : (obscureText ?? false);

  @override
  State<CustomText> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomText>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _hasText = false;

  // UX states
  bool _dirty = false;
  bool _touched = false;
  bool _submitted = false;

  late bool _isObscured;

  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  late Animation<double> _scaleAnimation;

  late ValidationManager _validationManager;

  // caches “seguros”
  List<TextInputFormatter>? _formattersCache;
  String? _formattersKey;
  TextInputType? _keyboardCache;
  BorderRadius? _radiusCache;
  EdgeInsetsGeometry? _paddingCache;
  TextStyle? _textStyleCache;
  TextStyle? _hintStyleCache;
  TextStyle? _labelStyleCache;

  List<BoxShadow>? _shadowsCache;
  bool _lastFocusForShadow = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _validationManager = ValidationManager();

    _animationController = AnimationController(
      duration: CustomTextFieldConstants.defaultAnimationDuration,
      vsync: this,
    );

    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    if (widget.controller != null) {
      _hasText = widget.controller!.text.isNotEmpty;
      widget.controller!.addListener(_onTextChanged);
    }

    widget.submitSignal?.addListener(_onSubmitSignal);
  }

  @override
  void didUpdateWidget(CustomText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
      _hasText = widget.controller?.text.isNotEmpty ?? false;
    }

    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
      _isFocused = _focusNode.hasFocus;
    }

    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }

    if (oldWidget.submitSignal != widget.submitSignal) {
      oldWidget.submitSignal?.removeListener(_onSubmitSignal);
      widget.submitSignal?.addListener(_onSubmitSignal);
    }

    if (oldWidget.fieldType != widget.fieldType ||
        oldWidget.textCase != widget.textCase ||
        oldWidget.inputFormatters != widget.inputFormatters ||
        oldWidget.maxLength != widget.maxLength ||
        oldWidget.keyboardType != widget.keyboardType) {
      _formattersCache = null;
      _formattersKey = null;
      _keyboardCache = null;
    }

    if (oldWidget.borderRadius != widget.borderRadius) _radiusCache = null;

    if (oldWidget.contentPadding != widget.contentPadding ||
        oldWidget.height != widget.height ||
        oldWidget.maxLines != widget.maxLines ||
        oldWidget.minLines != widget.minLines ||
        oldWidget.prefixIcon != widget.prefixIcon ||
        oldWidget.prefixText != widget.prefixText) {
      _paddingCache = null;
    }

    if (oldWidget.textStyle != widget.textStyle ||
        oldWidget.enabled != widget.enabled) {
      _textStyleCache = null;
    }
    if (oldWidget.hintStyle != widget.hintStyle) _hintStyleCache = null;
    if (oldWidget.labelStyle != widget.labelStyle) _labelStyleCache = null;

    if (oldWidget.borderColor != widget.borderColor) _shadowsCache = null;

    if (oldWidget.externalError != widget.externalError) {
      if (widget.externalError != null) {
        _validationManager.state.value = ValidationInvalid(
          widget.externalError!,
        );
        _validationManager.error.value = widget.externalError;
      } else {
        if (_shouldShowErrorOrIndicator &&
            (widget.controller?.text.isNotEmpty ?? false)) {
          _validateImmediate();
        } else {
          _validationManager.clear();
        }
      }
    }

    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    widget.submitSignal?.removeListener(_onSubmitSignal);

    _validationManager.dispose();
    _animationController.dispose();

    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();

    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  // ---------- UX logic ----------
  bool get _shouldShowError {
    if (widget.externalError != null) return true;

    switch (widget.autovalidateMode) {
      case AutovalidateModeX.disabled:
        return false;
      case AutovalidateModeX.always:
        return true;
      case AutovalidateModeX.onUserInteraction:
        return _dirty || _touched;
      case AutovalidateModeX.onUnfocus:
        return _touched;
      case AutovalidateModeX.afterSubmit:
        return _submitted;
    }
  }

  bool get _shouldShowErrorOrIndicator {
    if (widget.autovalidateMode == AutovalidateModeX.always) return true;
    if (widget.autovalidateMode == AutovalidateModeX.disabled) return false;
    return _dirty || _touched || _submitted;
  }

  bool get _hasVisibleError {
    if (!_shouldShowError) return false;
    return widget.externalError != null ||
        _validationManager.state.value is ValidationInvalid;
  }

  bool _passesMinCharsGate(String text) {
    if (text.isEmpty) return widget.required;
    final min = widget.fieldType == FieldType.email
        ? widget.minCharsBeforeValidate.clamp(1, 999)
        : 1;
    return text.length >= min;
  }

  String? _computeHelper() {
    final value = widget.controller?.text ?? '';
    if (_hasVisibleError) return null; // prioridad al error
    if (widget.showHelperOnlyOnFocus && !_isFocused) return null;

    final built = widget.helperBuilder?.call(value, _isFocused);
    if (built != null && built.trim().isNotEmpty) return built;

    if (widget.helperText != null && widget.helperText!.trim().isNotEmpty) {
      return widget.helperText;
    }
    return null;
  }

  void _onSubmitSignal() {
    final v = widget.submitSignal?.value ?? false;
    if (!v) return;

    _submitted = true;
    _validateImmediate();
    setState(() {});
  }

  void _onFocusChange() {
    if (!mounted) return;

    final focused = _focusNode.hasFocus;
    setState(() => _isFocused = focused);

    if (focused) {
      _animationController.forward();
      return;
    }

    _animationController.reverse();
    if (!_touched) _touched = true;

    if (widget.externalError != null) return;

    final shouldValidateOnBlur =
        widget.autovalidateMode == AutovalidateModeX.onUnfocus ||
        (widget.autovalidateMode == AutovalidateModeX.onUserInteraction &&
            (_dirty || _touched)) ||
        (widget.autovalidateMode == AutovalidateModeX.afterSubmit &&
            _submitted) ||
        widget.autovalidateMode == AutovalidateModeX.always;

    if (shouldValidateOnBlur) _validateImmediate();
  }

  void _onTextChanged() {
    if (!mounted) return;

    final text = widget.controller?.text ?? '';
    final hasText = text.isNotEmpty;

    if (!_dirty && hasText) _dirty = true;

    if (hasText != _hasText) setState(() => _hasText = hasText);

    widget.onChanged?.call(text);

    if (!widget.enabled) return;
    if (widget.externalError != null) return;

    final canAutoValidate =
        widget.autovalidateMode == AutovalidateModeX.always ||
        (widget.autovalidateMode == AutovalidateModeX.onUserInteraction &&
            (_dirty || _touched)) ||
        (widget.autovalidateMode == AutovalidateModeX.afterSubmit &&
            _submitted);

    final shouldValidateWhileTyping =
        canAutoValidate ||
        (widget.validateOnChangeAfterError && _hasVisibleError);

    if (!shouldValidateWhileTyping) {
      if (!hasText && !widget.required) _validationManager.clear();
      return;
    }

    if (!_passesMinCharsGate(text)) return;
    _validateDebounced();
  }

  void _validateDebounced() {
    final text = widget.controller?.text ?? '';
    _validationManager.validateDebounced(
      value: text,
      type: widget.fieldType,
      required: widget.required,
      delay: widget.validationDelay,
      validator: widget.validator,
      asyncValidator: widget.asyncValidator,
    );
  }

  void _validateImmediate() {
    final text = widget.controller?.text ?? '';

    if (text.isEmpty &&
        !widget.required &&
        widget.autovalidateMode != AutovalidateModeX.always) {
      _validationManager.clear();
      return;
    }

    if (!_passesMinCharsGate(text)) return;

    _validationManager.validateNow(
      value: text,
      type: widget.fieldType,
      required: widget.required,
      validator: widget.validator,
      asyncValidator: widget.asyncValidator,
    );
  }

  Future<bool> validateManually() async {
    if (!mounted) return false;
    _submitted = true;

    final text = widget.controller?.text ?? '';
    final err = await _validationManager.validateNow(
      value: text,
      type: widget.fieldType,
      required: widget.required,
      validator: widget.validator,
      asyncValidator: widget.asyncValidator,
    );

    if (mounted) setState(() {});
    return err == null;
  }

  // ---------- cached UI helpers ----------
  TextInputType _getKeyboardType() {
    switch (widget.fieldType) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.number:
        return TextInputType.number;
      default:
        return widget.keyboardType;
    }
  }

  TextInputType _keyboard() => _keyboardCache ??= _getKeyboardType();

  List<TextInputFormatter> _formatters() {
    final key =
        '${widget.fieldType}|${widget.textCase}|${widget.maxLength}|${widget.inputFormatters.hashCode}';
    if (_formattersCache != null && _formattersKey == key) {
      return _formattersCache!;
    }
    _formattersKey = key;

    final list = <TextInputFormatter>[...(widget.inputFormatters ?? const [])];

    if (widget.textCase == TextCase.upper) {
      list.insert(
        0,
        TextInputFormatter.withFunction(
          (oldV, newV) => newV.copyWith(text: newV.text.toUpperCase()),
        ),
      );
    } else if (widget.textCase == TextCase.lower) {
      list.insert(
        0,
        TextInputFormatter.withFunction(
          (oldV, newV) => newV.copyWith(text: newV.text.toLowerCase()),
        ),
      );
    }

    switch (widget.fieldType) {
      case FieldType.number:
        list.insert(0, NumberFormatter(maxLength: widget.maxLength));
        break;
      case FieldType.email:
        list.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
        break;
      default:
        break;
    }

    _formattersCache = list;
    return list;
  }

  BorderRadius _radius() =>
      _radiusCache ??= BorderRadius.circular(widget.borderRadius);

  TextStyle _textStyle() => _textStyleCache ??=
      (widget.textStyle ??
      TextStyle(
        color: widget.enabled ? AppColors.blue2 : Colors.grey,
        fontSize: 10,
        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
      ));

  TextStyle _hintStyle() => _hintStyleCache ??=
      (widget.hintStyle ??
      TextStyle(
        color: Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
      ));

  TextStyle _labelStyle() => _labelStyleCache ??=
      (widget.labelStyle ??
      TextStyle(
        fontFamily: 'Oxygen-Regular',
        fontSize: 9,
        color: widget.borderColor ?? Colors.black54,
      ));

  TextStyle _helperStyle() =>
      widget.helperStyle ??
      TextStyle(
        // color: Colors.grey[600],
        color: AppColors.greendark,
        fontSize: 9,
        fontWeight: FontWeight.w400,
      );

  Color _borderColor() {
    return widget.borderColor ??
        (_isFocused
            ? CustomTextFieldConstants.defaultFocusedBorderColor
            : CustomTextFieldConstants.defaultBorderColor);
  }

  EdgeInsetsGeometry _defaultPadding() {
    final hasPrefix = _buildPrefixIcon() != null || widget.prefixText != null;
    final isMultiline = widget.maxLines == null || widget.maxLines! > 1;

    if (widget.height != null && !isMultiline) {
      var vertical = (widget.height! - 20) / 2;
      vertical = vertical.clamp(8.0, 20.0);
      return EdgeInsets.symmetric(
        horizontal: hasPrefix ? 12 : 16,
        vertical: vertical,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: hasPrefix ? 12 : 16,
      vertical: isMultiline ? 8 : 14,
    );
  }

  EdgeInsetsGeometry _padding() =>
      _paddingCache ??= (widget.contentPadding ?? _defaultPadding());

  List<BoxShadow> _shadows() {
    if (_shadowsCache == null || _lastFocusForShadow != _isFocused) {
      _lastFocusForShadow = _isFocused;
      _shadowsCache = _buildShadows();
    }
    return _shadowsCache!;
  }

  List<BoxShadow> _buildShadows() {
    final intensity = _shadowAnimation.value;
    final border = _borderColor();
    final shadowColor = _getShadowColorFromBorder(border);

    if (_isFocused) {
      return [
        BoxShadow(
          color: border.withValues(alpha: 0.25 + (intensity * 0.2)),
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          offset: const Offset(-1, -1),
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ];
    }

    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.18),
        offset: const Offset(4, 4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: border.withValues(alpha: 0.15),
        offset: const Offset(1, 1),
        blurRadius: 4,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.8),
        offset: const Offset(-2, -2),
        blurRadius: 4,
        spreadRadius: -1,
      ),
    ];
  }

  Color _getShadowColorFromBorder(Color borderColor) {
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
      final hsl = HSLColor.fromColor(borderColor);
      return HSLColor.fromAHSL(
        1.0,
        hsl.hue,
        (hsl.saturation * 0.9).clamp(0.0, 1.0),
        (hsl.lightness * 0.25).clamp(0.0, 0.4),
      ).toColor();
    }
  }

  Widget _wrapIcon(Widget icon) {
    final color =
        widget.colorIcon ??
        widget.borderColor ??
        (_isFocused ? const Color(0xFF666666) : Colors.grey[600]);

    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: IconTheme(
        data: IconThemeData(color: color, size: 16),
        child: icon,
      ),
    );
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon != null) return _wrapIcon(widget.prefixIcon!);

    IconData? icon;
    switch (widget.fieldType) {
      case FieldType.email:
        icon = Icons.email_outlined;
        break;
      case FieldType.password:
        icon = Icons.lock_outlined;
        break;
      default:
        icon = null;
    }
    if (icon == null) return null;
    return _wrapIcon(Icon(icon, size: 16));
  }

  Widget _passwordToggle() {
    return IconButton(
      icon: Icon(
        _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: widget.enabled
          ? () => setState(() => _isObscured = !_isObscured)
          : null,
      color: _isFocused ? const Color(0xFF666666) : Colors.grey[600],
      iconSize: 20,
      splashRadius: 20,
      tooltip: _isObscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
    );
  }

  Widget _validationIndicator(ValidationState state) {
    if (!widget.showValidationIndicator || !_shouldShowErrorOrIndicator) {
      return const SizedBox.shrink();
    }
    if (!_hasText && !widget.required) return const SizedBox.shrink();

    if (state is ValidationLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: CustomTextFieldConstants.loadingIndicator,
      );
    }

    if (state is ValidationInvalid) {
      if (!_shouldShowError) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: CustomTextFieldConstants.invalidIcon,
      );
    }

    if (state is ValidationValid) {
      if (!widget.showSuccessIndicator) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: CustomTextFieldConstants.validIcon,
      );
    }

    return const SizedBox.shrink();
  }

  Widget? _suffixIcon() {
    final indicator = ValueListenableBuilder<ValidationState>(
      valueListenable: _validationManager.state,
      builder: (_, state, __) => _validationIndicator(state),
    );

    final wantsIndicator =
        widget.showValidationIndicator && _shouldShowErrorOrIndicator;

    if (widget.obscureText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wantsIndicator) indicator,
          const SizedBox(width: 4),
          _passwordToggle(),
        ],
      );
    }

    if (wantsIndicator) return indicator;
    if (widget.suffixIcon != null) return _wrapIcon(widget.suffixIcon!);
    return null;
  }

  Widget _counter() {
    if (widget.maxLength == null || widget.controller == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller!,
      builder: (_, value, __) {
        return Positioned(
          right: 8,
          bottom: 1,
          child: Text(
            '${value.text.length}/${widget.maxLength}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _errorMessage() {
    return ValueListenableBuilder<ValidationState>(
      valueListenable: _validationManager.state,
      builder: (context, state, child) {
        final external = widget.externalError;
        final internal = state is ValidationInvalid ? state.error : null;

        final show = _shouldShowError && (external != null || internal != null);
        final msg = external ?? internal ?? '';

        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: show ? 1 : 0,
            child: show
                ? Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      msg,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _helperMessage() {
    final helper = _computeHelper();
    final show = helper != null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: show ? 1 : 0,
        child: show
            ? Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(helper, style: _helperStyle()), // <- sin !
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTextField() {
    final semanticsLabel = widget.label ?? widget.hintText ?? 'Campo de texto';
    final isMultiline = widget.maxLines == null || widget.maxLines! > 1;

    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Container(
        height: isMultiline ? null : widget.height,
        decoration: BoxDecoration(
          color: widget.filled ? widget.backgroundColor : Colors.transparent,
          borderRadius: _radius(),
          boxShadow: widget.filled ? _shadows() : null,
          border: Border.all(
            color: _borderColor(),
            width: widget.borderWidth ?? 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: _radius(),
          child: Semantics(
            label: semanticsLabel,
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: _keyboard(),
              obscureText: _isObscured,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              inputFormatters: _formatters(),
              textAlignVertical: TextAlignVertical.center,
              onFieldSubmitted: widget.onSubmitted,
              validator: (widget.autovalidateMode == AutovalidateModeX.disabled)
                  ? widget.validator
                  : null,
              style: _textStyle(),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: widget.hintText,
                prefixIcon: _buildPrefixIcon(),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 35,
                ),
                suffixIcon: _suffixIcon(),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 35,
                ),
                prefixText: widget.prefixText,
                suffixText: widget.suffixText,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: _padding(),
                // contentPadding: EdgeInsets.fromLTRB(8, 8, 4, 8),
                hintStyle: _hintStyle(),
                counterText: '',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCounter = widget.maxLength != null && widget.controller != null;

    final field = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (_, __) => _buildTextField(),
      ),
    );

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) Text(widget.label!, style: _labelStyle()),
          if (showCounter) Stack(children: [field, _counter()]) else field,
          _helperMessage(),
          _errorMessage(),
        ],
      ),
    );
  }
}

// -------------------- Extensions --------------------
extension CustomTextFieldControllerExtension on TextEditingController {
  int? get numberValue => int.tryParse(text);
  bool get isValidNumber => RegExp(r'^\d+$').hasMatch(text);
}

// -------------------- Helpers (preconfigurados) --------------------
class CustomTextFieldHelpers {
  static CustomText text({
    required String label,
    required TextEditingController controller,
    ValueListenable<bool>? submitSignal,
    String? hintText,
    bool required = false,
    AutovalidateModeX autovalidateMode = AutovalidateModeX.onUnfocus,
    String? externalError,
    String? helperText,
    HelperTextBuilder? helperBuilder,
  }) {
    return CustomText(
      label: label,
      hintText: hintText,
      controller: controller,
      fieldType: FieldType.text,
      required: required,
      autovalidateMode: autovalidateMode,
      submitSignal: submitSignal,
      externalError: externalError,
      helperText: helperText,
      helperBuilder: helperBuilder,
    );
  }

  static CustomText number({
    required String label,
    required TextEditingController controller,
    ValueListenable<bool>? submitSignal,
    String? hintText,
    int? minLength,
    int? maxLength,
    bool required = false,
    AutovalidateModeX autovalidateMode = AutovalidateModeX.onUnfocus,
    String? externalError,
    String? helperText,
  }) {
    return CustomText(
      label: label,
      hintText: hintText ?? 'Ingresa un número',
      controller: controller,
      fieldType: FieldType.number,
      maxLength: maxLength,
      required: required,
      autovalidateMode: autovalidateMode,
      submitSignal: submitSignal,
      externalError: externalError,
      validator: (v) => FieldValidators.validateNumber(
        v,
        minLength: minLength,
        maxLength: maxLength,
      ),
      helperText: helperText ?? 'Solo se permiten dígitos.',
    );
  }

  static CustomText email({
    required String label,
    required TextEditingController controller,
    ValueListenable<bool>? submitSignal,
    String? hintText,
    bool required = true,
    AutovalidateModeX autovalidateMode = AutovalidateModeX.onUnfocus,
    String? externalError,
    Color? borderColor,
  }) {
    return CustomText(
      label: label,
      borderColor: borderColor,
      hintText: hintText ?? 'correo@ejemplo.com',
      controller: controller,
      fieldType: FieldType.email,
      required: required,
      autovalidateMode: autovalidateMode,
      minCharsBeforeValidate: 3,
      submitSignal: submitSignal,
      externalError: externalError,
      validator: FieldValidators.validateEmail,
      helperBuilder: (value, focused) {
        if (!focused) return null;
        if (value.isEmpty) return 'Escribe tu correo. Ej: nombre@dominio.com';
        if (!value.contains('@')) return 'Incluye el símbolo @';
        if (value.endsWith('@')) {
          return 'Ahora escribe el dominio (ej: gmail.com)';
        }
        return null;
      },
    );
  }

  static CustomText password({
    required String label,
    required TextEditingController controller,
    ValueListenable<bool>? submitSignal,
    String? hintText,
    bool required = true,
    AutovalidateModeX autovalidateMode = AutovalidateModeX.afterSubmit,
    String? externalError,
  }) {
    return CustomText(
      label: label,
      hintText: hintText ?? 'Ingresa tu contraseña',
      controller: controller,
      fieldType: FieldType.password,
      required: required,
      autovalidateMode: autovalidateMode,
      submitSignal: submitSignal,
      externalError: externalError,
      validator: FieldValidators.validatePassword,
      helperBuilder: (value, focused) {
        if (!focused) return null;
        if (value.isEmpty) return 'Usa al menos 6 caracteres.';
        if (value.length < 6) {
          return 'Te faltan ${6 - value.length} caracteres.';
        }
        return 'Bien. Puedes continuar.';
      },
      showSuccessIndicator: false,
    );
  }
}
