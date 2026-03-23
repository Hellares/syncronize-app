import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/empleado.dart';
import '../../../domain/repositories/empleado_repository.dart';
import 'empleado_detail_state.dart';

@injectable
class EmpleadoDetailCubit extends Cubit<EmpleadoDetailState> {
  final EmpleadoRepository _repository;

  EmpleadoDetailCubit(this._repository)
      : super(const EmpleadoDetailInitial());

  Future<void> loadEmpleado(String id) async {
    emit(const EmpleadoDetailLoading());

    final result = await _repository.getById(id);
    if (isClosed) return;

    if (result is Success<Empleado>) {
      emit(EmpleadoDetailLoaded(result.data));
    } else if (result is Error) {
      emit(EmpleadoDetailError((result as Error).message));
    }
  }

  Future<void> refresh(String id) async {
    await loadEmpleado(id);
  }
}
