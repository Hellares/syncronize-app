import 'package:flutter/material.dart';

import '../fonts/app_fonts.dart';
import '../theme/app_colors.dart';

/// Clase para items del radio group
class RadioOption<T> {
  final T value;
  final String label;
  final String? description;
  final Widget? leading;
  final bool enabled;

  const RadioOption({
    required this.value,
    required this.label,
    this.description,
    this.leading,
    this.enabled = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Widget reutilizable para grupos de radio buttons con RadioGroup
///
/// Ejemplo de uso:
/// ```dart
/// CustomRadioGroup<String>(
///   label: 'Selecciona una opción',
///   value: _selectedValue,
///   options: [
///     RadioOption(value: 'option1', label: 'Opción 1'),
///     RadioOption(value: 'option2', label: 'Opción 2', description: 'Descripción opcional'),
///   ],
///   onChanged: (value) => setState(() => _selectedValue = value),
///   validator: (value) => value == null ? 'Debes seleccionar una opción' : null,
/// )
/// ```
class CustomRadioGroup<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<RadioOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Color? labelColor;
  final Color? activeColor;
  final TextStyle? labelStyle;
  final TextStyle? optionLabelStyle;
  final TextStyle? optionDescriptionStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;
  final bool showDividers;

  /// Si es true, muestra los radio buttons como tiles con más padding
  final bool useTiles;

  const CustomRadioGroup({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelColor,
    this.activeColor,
    this.labelStyle,
    this.optionLabelStyle,
    this.optionDescriptionStyle,
    this.contentPadding,
    this.dense = true,
    this.showDividers = false,
    this.useTiles = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        final hasError = state.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: labelStyle ??
                    TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? Colors.red[700]
                          : (labelColor ?? AppColors.blue1),
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: hasError
                  ? BoxDecoration(
                      border: Border.all(color: Colors.red.shade300, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: RadioGroup<T>(
                groupValue: value,
                onChanged: (T? newValue) {
                  if (enabled) {
                    onChanged?.call(newValue);
                    state.didChange(newValue);
                    state.validate();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildRadioOptions(context, state),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[700],
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildRadioOptions(
      BuildContext context, FormFieldState<T> state) {
    final List<Widget> widgets = [];

    for (int i = 0; i < options.length; i++) {
      final option = options[i];

      if (useTiles) {
        widgets.add(
          RadioListTile<T>(
            value: option.value,
            dense: dense,
            contentPadding: contentPadding ?? EdgeInsets.zero,
            activeColor: activeColor ?? AppColors.blue1,
            enabled: enabled && option.enabled,
            title: Row(
              children: [
                if (option.leading != null) ...[
                  option.leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: optionLabelStyle ??
                        TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: (enabled && option.enabled)
                              ? Colors.black87
                              : Colors.grey,
                          fontFamily:
                              AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                  ),
                ),
              ],
            ),
            subtitle: option.description != null
                ? Text(
                    option.description!,
                    style: optionDescriptionStyle ??
                        TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontFamily:
                              AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                  )
                : null,
          ),
        );
      } else {
        widgets.add(
          Radio<T>(
            value: option.value,
            activeColor: activeColor ?? AppColors.blue1,
          ),
        );
      }

      // Agregar divisor entre opciones si está habilitado
      if (showDividers && i < options.length - 1) {
        widgets.add(const Divider(height: 1));
      }
    }

    return widgets;
  }
}

/// Helpers para crear radio groups comunes
class CustomRadioGroupHelpers {
  /// Radio group estándar con validación requerida
  static CustomRadioGroup<T> required<T>({
    required String label,
    required List<RadioOption<T>> options,
    T? value,
    void Function(T?)? onChanged,
    Color? activeColor,
    String errorMessage = 'Debe seleccionar una opción',
  }) {
    return CustomRadioGroup<T>(
      label: label,
      options: options,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      validator: (value) => value == null ? errorMessage : null,
    );
  }

  /// Radio group sin validación
  static CustomRadioGroup<T> optional<T>({
    required String label,
    required List<RadioOption<T>> options,
    T? value,
    void Function(T?)? onChanged,
    Color? activeColor,
  }) {
    return CustomRadioGroup<T>(
      label: label,
      options: options,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }

  /// Radio group compacto (sin tiles, solo radios)
  static CustomRadioGroup<T> compact<T>({
    required String label,
    required List<RadioOption<T>> options,
    T? value,
    void Function(T?)? onChanged,
    Color? activeColor,
    String? Function(T?)? validator,
  }) {
    return CustomRadioGroup<T>(
      label: label,
      options: options,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      useTiles: false,
      dense: true,
      validator: validator,
    );
  }

  /// Radio group con divisores entre opciones
  static CustomRadioGroup<T> withDividers<T>({
    required String label,
    required List<RadioOption<T>> options,
    T? value,
    void Function(T?)? onChanged,
    Color? activeColor,
    String? Function(T?)? validator,
  }) {
    return CustomRadioGroup<T>(
      label: label,
      options: options,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      showDividers: true,
      validator: validator,
    );
  }
}
