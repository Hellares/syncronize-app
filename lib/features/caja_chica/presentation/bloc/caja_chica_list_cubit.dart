import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja_chica.dart';
import '../../domain/usecases/listar_cajas_chicas_usecase.dart';
import 'caja_chica_list_state.dart';

@injectable
class CajaChicaListCubit extends Cubit<CajaChicaListState> {
  final ListarCajasChicasUseCase _listarCajasChicasUseCase;

  String? _filtroSedeId;

  CajaChicaListCubit(this._listarCajasChicasUseCase)
      : super(const CajaChicaListInitial());

  Future<void> loadCajasChicas({String? sedeId}) async {
    _filtroSedeId = sedeId;
    emit(const CajaChicaListLoading());

    final result = await _listarCajasChicasUseCase(sedeId: sedeId);
    if (isClosed) return;

    if (result is Success<List<CajaChica>>) {
      emit(CajaChicaListLoaded(result.data));
    } else if (result is Error<List<CajaChica>>) {
      emit(CajaChicaListError(result.message));
    }
  }

  Future<void> reload() async {
    await loadCajasChicas(sedeId: _filtroSedeId);
  }
}
