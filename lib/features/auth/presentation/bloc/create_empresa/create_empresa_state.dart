part of 'create_empresa_cubit.dart';

/// Estados del CreateEmpresaCubit
class CreateEmpresaState extends Equatable {
  final BlocFormItem nombre;
  final BlocFormItem ruc;
  final BlocFormItem descripcion;
  final BlocFormItem telefono;
  final BlocFormItem email;
  final BlocFormItem web;
  final BlocFormItem subdominio;
  final BlocFormItem rubro;
  final Resource? response;
  final GlobalKey<FormState>? formKey;

  const CreateEmpresaState({
    this.nombre = const BlocFormItem(value: '', error: null),
    this.ruc = const BlocFormItem(value: '', error: null),
    this.descripcion = const BlocFormItem(value: '', error: null),
    this.telefono = const BlocFormItem(value: '', error: null),
    this.email = const BlocFormItem(value: '', error: null),
    this.web = const BlocFormItem(value: '', error: null),
    this.subdominio = const BlocFormItem(value: '', error: null),
    this.rubro = const BlocFormItem(value: '', error: null),
    this.response,
    this.formKey,
  });

  CreateEmpresaState copyWith({
    BlocFormItem? nombre,
    BlocFormItem? ruc,
    BlocFormItem? descripcion,
    BlocFormItem? telefono,
    BlocFormItem? email,
    BlocFormItem? web,
    BlocFormItem? subdominio,
    BlocFormItem? rubro,
    Resource? response,
    GlobalKey<FormState>? formKey,
  }) {
    return CreateEmpresaState(
      nombre: nombre ?? this.nombre,
      ruc: ruc ?? this.ruc,
      descripcion: descripcion ?? this.descripcion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      web: web ?? this.web,
      subdominio: subdominio ?? this.subdominio,
      rubro: rubro ?? this.rubro,
      response: response,
      formKey: formKey ?? this.formKey,
    );
  }

  @override
  List<Object?> get props => [
        nombre,
        ruc,
        descripcion,
        telefono,
        email,
        web,
        subdominio,
        rubro,
        response,
      ];
}
