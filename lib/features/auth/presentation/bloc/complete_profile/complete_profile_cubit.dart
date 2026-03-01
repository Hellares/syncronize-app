import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/update_profile_usecase.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/utils/bloc_form_item.dart';

part 'complete_profile_state.dart';

@injectable
class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;

  CompleteProfileCubit({required this.updateProfileUseCase})
      : super(const CompleteProfileState());

  /// Inicializar campos desde el usuario actual (pre-llenar datos existentes)
  void initFromUser(User user) {
    emit(CompleteProfileState(
      dni: BlocFormItem(value: user.dni ?? '', error: null),
      telefono: BlocFormItem(value: user.telefono ?? '', error: null),
      direccion: BlocFormItem(value: user.direccion ?? '', error: null),
    ));
  }

  void dniChanged(String value) {
    emit(state.copyWith(
      dni: BlocFormItem(value: value, error: _validateDni(value)),
      response: null,
    ));
  }

  void telefonoChanged(String value) {
    emit(state.copyWith(
      telefono: BlocFormItem(value: value, error: _validateTelefono(value)),
      response: null,
    ));
  }

  void direccionChanged(String value) {
    emit(state.copyWith(
      direccion: BlocFormItem(value: value, error: _validateDireccion(value)),
      response: null,
    ));
  }

  String? _validateDni(String value) {
    if (value.isEmpty) return 'El DNI es requerido';
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'El DNI debe tener 8 dígitos numéricos';
    }
    return null;
  }

  String? _validateTelefono(String value) {
    if (value.isEmpty) return 'El teléfono es requerido';
    if (!RegExp(r'^9\d{8}$').hasMatch(value)) {
      return 'Debe tener 9 dígitos y empezar con 9';
    }
    return null;
  }

  String? _validateDireccion(String value) {
    if (value.isEmpty) return 'La dirección es requerida';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    if (value.length > 255) return 'Máximo 255 caracteres';
    return null;
  }

  bool _isFormValid() {
    return _validateDni(state.dni.value) == null &&
        _validateTelefono(state.telefono.value) == null &&
        _validateDireccion(state.direccion.value) == null;
  }

  Future<void> submit() async {
    // Mostrar errores de validación
    if (!_isFormValid()) {
      emit(state.copyWith(
        dni: state.dni.copyWith(error: _validateDni(state.dni.value)),
        telefono: state.telefono.copyWith(error: _validateTelefono(state.telefono.value)),
        direccion: state.direccion.copyWith(error: _validateDireccion(state.direccion.value)),
      ));
      return;
    }

    emit(state.copyWith(response: Loading()));

    final result = await updateProfileUseCase(UpdateProfileParams(
      dni: state.dni.value.trim(),
      telefono: state.telefono.value.trim(),
      direccion: state.direccion.value.trim(),
    ));

    emit(state.copyWith(response: result));
  }
}
