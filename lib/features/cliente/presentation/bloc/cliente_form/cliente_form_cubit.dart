import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/registro_cliente_response.dart';
import '../../../domain/usecases/registrar_cliente_usecase.dart';
import 'cliente_form_state.dart';

@injectable
class ClienteFormCubit extends Cubit<ClienteFormState> {
  final RegistrarClienteUseCase _registrarClienteUseCase;

  ClienteFormCubit(this._registrarClienteUseCase)
      : super(const ClienteFormInitial());

  /// Registra un nuevo cliente
  Future<void> registrarCliente({
    required String empresaId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String telefono,
    String? email,
    String? direccion,
    String? distrito,
    String? provincia,
    String? departamento,
    String? notas,
  }) async {
    emit(const ClienteFormLoading());

    final result = await _registrarClienteUseCase(
      empresaId: empresaId,
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      telefono: telefono,
      email: email,
      direccion: direccion,
      distrito: distrito,
      provincia: provincia,
      departamento: departamento,
      notas: notas,
    );

    if (result is Success<RegistroClienteResponse>) {
      emit(ClienteFormSuccess(result.data));
    } else if (result is Error<RegistroClienteResponse>) {
      emit(ClienteFormError(result.message));
    }
  }

  /// Resetea el formulario al estado inicial
  void reset() {
    emit(const ClienteFormInitial());
  }
}
