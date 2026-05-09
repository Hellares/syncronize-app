part of 'change_password_cubit.dart';

class ChangePasswordState extends Equatable {
  final BlocFormItem currentPassword;
  final BlocFormItem newPassword;
  final BlocFormItem confirmPassword;
  final Resource? response;
  final bool submitAttempt;

  const ChangePasswordState({
    this.currentPassword = const BlocFormItem(value: '', error: null),
    this.newPassword = const BlocFormItem(value: '', error: null),
    this.confirmPassword = const BlocFormItem(value: '', error: null),
    this.response,
    this.submitAttempt = false,
  });

  ChangePasswordState copyWith({
    BlocFormItem? currentPassword,
    BlocFormItem? newPassword,
    BlocFormItem? confirmPassword,
    Resource? response,
    bool? submitAttempt,
  }) {
    return ChangePasswordState(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      response: response,
      submitAttempt: submitAttempt ?? this.submitAttempt,
    );
  }

  @override
  List<Object?> get props => [
        currentPassword,
        newPassword,
        confirmPassword,
        response,
        submitAttempt,
      ];
}
