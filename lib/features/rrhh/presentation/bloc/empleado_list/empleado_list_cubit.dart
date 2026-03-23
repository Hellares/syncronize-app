import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/empleado.dart';
import '../../../domain/repositories/empleado_repository.dart';
import 'empleado_list_state.dart';

@injectable
class EmpleadoListCubit extends Cubit<EmpleadoListState> {
  final EmpleadoRepository _repository;

  Map<String, dynamic> _lastParams = {};

  EmpleadoListCubit(this._repository) : super(const EmpleadoListInitial());

  Future<void> loadEmpleados({
    String? sedeId,
    String? estado,
    String? search,
    int? page,
  }) async {
    _lastParams = {
      if (sedeId != null) 'sedeId': sedeId,
      if (estado != null) 'estado': estado,
      if (search != null) 'search': search,
      if (page != null) 'page': page.toString(),
    };

    emit(const EmpleadoListLoading());

    final result = await _repository.getAll(queryParams: _lastParams);
    if (isClosed) return;

    if (result is Success<List<Empleado>>) {
      emit(EmpleadoListLoaded(result.data));
    } else if (result is Error) {
      emit(EmpleadoListError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadEmpleados(
      sedeId: _lastParams['sedeId'],
      estado: _lastParams['estado'],
      search: _lastParams['search'],
      page: _lastParams['page'] != null
          ? int.tryParse(_lastParams['page'])
          : null,
    );
  }
}
