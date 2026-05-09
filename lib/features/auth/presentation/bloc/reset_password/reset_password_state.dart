part of 'reset_password_cubit.dart';

class ResetPasswordState extends Equatable {
  final String token;
  final BlocFormItem password;
  final BlocFormItem confirmPassword;
  final Resource? response;
  final bool submitAttempt;

  const ResetPasswordState({
    this.token = '',
    this.password = const BlocFormItem(value: '', error: null),
    this.confirmPassword = const BlocFormItem(value: '', error: null),
    this.response,
    this.submitAttempt = false,
  });

  ResetPasswordState copyWith({
    String? token,
    BlocFormItem? password,
    BlocFormItem? confirmPassword,
    Resource? response,
    bool? submitAttempt,
  }) {
    return ResetPasswordState(
      token: token ?? this.token,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      response: response,
      submitAttempt: submitAttempt ?? this.submitAttempt,
    );
  }

  @override
  List<Object?> get props =>
      [token, password, confirmPassword, response, submitAttempt];
}
