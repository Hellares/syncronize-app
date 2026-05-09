part of 'forgot_password_cubit.dart';

class ForgotPasswordState extends Equatable {
  final BlocFormItem email;
  final Resource? response;
  final bool submitAttempt;

  const ForgotPasswordState({
    this.email = const BlocFormItem(value: '', error: null),
    this.response,
    this.submitAttempt = false,
  });

  ForgotPasswordState copyWith({
    BlocFormItem? email,
    Resource? response,
    bool? submitAttempt,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      response: response,
      submitAttempt: submitAttempt ?? this.submitAttempt,
    );
  }

  @override
  List<Object?> get props => [email, response, submitAttempt];
}
