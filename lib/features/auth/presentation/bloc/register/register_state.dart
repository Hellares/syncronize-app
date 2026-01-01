part of 'register_cubit.dart';

/// Estados del RegisterCubit
class RegisterState extends Equatable {
  final BlocFormItem email;
  final BlocFormItem password;
  final BlocFormItem nombres;
  final BlocFormItem apellidos;
  final BlocFormItem telefono;
  final Resource? response;
  final GlobalKey<FormState>? formKey;

  const RegisterState({
    this.email = const BlocFormItem(value: '', error: null),
    this.password = const BlocFormItem(value: '', error: null),
    this.nombres = const BlocFormItem(value: '', error: null),
    this.apellidos = const BlocFormItem(value: '', error: null),
    this.telefono = const BlocFormItem(value: '', error: null),
    this.response,
    this.formKey,
  });

  RegisterState copyWith({
    BlocFormItem? email,
    BlocFormItem? password,
    BlocFormItem? nombres,
    BlocFormItem? apellidos,
    BlocFormItem? telefono,
    Resource? response,
    GlobalKey<FormState>? formKey,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      response: response,
      formKey: formKey ?? this.formKey,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        nombres,
        apellidos,
        telefono,
        response,
      ];
}
