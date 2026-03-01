part of 'complete_profile_cubit.dart';

class CompleteProfileState extends Equatable {
  final BlocFormItem dni;
  final BlocFormItem telefono;
  final BlocFormItem direccion;
  final Resource? response;

  const CompleteProfileState({
    this.dni = const BlocFormItem(value: '', error: null),
    this.telefono = const BlocFormItem(value: '', error: null),
    this.direccion = const BlocFormItem(value: '', error: null),
    this.response,
  });

  CompleteProfileState copyWith({
    BlocFormItem? dni,
    BlocFormItem? telefono,
    BlocFormItem? direccion,
    Resource? response,
  }) {
    return CompleteProfileState(
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      response: response,
    );
  }

  @override
  List<Object?> get props => [dni, telefono, direccion, response];
}
