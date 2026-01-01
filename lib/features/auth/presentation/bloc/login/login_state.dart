// part of 'login_cubit.dart';

// /// Estados del LoginCubit
// class LoginState extends Equatable {
//   final BlocFormItem email;
//   final BlocFormItem password;
//   final Resource? response;
//   final GlobalKey<FormState>? formKey;

//   // Almacenar temporalmente el Google ID Token cuando requiere selección de empresa
//   final String? googleIdToken;

//   const LoginState({
//     this.email = const BlocFormItem(value: '', error: null),
//     this.password = const BlocFormItem(value: '', error: null),
//     this.response,
//     this.formKey,
//     this.googleIdToken,
//   });

//   LoginState copyWith({
//     BlocFormItem? email,
//     BlocFormItem? password,
//     Resource? response,
//     GlobalKey<FormState>? formKey,
//     String? googleIdToken,
//     bool clearGoogleIdToken = false,
//   }) {
//     return LoginState(
//       email: email ?? this.email,
//       password: password ?? this.password,
//       response: response,
//       formKey: formKey ?? this.formKey,
//       googleIdToken: clearGoogleIdToken ? null : (googleIdToken ?? this.googleIdToken),
//     );
//   }

//   @override
//   List<Object?> get props => [email, password, response, googleIdToken];
// }

part of 'login_cubit.dart';

class LoginState extends Equatable {
  final BlocFormItem email;
  final BlocFormItem password;
  final Resource? response;
  final GlobalKey<FormState>? formKey;

  // ✅ Google
  final String? googleIdToken;
  final String? googleEmail;

  // ✅ UX pro (submit intent)
  final bool submitAttempt;

  // ✅ Multi-method auth
  final AuthMethodsResponse? availableMethods;
  final bool isCheckingMethods;
  final String? checkMethodsError;

  const LoginState({
    this.email = const BlocFormItem(value: '', error: null),
    this.password = const BlocFormItem(value: '', error: null),
    this.response,
    this.formKey,
    this.googleIdToken,
    this.googleEmail,
    this.submitAttempt = false,
    this.availableMethods,
    this.isCheckingMethods = false,
    this.checkMethodsError,
  });

  // ✅ Helpers para UI
  bool get shouldShowPasswordField =>
      availableMethods?.hasPassword ?? true; // Por defecto mostrar

  bool get shouldShowGoogleButton =>
      availableMethods?.hasGoogle ?? true; // Por defecto mostrar

  LoginState copyWith({
    BlocFormItem? email,
    BlocFormItem? password,
    Resource? response,
    GlobalKey<FormState>? formKey,

    // Google
    String? googleIdToken,
    String? googleEmail,
    bool clearGoogle = false,

    // UX
    bool? submitAttempt,

    // Multi-method auth
    AuthMethodsResponse? availableMethods,
    bool? isCheckingMethods,
    String? checkMethodsError,
    bool clearAvailableMethods = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      response: response,
      formKey: formKey ?? this.formKey,

      googleIdToken: clearGoogle ? null : (googleIdToken ?? this.googleIdToken),
      googleEmail: clearGoogle ? null : (googleEmail ?? this.googleEmail),

      submitAttempt: submitAttempt ?? this.submitAttempt,

      availableMethods: clearAvailableMethods ? null : (availableMethods ?? this.availableMethods),
      isCheckingMethods: isCheckingMethods ?? this.isCheckingMethods,
      checkMethodsError: checkMethodsError,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        response,
        googleIdToken,
        googleEmail,
        submitAttempt,
        availableMethods,
        isCheckingMethods,
        checkMethodsError,
      ];
}