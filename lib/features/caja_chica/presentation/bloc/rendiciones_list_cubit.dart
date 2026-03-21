import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/rendicion_caja_chica.dart';
import '../../domain/usecases/listar_rendiciones_usecase.dart';
import 'rendiciones_list_state.dart';

@injectable
class RendicionesListCubit extends Cubit<RendicionesListState> {
  final ListarRendicionesUseCase _listarRendicionesUseCase;

  String? _filtroCajaChicaId;
  String? _filtroEstado;

  RendicionesListCubit(this._listarRendicionesUseCase)
      : super(const RendicionesListInitial());

  Future<void> loadRendiciones({
    String? cajaChicaId,
    String? estado,
  }) async {
    _filtroCajaChicaId = cajaChicaId;
    _filtroEstado = estado;

    emit(const RendicionesListLoading());

    final result = await _listarRendicionesUseCase(
      cajaChicaId: cajaChicaId,
      estado: estado,
    );
    if (isClosed) return;

    if (result is Success<List<RendicionCajaChica>>) {
      emit(RendicionesListLoaded(result.data));
    } else if (result is Error<List<RendicionCajaChica>>) {
      emit(RendicionesListError(result.message));
    }
  }

  Future<void> filterByEstado(String? estado) async {
    await loadRendiciones(
      cajaChicaId: _filtroCajaChicaId,
      estado: estado,
    );
  }

  Future<void> reload() async {
    await loadRendiciones(
      cajaChicaId: _filtroCajaChicaId,
      estado: _filtroEstado,
    );
  }
}
