import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:syncronize/features/usuario/domain/entities/registro_usuario_response.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/registrar_usuario_usecase.dart';
import 'usuario_form_state.dart';

/// Cubit para manejar el formulario de usuario
@injectable
class UsuarioFormCubit extends Cubit<UsuarioFormState> {
  final RegistrarUsuarioUseCase _registrarUsuarioUseCase;

  UsuarioFormCubit(this._registrarUsuarioUseCase)
      : super(const UsuarioFormInitial());

  /// Registra un nuevo usuario
  Future<void> registrarUsuario({
    required String empresaId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String rol,
    String? email,
    List<String>? sedeIds,
    bool? puedeAbrirCaja,
    bool? puedeCerrarCaja,
    double? limiteCreditoVenta,
    List<String>? permisos,
    String? notas,
  }) async {
    emit(const UsuarioFormSubmitting());

    final result = await _registrarUsuarioUseCase(
      empresaId: empresaId,
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      telefono: telefono,
      rol: rol,
      email: email,
      sedeIds: sedeIds,
      puedeAbrirCaja: puedeAbrirCaja,
      puedeCerrarCaja: puedeCerrarCaja,
      limiteCreditoVenta: limiteCreditoVenta,
      permisos: permisos,
      notas: notas,
    );

    if (result is Success<RegistroUsuarioResponse>) {
      emit(UsuarioFormSuccess(result.data));
    } else if (result is Error<RegistroUsuarioResponse>) {
      emit(UsuarioFormError(result.message));
    }
  }

  /// Resetea el formulario
  void reset() {
    emit(const UsuarioFormInitial());
  }
}
