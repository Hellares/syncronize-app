// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:syncronize/core/fonts/app_fonts.dart';
// import 'package:syncronize/core/theme/app_colors.dart';

// import 'currency_formatter.dart';

// sealed class ValidationState {
//   const ValidationState();
// }

// class ValidationNone extends ValidationState {
//   const ValidationNone();
// }

// class ValidationLoading extends ValidationState {
//   const ValidationLoading();
// }

// class ValidationValid extends ValidationState {
//   const ValidationValid();
// }

// class ValidationInvalid extends ValidationState {
//   final String error;
//   const ValidationInvalid(this.error);
// }

// // 🚀 MANAGER DE VALIDACIÓN
// class CurrencyValidationManager {
//   Timer? _timer;
//   final ValueNotifier<ValidationState> state =
//       ValueNotifier<ValidationState>(const ValidationNone());
//   bool _disposed = false;

//   void startValidation(
//     String value,
//     Duration delay,
//     String? Function(String?)? validator,
//   ) {
//     if (_disposed) return;
//     _timer?.cancel();

//     if (validator == null) {
//       state.value = const ValidationNone();
//       return;
//     }

//     state.value = const ValidationLoading();

//     _timer = Timer(delay, () {
//       if (_disposed) return;
//       final err = validator(value);
//       if (err == null) {
//         state.value = const ValidationValid();
//       } else {
//         state.value = ValidationInvalid(err);
//       }
//     });
//   }

//   void clearValidation() {
//     if (_disposed) return;
//     _timer?.cancel();
//     state.value = const ValidationNone();
//   }

//   void dispose() {
//     _disposed = true;
//     _timer?.cancel();
//     state.dispose();
//   }
// }

// class CurrencyTextField extends StatefulWidget {
//   final String? label;
//   final String? hintText;

//   final TextEditingController? controller;
//   final FocusNode? focusNode;

//   /// Validador extra del usuario (se ejecuta después del defaultValidator)
//   final String? Function(String?)? validator;

//   final void Function(double)? onChanged;
//   final void Function(double)? onSubmitted;

//   final bool enabled;
//   final Color backgroundColor;
//   final Color? borderColor;
//   final double borderRadius;
//   final EdgeInsetsGeometry? contentPadding;

//   final TextStyle? textStyle;
//   final TextStyle? labelStyle;
//   final TextStyle? hintStyle;

//   final bool filled;
//   final double? height;
//   final double? borderWidth;

//   final String currencySymbol;
//   final int decimalPlaces;

//   /// ✅ NUEVO: comportamiento de validación
//   /// requiredField=false -> vacío no da error
//   final bool requiredField;

//   /// allowZero=true -> 0.00 NO da error
//   final bool allowZero;

//   /// Si el usuario borra (y queda vacío) se interpreta como 0 (no error si allowZero)
//   final bool treatEmptyAsZero;

//   /// límites opcionales
//   final double? minAmount;
//   final double? maxAmount;

//   /// UI symbol
//   final bool showSymbolIcon;

//   /// Validación realtime
//   final bool enableRealTimeValidation;
//   final Duration validationDelay;

//   final double? cursorHeight;
//   final double? cursorWidth;
//   final Color? cursorColor;

//   const CurrencyTextField({
//     super.key,
//     this.label,
//     this.hintText,
//     this.controller,
//     this.focusNode,
//     this.validator,
//     this.onChanged,
//     this.onSubmitted,
//     this.enabled = true,
//     this.backgroundColor = AppColors.white,
//     this.borderColor,
//     this.borderRadius = 6.0,
//     this.contentPadding,
//     this.textStyle,
//     this.labelStyle,
//     this.hintStyle,
//     this.filled = true,
//     this.height = 35,
//     this.borderWidth = 0.5,
//     this.currencySymbol = 'S/',
//     this.decimalPlaces = 2,
//     this.requiredField = false,
//     this.allowZero = true,
//     this.treatEmptyAsZero = true,
//     this.minAmount,
//     this.maxAmount,
//     this.showSymbolIcon = false,
//     this.enableRealTimeValidation = true,
//     this.validationDelay = const Duration(milliseconds: 800),
//     this.cursorHeight,
//     this.cursorWidth,
//     this.cursorColor,
//   });

