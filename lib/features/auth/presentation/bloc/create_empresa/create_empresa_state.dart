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

  // Datos SUNAT (se llenan automáticamente al consultar RUC)
  final String? razonSocial;
  final String? condicionContribuyente;
  final String? estadoContribuyente;
  final String? tipoContribuyente;
  final String? direccionFiscal;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? ubigeo;

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
    this.razonSocial,
    this.condicionContribuyente,
    this.estadoContribuyente,
    this.tipoContribuyente,
    this.direccionFiscal,
    this.departamento,
    this.provincia,
    this.distrito,
    this.ubigeo,
    this.response,
    this.formKey,
  });

  bool get tieneDatosSunat => razonSocial != null && condicionContribuyente != null;
  bool get esHabido => condicionContribuyente?.toUpperCase() == 'HABIDO';

  CreateEmpresaState copyWith({
    BlocFormItem? nombre,
    BlocFormItem? ruc,
    BlocFormItem? descripcion,
    BlocFormItem? telefono,
    BlocFormItem? email,
    BlocFormItem? web,
    BlocFormItem? subdominio,
    BlocFormItem? rubro,
    String? razonSocial,
    String? condicionContribuyente,
    String? estadoContribuyente,
    String? tipoContribuyente,
    String? direccionFiscal,
    String? departamento,
    String? provincia,
    String? distrito,
    String? ubigeo,
    Resource? response,
    GlobalKey<FormState>? formKey,
    bool clearSunat = false,
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
      razonSocial: clearSunat ? null : (razonSocial ?? this.razonSocial),
      condicionContribuyente: clearSunat ? null : (condicionContribuyente ?? this.condicionContribuyente),
      estadoContribuyente: clearSunat ? null : (estadoContribuyente ?? this.estadoContribuyente),
      tipoContribuyente: clearSunat ? null : (tipoContribuyente ?? this.tipoContribuyente),
      direccionFiscal: clearSunat ? null : (direccionFiscal ?? this.direccionFiscal),
      departamento: clearSunat ? null : (departamento ?? this.departamento),
      provincia: clearSunat ? null : (provincia ?? this.provincia),
      distrito: clearSunat ? null : (distrito ?? this.distrito),
      ubigeo: clearSunat ? null : (ubigeo ?? this.ubigeo),
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
        razonSocial,
        condicionContribuyente,
        estadoContribuyente,
        tipoContribuyente,
        direccionFiscal,
        departamento,
        provincia,
        distrito,
        ubigeo,
        response,
      ];
}
