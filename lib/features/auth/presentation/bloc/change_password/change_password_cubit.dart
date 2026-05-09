import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/bloc_form_item.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/change_password_usecase.dart';

part 'change_password_state.dart';

@injectable
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ChangePasswordCubit(this.changePasswordUseCase)
      : super(const ChangePasswordState());

  void currentPasswordChanged(String value) {
    emit(state.copyWith(
      currentPassword: BlocFormItem(
        value: value,
        error: value.isEmpty ? 'La contraseña actual es requerida' : null,
      ),
      response: null,
    ));
  }

  void newPasswordChanged(String value) {
    final trimmed = value.trim();
    emit(state.copyWith(
      newPassword:
          BlocFormItem(value: trimmed, error: _validatePassword(trimmed)),
      response: null,
    ));
    if (state.confirmPassword.value.isNotEmpty) _validateConfirm();
  }

  void confirmPasswordChanged(String value) {
    final trimmed = value.trim();
    emit(state.copyWith(
      confirmPassword: state.confirmPassword.copyWith(value: trimmed),
      response: null,
    ));
    _validateConfirm();
  }

  void _validateConfirm() {
    String? error;
    if (state.confirmPassword.value.isEmpty) {
      error = 'Debes confirmar la nueva contraseña';
    } else if (state.newPassword.value != state.confirmPassword.value) {
      error = 'Las contraseñas no coinciden';
    }
    emit(state.copyWith(
      confirmPassword: state.confirmPassword.copyWith(error: error),
    ));
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una minúscula';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
      return 'Debe contener un carácter especial (@\$!%*?&)';
    }
    return null;
  }

  Future<void> submit() async {
    emit(state.copyWith(submitAttempt: true));
    emit(state.copyWith(submitAttempt: false));

    if (state.currentPassword.value.isEmpty) {
      emit(state.copyWith(
        currentPassword: state.currentPassword.copyWith(
          error: 'La contraseña actual es requerida',
        ),
      ));
      return;
    }

    final newError = _validatePassword(state.newPassword.value);
    if (newError != null) {
      emit(state.copyWith(
        newPassword: state.newPassword.copyWith(error: newError),
      ));
      return;
    }
    _validateConfirm();
    if (state.confirmPassword.error != null) return;

    if (state.currentPassword.value == state.newPassword.value) {
      emit(state.copyWith(
        newPassword: state.newPassword.copyWith(
          error: 'La nueva contraseña debe ser distinta a la actual',
        ),
      ));
      return;
    }

    emit(state.copyWith(response: Loading()));
    final result = await changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: state.currentPassword.value,
        newPassword: state.newPassword.value,
        confirmPassword: state.confirmPassword.value,
      ),
    );
    emit(state.copyWith(response: result));
  }
}
