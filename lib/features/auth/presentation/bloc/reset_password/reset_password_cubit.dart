import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/bloc_form_item.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/reset_password_usecase.dart';

part 'reset_password_state.dart';

@injectable
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final ResetPasswordUseCase resetPasswordUseCase;

  ResetPasswordCubit(this.resetPasswordUseCase)
      : super(const ResetPasswordState());

  void setToken(String token) {
    emit(state.copyWith(token: token));
  }

  void passwordChanged(String value) {
    final trimmed = value.trim();
    emit(state.copyWith(
      password: BlocFormItem(value: trimmed, error: _validatePassword(trimmed)),
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
      error = 'Debes confirmar la contraseña';
    } else if (state.password.value != state.confirmPassword.value) {
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

    if (state.token.isEmpty) {
      emit(state.copyWith(
        response: Error('Enlace inválido. Solicita uno nuevo.'),
      ));
      return;
    }

    final passwordError = _validatePassword(state.password.value);
    if (passwordError != null) {
      emit(state.copyWith(
        password: state.password.copyWith(error: passwordError),
      ));
      return;
    }
    _validateConfirm();
    if (state.confirmPassword.error != null) return;

    emit(state.copyWith(response: Loading()));
    final result = await resetPasswordUseCase(
      ResetPasswordParams(
        resetToken: state.token,
        newPassword: state.password.value,
        confirmPassword: state.confirmPassword.value,
      ),
    );
    emit(state.copyWith(response: result));
  }
}
