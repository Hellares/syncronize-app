import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/utils/bloc_form_item.dart';

part 'register_state.dart';

/// Cubit para manejar el formulario y lógica de registro
@injectable
class RegisterCubit extends Cubit<RegisterState> {
  final RegisterUseCase registerUseCase;

  RegisterCubit({required this.registerUseCase}) : super(const RegisterState());

  /// Actualizar email
  void emailChanged(String value) {
    emit(state.copyWith(
      email: BlocFormItem(value: value, error: _validateEmail(value)),
      response: null,
    ));
  }

  /// Actualizar password
  void passwordChanged(String value) {
    emit(state.copyWith(
      password: BlocFormItem(value: value, error: _validatePassword(value)),
      response: null,
    ));
  }

  /// Actualizar nombres
  void nombresChanged(String value) {
    emit(state.copyWith(
      nombres: BlocFormItem(value: value, error: _validateNombres(value)),
      response: null,
    ));
  }

  /// Actualizar apellidos
  void apellidosChanged(String value) {
    emit(state.copyWith(
      apellidos: BlocFormItem(value: value, error: _validateApellidos(value)),
      response: null,
    ));
  }

  /// Actualizar teléfono
  void telefonoChanged(String value) {
    emit(state.copyWith(
      telefono: BlocFormItem(value: value, error: _validateTelefono(value)),
      response: null,
    ));
  }

  /// Actualizar DNI (opcional). Cuando el usuario lo completa, la pantalla
  /// de registro autocompleta nombres/apellidos vía RENIEC.
  void dniChanged(String value) {
    emit(state.copyWith(
      dni: BlocFormItem(value: value, error: _validateDni(value)),
      response: null,
    ));
  }

  /// Helper para autocompletar nombre/apellido/teléfono después de un
  /// lookup RENIEC exitoso. No afecta validaciones, sólo escribe valores.
  void datosRenieFill({
    required String nombres,
    required String apellidos,
    String? telefono,
  }) {
    emit(state.copyWith(
      nombres: BlocFormItem(value: nombres, error: _validateNombres(nombres)),
      apellidos: BlocFormItem(
          value: apellidos, error: _validateApellidos(apellidos)),
      telefono: telefono != null && telefono.isNotEmpty
          ? BlocFormItem(value: telefono, error: _validateTelefono(telefono))
          : state.telefono,
      response: null,
    ));
  }

  /// Validaciones
  String? _validateEmail(String value) {
    if (value.isEmpty) return 'El email es requerido';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Email inválido';
    return null;
  }

  /// Validar password (sincronizado con backend)
  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    // Validar que contenga al menos una mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una mayúscula';
    }
    // Validar que contenga al menos una minúscula
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una minúscula';
    }
    // Validar que contenga al menos un número
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    // Validar que contenga al menos un carácter especial
    if (!RegExp(r'[@$!%*?&_\-#^()+={}\[\]:;"' r"'<>,.\/\\|~`]").hasMatch(value)) {
      return 'Debe contener al menos un carácter especial';
    }
    return null;
  }

  String? _validateNombres(String value) {
    if (value.isEmpty) return 'Los nombres son requeridos';
    if (value.length < 2) return 'Mínimo 2 caracteres';
    return null;
  }

  String? _validateApellidos(String value) {
    if (value.isEmpty) return 'Los apellidos son requeridos';
    if (value.length < 2) return 'Mínimo 2 caracteres';
    return null;
  }

  String? _validateTelefono(String value) {
    // Teléfono es opcional
    if (value.isEmpty) return null;
    if (value.length < 9) return 'Teléfono inválido';
    return null;
  }

  /// DNI es opcional pero, si se ingresa, debe tener exactamente 8 dígitos.
  String? _validateDni(String value) {
    if (value.isEmpty) return null;
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'DNI debe tener 8 dígitos';
    }
    return null;
  }

  /// Validar formulario completo
  bool _isFormValid() {
    return _validateEmail(state.email.value) == null &&
        _validatePassword(state.password.value) == null &&
        _validateNombres(state.nombres.value) == null &&
        _validateApellidos(state.apellidos.value) == null &&
        _validateTelefono(state.telefono.value) == null &&
        _validateDni(state.dni.value) == null;
  }

  /// Registrar
  Future<void> register() async {
    // Validar formulario
    if (!_isFormValid()) {
      emit(state.copyWith(
        email: state.email.copyWith(error: _validateEmail(state.email.value)),
        password: state.password.copyWith(error: _validatePassword(state.password.value)),
        nombres: state.nombres.copyWith(error: _validateNombres(state.nombres.value)),
        apellidos: state.apellidos.copyWith(error: _validateApellidos(state.apellidos.value)),
        telefono: state.telefono.copyWith(error: _validateTelefono(state.telefono.value)),
        dni: state.dni.copyWith(error: _validateDni(state.dni.value)),
      ));
      return;
    }

    // Emitir Loading
    emit(state.copyWith(response: Loading()));

    final dniValue = state.dni.value.trim();
    final params = RegisterParams(
      email: state.email.value.trim(),
      password: state.password.value,
      nombres: state.nombres.value.trim(),
      apellidos: state.apellidos.value.trim(),
      telefono: state.telefono.value.trim().isEmpty ? null : state.telefono.value.trim(),
      dni: dniValue.isEmpty ? null : dniValue,
    );

    final result = await registerUseCase(params);

    // Actualizar estado con resultado
    emit(state.copyWith(response: result));
  }

  /// Resetear formulario
  void reset() {
    emit(const RegisterState());
  }
}