//   @override
//   State<CurrencyTextField> createState() => _CurrencyTextFieldState();
// }

// class _CurrencyTextFieldState extends State<CurrencyTextField>
//     with SingleTickerProviderStateMixin {
//   bool _isFocused = false;

//   late FocusNode _focusNode;
//   late bool _ownsFocusNode;

//   late TextEditingController _controller;
//   late bool _ownsController;

//   late AnimationController _animationController;
//   late Animation<double> _shadowAnimation;
//   late Animation<double> _scaleAnimation;

//   late CurrencyValidationManager _validationManager;

//   BorderRadius? _cachedBorderRadius;
//   EdgeInsetsGeometry? _cachedContentPadding;
//   TextStyle? _cachedTextStyle;
//   TextStyle? _cachedHintStyle;
//   TextStyle? _cachedLabelStyle;
//   List<BoxShadow>? _shadowsCache;
//   bool _lastFocusState = false;

//   @override
//   void initState() {
//     super.initState();

//     _ownsFocusNode = widget.focusNode == null;
//     _focusNode = widget.focusNode ?? FocusNode();
//     _focusNode.addListener(_onFocusChange);

//     _ownsController = widget.controller == null;
//     _controller = widget.controller ?? TextEditingController();

//     _validationManager = CurrencyValidationManager();

//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.fastOutSlowIn,
//       ),
//     );

//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.fastOutSlowIn,
//       ),
//     );

//     _initializeController();
//   }

//   @override
//   void didUpdateWidget(covariant CurrencyTextField oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.focusNode != widget.focusNode) {
//       _focusNode.removeListener(_onFocusChange);
//       if (_ownsFocusNode) _focusNode.dispose();
//       _ownsFocusNode = widget.focusNode == null;
//       _focusNode = widget.focusNode ?? FocusNode();
//       _focusNode.addListener(_onFocusChange);
//     }

//     if (oldWidget.controller != widget.controller) {
//       if (_ownsController) _controller.dispose();
//       _ownsController = widget.controller == null;
//       _controller = widget.controller ?? TextEditingController();
//       _initializeController();
//     }
//   }

//   @override
//   void dispose() {
//     _focusNode.removeListener(_onFocusChange);
//     if (_ownsFocusNode) _focusNode.dispose();

//     if (_ownsController) _controller.dispose();

//     _validationManager.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _initializeController() {
//     // Si viene vacío al inicio, mantener 0.00 (como tu comportamiento actual)
//     if (_controller.text.isEmpty || _controller.text == '0' || _controller.text == '0.0') {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         _controller.text = '0.${'0' * widget.decimalPlaces}';
//         _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
//       });
//     }
//   }

//   void _onFocusChange() {
//     if (!mounted) return;
//     setState(() => _isFocused = _focusNode.hasFocus);

//     if (_isFocused) {
//       _animationController.forward();
//     } else {
//       _animationController.reverse();
//     }
//   }

//   /// ✅ NUEVO: validador default que respeta allowZero/requiredField/treatEmptyAsZero
//   String? _defaultValidator(String? value) {
//     final v = (value ?? '').trim();

//     if (v.isEmpty) {
//       if (widget.requiredField) return 'Campo requerido';
//       // si no es requerido, vacío es válido
//       return null;
//     }

//     final amount = CurrencyUtilsImproved.parseToDouble(v);

//     // Si queda 0.00 por borrado/formateo:
//     if (amount == 0) {
//       if (widget.allowZero) return null;
//       return 'El monto debe ser mayor a 0';
//     }

//     if (amount < 0) return 'Monto inválido';

//     // Si allowZero=true, NO aplicar minAmount cuando amount==0 (ya lo manejamos arriba)
//     if (widget.minAmount != null && amount < widget.minAmount!) {
//       return 'Monto mínimo: ${widget.currencySymbol} ${widget.minAmount!.toStringAsFixed(widget.decimalPlaces)}';
//     }

