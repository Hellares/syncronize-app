import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/politica_descuento.dart';
import '../../../domain/usecases/get_politicas_descuento.dart';
import '../../../domain/usecases/delete_politica.dart';
import 'politica_list_state.dart';

@injectable
class PoliticaListCubit extends Cubit<PoliticaListState> {
  final GetPoliticasDescuento _getPoliticasDescuento;
  final DeletePolitica _deletePolitica;

  PoliticaListCubit(
    this._getPoliticasDescuento,
    this._deletePolitica,
  ) : super(const PoliticaListInitial());

  int _currentPage = 1;
  int _limit = 20;
  String? _tipoDescuentoFiltro;
  bool? _isActiveFiltro;
  List<PoliticaDescuento> _allPoliticas = [];
  int _total = 0;

  /// Carga la lista de políticas de descuento
  Future<void> loadPoliticas({
    String? tipoDescuento,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    _currentPage = page;
    _limit = limit;
    _tipoDescuentoFiltro = tipoDescuento;
    _isActiveFiltro = isActive;
    _allPoliticas = [];

    emit(const PoliticaListLoading());

    final result = await _getPoliticasDescuento(
      tipoDescuento: tipoDescuento,
      isActive: isActive,
      page: page,
      limit: limit,
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      _allPoliticas = List<PoliticaDescuento>.from(data['data'] ?? []);
      _total = data['total'] ?? 0;

      emit(PoliticaListLoaded(
        politicas: _allPoliticas,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        tipoDescuentoFiltro: _tipoDescuentoFiltro,
        isActiveFiltro: _isActiveFiltro,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(PoliticaListError(result.message, errorCode: result.errorCode));
    }
  }

  /// Carga más políticas (paginación)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! PoliticaListLoaded) return;
    if (!currentState.hasMore) return;

    emit(PoliticaListLoadingMore(_allPoliticas));

    final nextPage = _currentPage + 1;

    final result = await _getPoliticasDescuento(
      tipoDescuento: _tipoDescuentoFiltro,
      isActive: _isActiveFiltro,
      page: nextPage,
      limit: _limit,
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final newPoliticas = List<PoliticaDescuento>.from(data['data'] ?? []);
      _allPoliticas.addAll(newPoliticas);
      _currentPage = nextPage;
      _total = data['total'] ?? _total;

      emit(PoliticaListLoaded(
        politicas: _allPoliticas,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        tipoDescuentoFiltro: _tipoDescuentoFiltro,
        isActiveFiltro: _isActiveFiltro,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      // Volver al estado anterior en caso de error
      emit(currentState);
    }
  }

  /// Aplica filtros y recarga la lista
  Future<void> applyFiltros({
    String? tipoDescuento,
    bool? isActive,
  }) async {
    await loadPoliticas(
      tipoDescuento: tipoDescuento,
      isActive: isActive,
      page: 1,
      limit: _limit,
    );
  }

  /// Resetea los filtros
  Future<void> resetFiltros() async {
    await loadPoliticas(
      page: 1,
      limit: _limit,
    );
  }

  /// Recarga la lista actual
  Future<void> reload() async {
    await loadPoliticas(
      tipoDescuento: _tipoDescuentoFiltro,
      isActive: _isActiveFiltro,
      page: 1,
      limit: _limit,
    );
  }

  /// Elimina una política
  Future<bool> deletePoliticaById(String id) async {
    final result = await _deletePolitica(id);

    if (result is Success<void>) {
      // Remover la política de la lista local
      _allPoliticas.removeWhere((p) => p.id == id);
      _total = _total > 0 ? _total - 1 : 0;

      final currentState = state;
      if (currentState is PoliticaListLoaded) {
        emit(PoliticaListLoaded(
          politicas: _allPoliticas,
          total: _total,
          currentPage: _currentPage,
          limit: _limit,
          tipoDescuentoFiltro: _tipoDescuentoFiltro,
          isActiveFiltro: _isActiveFiltro,
        ));
      }
      return true;
    } else if (result is Error<void>) {
      emit(PoliticaListError(result.message, errorCode: result.errorCode));
      return false;
    }
    return false;
  }

  /// Limpia el estado
  void clear() {
    _currentPage = 1;
    _limit = 20;
    _tipoDescuentoFiltro = null;
    _isActiveFiltro = null;
    _allPoliticas = [];
    _total = 0;
    emit(const PoliticaListInitial());
  }
}
