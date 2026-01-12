import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../empresa/domain/entities/sede.dart';
import '../../../domain/usecases/delete_sede_usecase.dart';
import '../../../domain/usecases/get_sedes_usecase.dart';
import 'sede_list_state.dart';

@injectable
class SedeListCubit extends Cubit<SedeListState> {
  final GetSedesUseCase _getSedesUseCase;
  final DeleteSedeUseCase _deleteSedeUseCase;

  SedeListCubit(
    this._getSedesUseCase,
    this._deleteSedeUseCase,
  ) : super(const SedeListInitial());

  String? _currentEmpresaId;

  /// Carga la lista de sedes
  Future<void> loadSedes(String empresaId) async {
    _currentEmpresaId = empresaId;

    emit(const SedeListLoading());

    final result = await _getSedesUseCase(empresaId);

    if (isClosed) return;

    if (result is Success<List<Sede>>) {
      emit(SedeListLoaded(result.data));
    } else if (result is Error<List<Sede>>) {
      emit(SedeListError(result.message, errorCode: result.errorCode));
    }
  }

  /// Recarga la lista de sedes
  Future<void> refresh() async {
    if (_currentEmpresaId == null) return;
    await loadSedes(_currentEmpresaId!);
  }

  /// Elimina una sede
  Future<bool> deleteSede(String sedeId) async {
    if (_currentEmpresaId == null) return false;

    final result = await _deleteSedeUseCase(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId,
    );

    if (result is Success) {
      // Recargar la lista después de eliminar
      await refresh();
      return true;
    } else if (result is Error) {
      emit(SedeListError(result.message, errorCode: result.errorCode));
      return false;
    }

    return false;
  }
}