//     if (widget.maxAmount != null && amount > widget.maxAmount!) {
//       return 'Monto máximo: ${widget.currencySymbol} ${widget.maxAmount!.toStringAsFixed(widget.decimalPlaces)}';
//     }

//     return null;
//   }

//   String? Function(String?) _getCombinedValidator() {
//     return (value) {
//       final defaultError = _defaultValidator(value);
//       if (defaultError != null) return defaultError;

//       if (widget.validator != null) {
//         return widget.validator!(value);
//       }
//       return null;
//     };
//   }

//   BorderRadius _getCachedBorderRadius() =>
//       _cachedBorderRadius ??= BorderRadius.circular(widget.borderRadius);

//   EdgeInsetsGeometry _getCachedContentPadding() {
//     if (_cachedContentPadding != null) return _cachedContentPadding!;

//     if (widget.contentPadding != null) {
//       _cachedContentPadding = widget.contentPadding;
//       return _cachedContentPadding!;
//     }

//     // ✅ AJUSTE ESPECÍFICO POR ALTURA PARA CENTRADO PERFECTO
//     if (widget.height == 38) {
//       _cachedContentPadding = const EdgeInsets.fromLTRB(16, 12, 16, 11);
//     } else if (widget.height == 35) {
//       _cachedContentPadding = const EdgeInsets.fromLTRB(16, 10.5, 16, 10);
//     } else if (widget.height == 40) {
//       _cachedContentPadding = const EdgeInsets.fromLTRB(16, 13, 16, 12);
//     } else {
//       // Cálculo dinámico para otras alturas
//       double fontSize = _getCachedTextStyle().fontSize ?? 10;
//       double textHeight = fontSize * 1.5;
//       double verticalPadding = ((widget.height ?? 35) - textHeight) / 2;
//       _cachedContentPadding = EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: verticalPadding.clamp(8.0, 15.0),
//       );
//     }

//     return _cachedContentPadding!;
//   }

//   TextStyle _getCachedTextStyle() {
//     return _cachedTextStyle ??= widget.textStyle ??
//         TextStyle(
//           color: widget.enabled ? AppColors.blue2 : AppColors.blue3,
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//           fontFamily: 'Oxygen-Regular',
//           height: 1.0,
//         );
//   }

//   TextStyle _getCachedHintStyle() {
//     return _cachedHintStyle ??= widget.hintStyle ??
//         TextStyle(
//           color: Colors.grey[500],
//           fontSize: 10,
//           fontWeight: FontWeight.w400,
//           height: 1.0,
//         );
//   }

//   TextStyle _getCachedLabelStyle() {
//     return _cachedLabelStyle ??= widget.labelStyle ??
//         TextStyle(
//           fontSize: 9,
//           fontWeight: FontWeight.w500,
//           color: AppColors.blue1,
//           fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
//         );
//   }

//   Color _getCachedBorderColor() {
//     return widget.borderColor ??
//         (_isFocused ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0));
//   }

//   Widget? _buildSymbolIcon() {
//     if (!widget.showSymbolIcon) return null;
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8),
//       child: Text(
//         widget.currencySymbol,
//         style: _getCachedTextStyle().copyWith(
//           color: widget.borderColor ?? AppColors.blue3,
//           fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
//         ),
//       ),
//     );
//   }

//   Widget _buildValidationIcon() {
//     return ValueListenableBuilder<ValidationState>(
//       valueListenable: _validationManager.state,
//       builder: (context, state, child) {
//         return Padding(
//           padding: const EdgeInsets.only(right: 8),
//           child: SizedBox(
//             width: 16,
//             height: 16,
//             child: Center(
//               child: switch (state) {
//                 ValidationLoading() => const SizedBox(
//                     width: 14,
//                     height: 14,
//                     child: CircularProgressIndicator(strokeWidth: 1),
//                   ),
//                 ValidationValid() => const Icon(Icons.check_circle, color: Colors.green, size: 16),
//                 ValidationInvalid() => const Icon(Icons.error, color: Colors.red, size: 16),
//                 ValidationNone() => const SizedBox.shrink(),
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorText() {
//     return ValueListenableBuilder<ValidationState>(
//       valueListenable: _validationManager.state,
//       builder: (context, state, child) {
//         if (state is ValidationInvalid) {
//           return Padding(
//             padding: const EdgeInsets.only(top: 3),
//             child: Text(
//               state.error,
//               style: TextStyle(
//                 color: Colors.red[700],
//                 fontSize: 8,
//                 fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
//               ),
//             ),
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }

