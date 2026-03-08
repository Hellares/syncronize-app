import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/tercerizacion.dart';
import '../../../domain/usecases/listar_tercerizaciones_usecase.dart';
import 'tercerizacion_list_state.dart';

@injectable
class TercerizacionListCubit extends Cubit<TercerizacionListState> {
  final ListarTercerizacionesUseCase _listarUseCase;

  TercerizacionListCubit(this._listarUseCase)
      : super(const TercerizacionListInitial());

  String? _empresaId;
  String? _tipo;
  String? _estado;
  List<TercerizacionServicio> _allItems = [];

  Future<void> load({
    required String empresaId,
    String? tipo,
    String? estado,
  }) async {
    _empresaId = empresaId;
    _tipo = tipo;
    _estado = estado;
    _allItems = [];

    emit(const TercerizacionListLoading());

    final result = await _listarUseCase(
      empresaId: empresaId,
      tipo: tipo,
      estado: estado,
      page: 1,
    );

    if (isClosed) return;

    if (result is Success<TercerizacionesPaginadas>) {
      final data = result.data;
      _allItems = data.data;
      emit(TercerizacionListLoaded(
        items: _allItems,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        tipo: tipo,
        estado: estado,
      ));
    } else if (result is Error<TercerizacionesPaginadas>) {
      emit(TercerizacionListError(result.message));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! TercerizacionListLoaded) return;
    if (!currentState.hasMore || _empresaId == null) return;

    final nextPage = currentState.page + 1;
    final result = await _listarUseCase(
      empresaId: _empresaId!,
      tipo: _tipo,
      estado: _estado,
      page: nextPage,
    );

    if (isClosed) return;

    if (result is Success<TercerizacionesPaginadas>) {
      final data = result.data;
      _allItems = [..._allItems, ...data.data];
      emit(TercerizacionListLoaded(
        items: _allItems,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        tipo: _tipo,
        estado: _estado,
      ));
    }
  }

  Future<void> filterByTipo(String? tipo) async {
    if (_empresaId == null) return;
    await load(empresaId: _empresaId!, tipo: tipo, estado: _estado);
  }

  Future<void> filterByEstado(String? estado) async {
    if (_empresaId == null) return;
    await load(empresaId: _empresaId!, tipo: _tipo, estado: estado);
  }

  Future<void> refresh() async {
    if (_empresaId == null) return;
    await load(empresaId: _empresaId!, tipo: _tipo, estado: _estado);
  }
}
