import 'package:flutter/material.dart';
import 'custom_text_field.dart';

/// Campo de contraseña con toggle de visibilidad
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final String? errorText;
  final void Function(String)? onChanged;
  final bool enabled;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Contraseña',
    this.hint,
    this.validator,
    this.errorText,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      validator: widget.validator,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