//   List<BoxShadow> _getCachedShadows() {
//     if (_shadowsCache == null || _lastFocusState != _isFocused) {
//       _shadowsCache = _buildShadows();
//       _lastFocusState = _isFocused;
//     }
//     return _shadowsCache!;
//   }

//   List<BoxShadow> _buildShadows() {
//     final double intensity = _shadowAnimation.value;
//     final Color currentBorderColor = _getCachedBorderColor();
//     Color shadowColor = _getShadowColor(currentBorderColor);

//     if (_isFocused) {
//       return [
//         BoxShadow(
//           color: currentBorderColor.withValues(alpha: 0.3 + (intensity * 0.2)),
//           offset: const Offset(0, 3),
//           blurRadius: 4 + (intensity * 2),
//           spreadRadius: 0,
//         ),
//         BoxShadow(
//           color: Colors.white.withValues(alpha: 0.6),
//           offset: const Offset(-1, -1),
//           blurRadius: 2,
//           spreadRadius: -1,
//         ),
//       ];
//     } else {
//       return [
//         BoxShadow(
//           color: shadowColor.withValues(alpha: 0.18),
//           offset: const Offset(4, 4),
//           blurRadius: 8,
//           spreadRadius: 0,
//         ),
//         BoxShadow(
//           color: currentBorderColor.withValues(alpha: 0.15),
//           offset: const Offset(1, 1),
//           blurRadius: 4,
//           spreadRadius: -1,
//         ),
//         BoxShadow(
//           color: Colors.white.withValues(alpha: 0.8),
//           offset: const Offset(-2, -2),
//           blurRadius: 4,
//           spreadRadius: -1,
//         ),
//       ];
//     }
//   }

//   Color _getShadowColor(Color borderColor) {
//     if (borderColor == AppColors.blue || borderColor == const Color(0xFF1976D2)) {
//       return const Color(0xFF0D47A1);
//     } else if (borderColor == Colors.green || borderColor == const Color(0xFF4CAF50)) {
//       return const Color(0xFF1B5E20);
//     } else {
//       HSLColor hsl = HSLColor.fromColor(borderColor);
//       return HSLColor.fromAHSL(
//         1.0,
//         hsl.hue,
//         (hsl.saturation * 0.9).clamp(0.0, 1.0),
//         (hsl.lightness * 0.25).clamp(0.0, 0.4),
//       ).toColor();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RepaintBoundary(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (widget.label != null) ...[
//             Text(widget.label!, style: _getCachedLabelStyle()),
//             const SizedBox(height: 2),
//           ],
//           AnimatedBuilder(
//             animation: _animationController,
//             builder: (context, child) {
//             return Transform.scale(
//               scale: _scaleAnimation.value,
//               child: Container(
//                 height: widget.height,
//                 decoration: BoxDecoration(
//                   color: widget.filled ? widget.backgroundColor : Colors.transparent,
//                   borderRadius: _getCachedBorderRadius(),
//                   boxShadow: widget.filled ? _getCachedShadows() : null,
//                   border: Border.all(
//                     color: _getCachedBorderColor(),
//                     width: widget.borderWidth ?? 0.5,
//                   ),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: _getCachedBorderRadius(),
//                   child: TextFormField(
//                     controller: _controller,
//                     focusNode: _focusNode,
//                     enabled: widget.enabled,
//                     maxLines: 1,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     inputFormatters: [
//                       CurrencyFormatterImproved(
//                         symbol: widget.currencySymbol,
//                         decimalPlaces: widget.decimalPlaces,
//                         locale: 'es',
//                       ),
//                     ],
//                     cursorHeight: widget.cursorHeight ?? 14,
//                     cursorWidth: widget.cursorWidth ?? 1.5,
//                     cursorColor: widget.cursorColor ?? AppColors.blue2,
//                     style: _getCachedTextStyle(),
//                     validator: _getCombinedValidator(),
//                     onChanged: (value) {
//                       // ✅ Si 0 es permitido, no marcar error cuando queda 0.00
//                       if (widget.enableRealTimeValidation) {
//                         _validationManager.startValidation(
//                           value,
//                           widget.validationDelay,
//                           _getCombinedValidator(),
//                         );
//                       }

