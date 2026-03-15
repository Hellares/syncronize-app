part of 'complete_profile_cubit.dart';

class CompleteProfileState extends Equatable {
  final BlocFormItem dni;
  final BlocFormItem telefono;
  final BlocFormItem direccion;
  final Resource? response;

  // Datos de consulta DNI (RENIEC)
  final bool isConsultingDni;
  final String? dniError;
  final String? nombres;
  final String? apellidos;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final bool dniConsultado;

  // Vinculación de cuentas
  final bool dniPerteneceAOtro;
  final String? targetPersonaId;
  final bool isLinking;
  final Resource? linkResponse;

  const CompleteProfileState({
    this.dni = const BlocFormItem(value: '', error: null),
    this.telefono = const BlocFormItem(value: '', error: null),
    this.direccion = const BlocFormItem(value: '', error: null),
    this.response,
    this.isConsultingDni = false,
    this.dniError,
    this.nombres,
    this.apellidos,
    this.departamento,
    this.provincia,
    this.distrito,
    this.dniConsultado = false,
    this.dniPerteneceAOtro = false,
    this.targetPersonaId,
    this.isLinking = false,
    this.linkResponse,
  });

  CompleteProfileState copyWith({
    BlocFormItem? dni,
    BlocFormItem? telefono,
    BlocFormItem? direccion,
    Resource? response,
    bool? isConsultingDni,
    String? dniError,
    bool clearDniError = false,
    String? nombres,
    String? apellidos,
    String? departamento,
    String? provincia,
    String? distrito,
    bool? dniConsultado,
    bool? dniPerteneceAOtro,
    String? targetPersonaId,
    bool? isLinking,
    Resource? linkResponse,
  }) {
    return CompleteProfileState(
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      response: response,
      isConsultingDni: isConsultingDni ?? this.isConsultingDni,
      dniError: clearDniError ? null : (dniError ?? this.dniError),
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      departamento: departamento ?? this.departamento,
      provincia: provincia ?? this.provincia,
      distrito: distrito ?? this.distrito,
      dniConsultado: dniConsultado ?? this.dniConsultado,
      dniPerteneceAOtro: dniPerteneceAOtro ?? this.dniPerteneceAOtro,
      targetPersonaId: targetPersonaId ?? this.targetPersonaId,
      isLinking: isLinking ?? this.isLinking,
      linkResponse: linkResponse,
    );
  }

  @override
  List<Object?> get props => [
        dni,
        telefono,
        direccion,
        response,
        isConsultingDni,
        dniError,
        nombres,
        apellidos,
        departamento,
        provincia,
        distrito,
        dniConsultado,
        dniPerteneceAOtro,
        targetPersonaId,
        isLinking,
        linkResponse,
      ];
}
