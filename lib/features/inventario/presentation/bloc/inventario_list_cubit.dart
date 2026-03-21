import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/inventario.dart';
import '../../domain/usecases/listar_inventarios_usecase.dart';
import 'inventario_list_state.dart';

@injectable
class InventarioListCubit extends Cubit<InventarioListState> {
  final ListarInventariosUseCase _listarUseCase;

  String? _filtroSedeId;
  String? _filtroEstado;

  InventarioListCubit(this._listarUseCase)
      : super(const InventarioListInitial());

  Future<void> loadInventarios({
    String? sedeId,
    String? estado,
  }) async {
    _filtroSedeId = sedeId;
    _filtroEstado = estado;

    emit(const InventarioListLoading());

    final result = await _listarUseCase(
      sedeId: sedeId,
      estado: estado,
    );
    if (isClosed) return;

    if (result is Success<List<Inventario>>) {
      emit(InventarioListLoaded(result.data));
    } else if (result is Error<List<Inventario>>) {
      emit(InventarioListError(result.message));
    }
  }

  Future<void> filterByEstado(String? estado) async {
    await loadInventarios(
      sedeId: _filtroSedeId,
      estado: estado,
    );
  }

  Future<void> filterBySede(String? sedeId) async {
    await loadInventarios(
      sedeId: sedeId,
      estado: _filtroEstado,
    );
  }

  Future<void> reload() async {
    await loadInventarios(
      sedeId: _filtroSedeId,
      estado: _filtroEstado,
    );
  }
}