//                       if (widget.onChanged != null) {
//                         final numValue = CurrencyUtilsImproved.parseToDouble(value);
//                         widget.onChanged!(numValue);
//                       }
//                     },
//                     onFieldSubmitted: (value) {
//                       if (widget.onSubmitted != null) {
//                         final numValue = CurrencyUtilsImproved.parseToDouble(value);
//                         widget.onSubmitted!(numValue);
//                       }
//                     },
//                     decoration: InputDecoration(
//                       isDense: true,
//                       hintText: widget.hintText ?? '0.00',
//                       hintStyle: _getCachedHintStyle(),
//                       contentPadding: _getCachedContentPadding(),
//                       border: InputBorder.none,
//                       enabledBorder: InputBorder.none,
//                       focusedBorder: InputBorder.none,
//                       errorBorder: InputBorder.none,
//                       focusedErrorBorder: InputBorder.none,
//                       disabledBorder: InputBorder.none,
//                       prefixIcon: widget.showSymbolIcon ? _buildSymbolIcon() : null,
//                       prefixIconConstraints: const BoxConstraints(
//                         minWidth: 40,
//                         minHeight: 35,
//                       ),
//                       prefixText: '${widget.currencySymbol} ',
//                       prefixStyle: _getCachedTextStyle().copyWith(
//                         color: AppColors.blueGrey,
//                         height: 1.0,
//                       ),
//                       suffixIcon: widget.enableRealTimeValidation ? _buildValidationIcon() : null,
//                       suffixIconConstraints: const BoxConstraints(
//                         minWidth: 30,
//                         minHeight: 35,
//                       ),
//                       counterText: '',
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//           ),
//           if (widget.enableRealTimeValidation) _buildErrorText(),
//         ],
//       ),
//     );
//   }
// }

// /// 💰 Helper opcional
// class CurrencyTextFieldHelper {
//   static CurrencyTextField create({
//     required String label,
//     required TextEditingController controller,
//     String? hintText,
//     String currencySymbol = 'S/',
//     int decimalPlaces = 2,
//     bool requiredField = false,
//     bool allowZero = true,
//     double? minAmount,
//     double? maxAmount,
//     String? Function(String?)? validator,
//     void Function(double)? onChanged,
//   }) {
//     return CurrencyTextField(
//       label: label,
//       controller: controller,
//       hintText: hintText,
//       currencySymbol: currencySymbol,
//       decimalPlaces: decimalPlaces,
//       requiredField: requiredField,
//       allowZero: allowZero,
//       minAmount: minAmount,
//       maxAmount: maxAmount,
//       validator: validator,
//       onChanged: onChanged,
//     );
//   }
// }


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import 'currency_formatter.dart';

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

// 🚀 MANAGER DE VALIDACIÓN
class CurrencyValidationManager {
  Timer? _timer;
  final ValueNotifier<ValidationState> state =
      ValueNotifier<ValidationState>(const ValidationNone());
  bool _disposed = false;

  void startValidation(
    String value,
    Duration delay,
    String? Function(String?)? validator,
  ) {
    if (_disposed) return;
    _timer?.cancel();

    if (validator == null) {
      state.value = const ValidationNone();
      return;
    }

    state.value = const ValidationLoading();

    _timer = Timer(delay, () {
      if (_disposed) return;
      final err = validator(value);
      if (err == null) {
        state.value = const ValidationValid();
      } else {
        state.value = ValidationInvalid(err);
      }
    });
  }

