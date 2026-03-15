import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/auth_response.dart';
import '../../../domain/usecases/update_profile_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/utils/bloc_form_item.dart';

part 'complete_profile_state.dart';

@injectable
class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final ConsultarDniUseCase consultarDniUseCase;
  final AuthRepository authRepository;

  CompleteProfileCubit({
    required this.updateProfileUseCase,
    required this.consultarDniUseCase,
    required this.authRepository,
  }) : super(const CompleteProfileState());

  /// Inicializar campos desde el usuario actual (pre-llenar datos existentes)
  void initFromUser(User user) {
    emit(CompleteProfileState(
      dni: BlocFormItem(value: user.dni ?? '', error: null),
      telefono: BlocFormItem(value: user.telefono ?? '', error: null),
      direccion: BlocFormItem(value: user.direccion ?? '', error: null),
    ));
  }

  void dniChanged(String value) {
    emit(state.copyWith(
      dni: BlocFormItem(value: value, error: _validateDni(value)),
      response: null,
      clearDniError: true,
      dniConsultado: false,
      dniPerteneceAOtro: false,
      nombres: null,
      apellidos: null,
    ));
  }

  void telefonoChanged(String value) {
    emit(state.copyWith(
      telefono: BlocFormItem(value: value, error: _validateTelefono(value)),
      response: null,
    ));
  }

  void direccionChanged(String value) {
    emit(state.copyWith(
      direccion: BlocFormItem(value: value, error: _validateDireccion(value)),
      response: null,
    ));
  }

  /// Consultar datos del DNI en RENIEC via API externa
  Future<void> consultarDni() async {
    final dni = state.dni.value.trim();

    if (_validateDni(dni) != null) {
      emit(state.copyWith(
        dni: BlocFormItem(value: dni, error: _validateDni(dni)),
      ));
      return;
    }

    emit(state.copyWith(isConsultingDni: true, clearDniError: true));

    final result = await consultarDniUseCase(dni);

    if (result is Success<ConsultaDni>) {
      final data = result.data;

      // Verificar si el DNI pertenece a otra persona en el sistema
      final perteneceAOtro = data.existeEnSistema == true && data.personaId != null;

      // Auto-llenar dirección si está vacía
      final direccionActual = state.direccion.value.trim();
      final nuevaDireccion = direccionActual.isEmpty
          ? data.direccionCompleta
          : direccionActual;

      emit(state.copyWith(
        isConsultingDni: false,
        dniConsultado: true,
        dniPerteneceAOtro: perteneceAOtro,
        targetPersonaId: data.personaId,
        nombres: data.nombres,
        apellidos: data.apellidos,
        departamento: data.departamento,
        provincia: data.provincia,
        distrito: data.distrito,
        direccion: BlocFormItem(value: nuevaDireccion, error: null),
      ));
    } else if (result is Error) {
      emit(state.copyWith(
        isConsultingDni: false,
        dniError: (result as Error).message,
      ));
    }
  }

  /// Vincular cuenta actual (Google) con la cuenta existente (DNI)
  Future<void> confirmarVinculacion() async {
    if (state.targetPersonaId == null) return;

    emit(state.copyWith(isLinking: true, linkResponse: Loading()));

    final result = await authRepository.linkAccount(
      dni: state.dni.value.trim(),
      targetPersonaId: state.targetPersonaId!,
    );

    if (result is Success<AuthResponse>) {
      emit(state.copyWith(
        isLinking: false,
        linkResponse: result,
      ));
    } else if (result is Error) {
      emit(state.copyWith(
        isLinking: false,
        linkResponse: result,
      ));
    }
  }

  String? _validateDni(String value) {
    if (value.isEmpty) return 'El DNI es requerido';
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'El DNI debe tener 8 dígitos numéricos';
    }
    return null;
  }

  String? _validateTelefono(String value) {
    if (value.isEmpty) return 'El teléfono es requerido';
    if (!RegExp(r'^9\d{8}$').hasMatch(value)) {
      return 'Debe tener 9 dígitos y empezar con 9';
    }
    return null;
  }

  String? _validateDireccion(String value) {
    if (value.isEmpty) return 'La dirección es requerida';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    if (value.length > 255) return 'Máximo 255 caracteres';
    return null;
  }

  bool _isFormValid() {
    return _validateDni(state.dni.value) == null &&
        _validateTelefono(state.telefono.value) == null &&
        _validateDireccion(state.direccion.value) == null;
  }

  Future<void> submit() async {
    if (!_isFormValid()) {
      emit(state.copyWith(
        dni: state.dni.copyWith(error: _validateDni(state.dni.value)),
        telefono: state.telefono.copyWith(error: _validateTelefono(state.telefono.value)),
        direccion: state.direccion.copyWith(error: _validateDireccion(state.direccion.value)),
      ));
      return;
    }

    emit(state.copyWith(response: Loading()));

    final result = await updateProfileUseCase(UpdateProfileParams(
      dni: state.dni.value.trim(),
      telefono: state.telefono.value.trim(),
      direccion: state.direccion.value.trim(),
      nombres: state.nombres,
      apellidos: state.apellidos,
      departamento: state.departamento,
      provincia: state.provincia,
      distrito: state.distrito,
    ));

    emit(state.copyWith(response: result));
  }
}
