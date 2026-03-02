import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/lote.dart';
import '../../../domain/usecases/get_lotes_usecase.dart';
import '../../../domain/usecases/get_lotes_proximos_vencer_usecase.dart';
import '../../../domain/usecases/marcar_lotes_vencidos_usecase.dart';
import 'lote_list_state.dart';

@injectable
class LoteListCubit extends Cubit<LoteListState> {
  final GetLotesUseCase _getLotesUseCase;
  final GetLotesProximosVencerUseCase _getLotesProximosVencerUseCase;
  final MarcarLotesVencidosUseCase _marcarLotesVencidosUseCase;

  LoteListCubit(
    this._getLotesUseCase,
    this._getLotesProximosVencerUseCase,
    this._marcarLotesVencidosUseCase,
  ) : super(const LoteListInitial());

  String? _currentEmpresaId;
  String? _sedeId;
  String? _productoStockId;
  String? _estadoFilter;
  bool _showProximosVencer = false;

  Future<void> loadLotes({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
  }) async {
    if (empresaId.isEmpty) {
      emit(const LoteListError('ID de empresa no válido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _sedeId = sedeId;
    _productoStockId = productoStockId;
    _estadoFilter = estado;
    _showProximosVencer = false;

    emit(const LoteListLoading());

    final result = await _getLotesUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      productoStockId: productoStockId,
      estado: estado,
    );

    if (result is Success<List<Lote>>) {
      emit(LoteListLoaded(
        lotes: result.data,
        estadoFilter: estado,
      ));
    } else if (result is Error<List<Lote>>) {
      emit(LoteListError(result.message));
    }
  }

  Future<void> loadProximosVencer({
    required String empresaId,
    int dias = 30,
  }) async {
    _currentEmpresaId = empresaId;
    _showProximosVencer = true;

    emit(const LoteListLoading());

    final result = await _getLotesProximosVencerUseCase(
      empresaId: empresaId,
      dias: dias,
    );

    if (result is Success<List<Lote>>) {
      emit(LoteListLoaded(lotes: result.data));
    } else if (result is Error<List<Lote>>) {
      emit(LoteListError(result.message));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    if (_showProximosVencer) {
      await loadProximosVencer(empresaId: _currentEmpresaId!);
    } else {
      await loadLotes(
        empresaId: _currentEmpresaId!,
        sedeId: _sedeId,
        productoStockId: _productoStockId,
        estado: _estadoFilter,
      );
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! LoteListLoaded) return;
    emit(currentState.copyWith(
      searchQuery: query.isEmpty ? null : query,
    ));
  }

  void filterByEstado(String? estado) {
    final currentState = state;
    if (currentState is! LoteListLoaded) return;
    emit(currentState.copyWith(estadoFilter: estado));
  }

  Future<bool> marcarVencidos() async {
    if (_currentEmpresaId == null) return false;
    final result = await _marcarLotesVencidosUseCase(
      empresaId: _currentEmpresaId!,
    );
    if (result is Success) {
      await reload();
      return true;
    }
    return false;
  }
}