  void clearValidation() {
    if (_disposed) return;
    _timer?.cancel();
    state.value = const ValidationNone();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    state.dispose();
  }
}

class CurrencyTextField extends StatefulWidget {
  final String? label;
  final String? hintText;

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Validador extra del usuario (se ejecuta después del defaultValidator)
  final String? Function(String?)? validator;

  final void Function(double)? onChanged;
  final void Function(double)? onSubmitted;

  final bool enabled;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;

  final bool filled;
  final double? height;
  final double? borderWidth;

  final String currencySymbol;
  final int decimalPlaces;

  /// ✅ comportamiento de validación
  /// requiredField=false -> vacío no da error
  final bool requiredField;

  /// allowZero=true -> 0.00 NO da error
  final bool allowZero;

  /// Si true: cuando queda vacío, se interpreta como 0 (ej: al perder foco lo normaliza)
  /// Si false: permite vacío real sin forzarlo a 0 (útil si "no aplica")
  final bool treatEmptyAsZero;

  /// límites opcionales
  final double? minAmount;
  final double? maxAmount;

  /// UI symbol
  final bool showSymbolIcon;

  /// Validación realtime
  final bool enableRealTimeValidation;
  final Duration validationDelay;

  final double? cursorHeight;
  final double? cursorWidth;
  final Color? cursorColor;

  const CurrencyTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.backgroundColor = AppColors.white,
    this.borderColor,
    this.borderRadius = 6.0,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.filled = true,
    this.height = 35,
    this.borderWidth = 0.5,
    this.currencySymbol = 'S/',
    this.decimalPlaces = 2,
    this.requiredField = false,
    this.allowZero = true,
    this.treatEmptyAsZero = true,
    this.minAmount,
    this.maxAmount,
    this.showSymbolIcon = false,
    this.enableRealTimeValidation = true,
    this.validationDelay = const Duration(milliseconds: 800),
    this.cursorHeight,
    this.cursorWidth,
    this.cursorColor,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;

  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  late TextEditingController _controller;
  late bool _ownsController;

  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  late Animation<double> _scaleAnimation;

  late CurrencyValidationManager _validationManager;

  BorderRadius? _cachedBorderRadius;
  EdgeInsetsGeometry? _cachedContentPadding;
  TextStyle? _cachedTextStyle;
  TextStyle? _cachedHintStyle;
  TextStyle? _cachedLabelStyle;

  @override
  void initState() {
    super.initState();

    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();

    _validationManager = CurrencyValidationManager();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shadowAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _initializeController();
  }

  @override
  void didUpdateWidget(covariant CurrencyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }

    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();

    if (_ownsController) _controller.dispose();

