import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/vinculacion.dart';
import '../../../domain/usecases/listar_vinculaciones_usecase.dart';
import 'vinculacion_list_state.dart';

@injectable
class VinculacionListCubit extends Cubit<VinculacionListState> {
  final ListarVinculacionesUseCase _listarUseCase;

  VinculacionListCubit(this._listarUseCase)
      : super(const VinculacionListInitial());

  String? _empresaId;
  String? _tipo;
  String? _estado;
  List<VinculacionEmpresa> _allItems = [];
  bool _isLoadingMore = false;

  Future<void> load({
    required String empresaId,
    String? tipo,
    String? estado,
  }) async {
    _empresaId = empresaId;
    _tipo = tipo;
    _estado = estado;
    _allItems = [];

    emit(const VinculacionListLoading());

    final result = await _listarUseCase(
      empresaId: empresaId,
      tipo: tipo,
      estado: estado,
      page: 1,
    );

    if (isClosed) return;

    if (result is Success<VinculacionesPaginadas>) {
      final data = result.data;
      _allItems = data.data;
      emit(VinculacionListLoaded(
        items: _allItems,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        tipo: tipo,
        estado: estado,
      ));
    } else if (result is Error<VinculacionesPaginadas>) {
      emit(VinculacionListError(result.message));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! VinculacionListLoaded) return;
    if (!currentState.hasMore || _empresaId == null) return;
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final nextPage = currentState.page + 1;
    final result = await _listarUseCase(
      empresaId: _empresaId!,
      tipo: _tipo,
      estado: _estado,
      page: nextPage,
    );

    if (isClosed) {
      _isLoadingMore = false;
      return;
    }
    _isLoadingMore = false;

    if (result is Success<VinculacionesPaginadas>) {
      final data = result.data;
      _allItems = [..._allItems, ...data.data];
      emit(VinculacionListLoaded(
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
