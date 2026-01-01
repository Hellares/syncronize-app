part of 'account_security_cubit.dart';

/// Estados del AccountSecurityCubit
class AccountSecurityState extends Equatable {
  final BlocFormItem password;
  final BlocFormItem confirmPassword;

  // Métodos disponibles del usuario actual
  final AuthMethodsResponse? availableMethods;
  final bool isLoadingMethods;

  // Estado de la operación de establecer contraseña
  final Resource? setPasswordResponse;

  // UX pro (submit intent)
  final bool submitAttempt;

  const AccountSecurityState({
    this.password = const BlocFormItem(value: '', error: null),
    this.confirmPassword = const BlocFormItem(value: '', error: null),
    this.availableMethods,
    this.isLoadingMethods = false,
    this.setPasswordResponse,
    this.submitAttempt = false,
  });

  // ✅ Helpers para UI
  bool get hasPassword => availableMethods?.hasPassword ?? false;
  bool get hasGoogle => availableMethods?.hasGoogle ?? false;
  bool get hasMultipleMethods => availableMethods?.hasMultipleMethods ?? false;
  bool get canAddPassword => !hasPassword && hasGoogle;

  AccountSecurityState copyWith({
    BlocFormItem? password,
    BlocFormItem? confirmPassword,
    AuthMethodsResponse? availableMethods,
    bool? isLoadingMethods,
    Resource? setPasswordResponse,
    bool? submitAttempt,
    bool clearAvailableMethods = false,
  }) {
    return AccountSecurityState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      availableMethods: clearAvailableMethods ? null : (availableMethods ?? this.availableMethods),
      isLoadingMethods: isLoadingMethods ?? this.isLoadingMethods,
      setPasswordResponse: setPasswordResponse,
      submitAttempt: submitAttempt ?? this.submitAttempt,
    );
  }

  @override
  List<Object?> get props => [
        password,
        confirmPassword,
        availableMethods,
        isLoadingMethods,
        setPasswordResponse,
        submitAttempt,
      ];
}
