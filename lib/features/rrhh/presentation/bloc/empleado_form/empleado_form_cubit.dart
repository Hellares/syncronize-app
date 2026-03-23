import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/empleado.dart';
import '../../../domain/repositories/empleado_repository.dart';
import 'empleado_form_state.dart';

@injectable
class EmpleadoFormCubit extends Cubit<EmpleadoFormState> {
  final EmpleadoRepository _repository;

  EmpleadoFormCubit(this._repository) : super(const EmpleadoFormInitial());

  Future<void> crearEmpleado(Map<String, dynamic> data) async {
    emit(const EmpleadoFormSubmitting());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Empleado>) {
      emit(EmpleadoFormSuccess(result.data));
    } else if (result is Error) {
      emit(EmpleadoFormError((result as Error).message));
    }
  }

  Future<void> actualizarEmpleado(
    String id,
    Map<String, dynamic> data,
  ) async {
    emit(const EmpleadoFormSubmitting());

    final result = await _repository.update(id, data);
    if (isClosed) return;

    if (result is Success<Empleado>) {
      emit(EmpleadoFormSuccess(result.data));
    } else if (result is Error) {
      emit(EmpleadoFormError((result as Error).message));
    }
  }

  void reset() {
    emit(const EmpleadoFormInitial());
  }
}