    _validationManager.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeController() {
    // Si viene vacío al inicio, mantener 0.00 (si treatEmptyAsZero=true)
    if (widget.treatEmptyAsZero) {
      if (_controller.text.isEmpty ||
          _controller.text == '0' ||
          _controller.text == '0.0') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _controller.text = '0.${'0' * widget.decimalPlaces}';
          _controller.selection =
              TextSelection.collapsed(offset: _controller.text.length);
        });
      }
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    final focused = _focusNode.hasFocus;

    setState(() => _isFocused = focused);

    if (focused) {
      _animationController.forward();
    } else {
      _animationController.reverse();

      // ✅ Normalizar a 0.00 al perder foco SOLO si treatEmptyAsZero=true
      if (widget.treatEmptyAsZero) {
        final raw = _controller.text.trim();
        if (raw.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _controller.text = '0.${'0' * widget.decimalPlaces}';
            _controller.selection =
                TextSelection.collapsed(offset: _controller.text.length);
          });
        }
      }
    }
  }

  /// ✅ validador default que respeta allowZero/requiredField/treatEmptyAsZero
  String? _defaultValidator(String? value) {
    final v = (value ?? '').trim();

    // Si permites vacío real (treatEmptyAsZero=false) y no es requerido, no hay error.
    if (v.isEmpty) {
      if (widget.requiredField) return 'Campo requerido';
      return null;
    }

    final amount = CurrencyUtilsImproved.parseToDouble(v);

    // Si queda 0.00 por borrado/formateo:
    if (amount == 0) {
      if (widget.allowZero) return null;
      return 'El monto debe ser mayor a 0';
    }

    if (amount < 0) return 'Monto inválido';

    if (widget.minAmount != null && amount < widget.minAmount!) {
      return 'Monto mínimo: ${widget.currencySymbol} ${widget.minAmount!.toStringAsFixed(widget.decimalPlaces)}';
    }

    if (widget.maxAmount != null && amount > widget.maxAmount!) {
      return 'Monto máximo: ${widget.currencySymbol} ${widget.maxAmount!.toStringAsFixed(widget.decimalPlaces)}';
    }

    return null;
  }

  String? Function(String?) _getCombinedValidator() {
    return (value) {
      final defaultError = _defaultValidator(value);
      if (defaultError != null) return defaultError;

      if (widget.validator != null) {
        return widget.validator!(value);
      }
      return null;
    };
  }

  BorderRadius _getCachedBorderRadius() =>
      _cachedBorderRadius ??= BorderRadius.circular(widget.borderRadius);

  EdgeInsetsGeometry _getCachedContentPadding() {
    if (_cachedContentPadding != null) return _cachedContentPadding!;

    if (widget.contentPadding != null) {
      _cachedContentPadding = widget.contentPadding;
      return _cachedContentPadding!;
    }

    // ✅ AJUSTE ESPECÍFICO POR ALTURA PARA CENTRADO PERFECTO
    if (widget.height == 38) {
      _cachedContentPadding = const EdgeInsets.fromLTRB(16, 12, 16, 11);
    } else if (widget.height == 35) {
      _cachedContentPadding = const EdgeInsets.fromLTRB(16, 10.5, 16, 10);
    } else if (widget.height == 40) {
      _cachedContentPadding = const EdgeInsets.fromLTRB(16, 13, 16, 12);
    } else {
      // Cálculo dinámico para otras alturas
      double fontSize = _getCachedTextStyle().fontSize ?? 10;
      double textHeight = fontSize * 1.5;
      double verticalPadding = ((widget.height ?? 35) - textHeight) / 2;
      _cachedContentPadding = EdgeInsets.symmetric(
        horizontal: 16,
        vertical: verticalPadding.clamp(8.0, 15.0),
      );
    }

    return _cachedContentPadding!;
  }

  TextStyle _getCachedTextStyle() {
    return _cachedTextStyle ??=
        widget.textStyle ??
        TextStyle(
          color: widget.enabled ? AppColors.blue2 : AppColors.blue3,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Oxygen-Regular',
          height: 1.0,
        );
  }

  TextStyle _getCachedHintStyle() {
    return _cachedHintStyle ??=
        widget.hintStyle ??
        TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
          fontWeight: FontWeight.w400,
          height: 1.0,
        );
  }

  TextStyle _getCachedLabelStyle() {
    return _cachedLabelStyle ??=
        widget.labelStyle ??
        TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: AppColors.blue1,
          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
        );
  }

  Color _getCachedBorderColor() {
    return widget.borderColor ??
        (_isFocused ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0));
  }

  Widget? _buildSymbolIcon() {
    if (!widget.showSymbolIcon) return null;
    return Text(
      widget.currencySymbol,
      style: _getCachedTextStyle().copyWith(
        color: widget.borderColor ?? AppColors.blue3,
        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
      ),
    );
  }

  Widget _buildValidationIcon() {
    return ValueListenableBuilder<ValidationState>(
      valueListenable: _validationManager.state,
      builder: (context, state, child) {
        return SizedBox(
          width: 16,
          height: 16,
          child: Center(
            child: switch (state) {
              ValidationLoading() => const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1),
                ),
              ValidationValid() =>
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ValidationInvalid() =>
                const Icon(Icons.error, color: Colors.red, size: 16),
              ValidationNone() => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorText() {
    return ValueListenableBuilder<ValidationState>(
      valueListenable: _validationManager.state,
      builder: (context, state, child) {
        if (state is ValidationInvalid) {
          return Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              state.error,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 8,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<BoxShadow> _buildShadows() {
    final intensity = _shadowAnimation.value;
    final borderColor = _getCachedBorderColor();
    final shadowColor = _getShadowColor(borderColor);

    if (_isFocused) {
      return [
        BoxShadow(
          color: borderColor.withValues(alpha: 0.25 + (intensity * 0.2)),
          offset: const Offset(0, 3),
          blurRadius: 4 + (intensity * 2),
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
      ),
      BoxShadow(
        color: borderColor.withValues(alpha: 0.15),
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

  Color _getShadowColor(Color borderColor) {
    if (borderColor == AppColors.blue ||
        borderColor == const Color(0xFF1976D2)) {
      return const Color(0xFF0D47A1);
    } else if (borderColor == Colors.green ||
        borderColor == const Color(0xFF4CAF50)) {
      return const Color(0xFF1B5E20);
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

  @override
  Widget build(BuildContext context) {
    final combinedValidator = _getCombinedValidator();

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(widget.label!, style: _getCachedLabelStyle()),
            const SizedBox(height: 2),
          ],
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: widget.filled
                        ? widget.backgroundColor
                        : Colors.transparent,
                    borderRadius: _getCachedBorderRadius(),
                    boxShadow: widget.filled ? _buildShadows() : null,
                    border: Border.all(
                      color: _getCachedBorderColor(),
                      width: widget.borderWidth ?? 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: _getCachedBorderRadius(),
                    child: TextFormField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLines: 1,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        CurrencyFormatterImproved(
                          symbol: widget.currencySymbol,
                          decimalPlaces: widget.decimalPlaces,
                          locale: 'es',
                        ),
                      ],
                      cursorHeight: widget.cursorHeight ?? 14,
                      cursorWidth: widget.cursorWidth ?? 1.5,
                      cursorColor: widget.cursorColor ?? AppColors.blue2,
                      style: _getCachedTextStyle(),
                      validator: combinedValidator,
                      onChanged: (value) {
                        if (widget.enableRealTimeValidation) {
                          _validationManager.startValidation(
                            value,
                            widget.validationDelay,
                            combinedValidator,
                          );
                        }

                        if (widget.onChanged != null) {
                          final numValue =
                              CurrencyUtilsImproved.parseToDouble(value);
                          widget.onChanged!(numValue);
                        }
                      },
                      onFieldSubmitted: (value) {
                        if (widget.onSubmitted != null) {
                          final numValue =
                              CurrencyUtilsImproved.parseToDouble(value);
                          widget.onSubmitted!(numValue);
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.hintText ?? '0.00',
                        hintStyle: _getCachedHintStyle(),
                        contentPadding: _getCachedContentPadding(),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,

                        // ✅ símbolo: o icono o texto, pero no ambos
                        prefixIcon: widget.showSymbolIcon
                            ? Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: _buildSymbolIcon(),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  '${widget.currencySymbol} ',
                                  style: _getCachedTextStyle().copyWith(
                                    color: AppColors.blueGrey,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),

                        suffixIcon: widget.enableRealTimeValidation
                            ? Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _buildValidationIcon(),
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.enableRealTimeValidation) _buildErrorText(),
        ],
      ),
    );
  }
}

/// 💰 Helper opcional
class CurrencyTextFieldHelper {
  static CurrencyTextField create({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String currencySymbol = 'S/',
    int decimalPlaces = 2,
    bool requiredField = false,
    bool allowZero = true,
    bool treatEmptyAsZero = true,
    double? minAmount,
    double? maxAmount,
    String? Function(String?)? validator,
    void Function(double)? onChanged,
  }) {
    return CurrencyTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      currencySymbol: currencySymbol,
      decimalPlaces: decimalPlaces,
      requiredField: requiredField,
      allowZero: allowZero,
      treatEmptyAsZero: treatEmptyAsZero,
      minAmount: minAmount,
      maxAmount: maxAmount,
      validator: validator,
      onChanged: onChanged,
    );
  }
}

