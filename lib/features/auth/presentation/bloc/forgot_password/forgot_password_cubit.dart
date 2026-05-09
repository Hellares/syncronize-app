import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/bloc_form_item.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/forgot_password_usecase.dart';

part 'forgot_password_state.dart';

@injectable
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ForgotPasswordUseCase forgotPasswordUseCase;

  ForgotPasswordCubit(this.forgotPasswordUseCase)
      : super(const ForgotPasswordState());

  void emailChanged(String value) {
    emit(state.copyWith(
      email: BlocFormItem(value: value.trim(), error: _validateEmail(value)),
      response: null,
    ));
  }

  String? _validateEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'El email es requerido';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(v)) return 'Email inválido';
    return null;
  }

  Future<void> submit() async {
    emit(state.copyWith(submitAttempt: true));
    emit(state.copyWith(submitAttempt: false));

    final emailError = _validateEmail(state.email.value);
    if (emailError != null) {
      emit(state.copyWith(
        email: state.email.copyWith(error: emailError),
      ));
      return;
    }

    emit(state.copyWith(response: Loading()));
    final result = await forgotPasswordUseCase(
      ForgotPasswordParams(email: state.email.value),
    );
    emit(state.copyWith(response: result));
  }
}
