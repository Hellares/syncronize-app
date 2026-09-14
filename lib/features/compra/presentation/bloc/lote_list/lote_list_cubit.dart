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

  /// Lotes por pedido. La tabla muestra muchos a la vez; el resto llega con
  /// "Cargar más".
  static const int pageSize = 50;

  String? _empresaId;
  String? _sedeId;
  String? _productoStockId;
  String? _estado;
  String? _search;
  bool _proximosVencer = false;
  String? _nextCursor;

  /// Descarta respuestas viejas: si se cambia el filtro con una carga en
  /// vuelo, la que llega tarde no pisa la nueva.
  int _pedido = 0;

  Future<void> loadLotes({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
    String? search,
  }) async {
    if (empresaId.isEmpty) {
      emit(const LoteListError('ID de empresa no válido'));
      return;
    }
    _empresaId = empresaId;
    _sedeId = sedeId;
    _productoStockId = productoStockId;
    _estado = estado;
    _search = search;
    _proximosVencer = false;
    await _cargarPrimeraPagina();
  }

  Future<void> _cargarPrimeraPagina() async {
    final pedido = ++_pedido;
    _nextCursor = null;
    emit(const LoteListLoading());

    final result = await _getLotesUseCase(
      empresaId: _empresaId!,
      sedeId: _sedeId,
      productoStockId: _productoStockId,
      estado: _estado,
      search: _search,
      limit: pageSize,
    );
    if (isClosed || pedido != _pedido) return;

    if (result is Success<LotesPagina>) {
      _nextCursor = result.data.nextCursor;
      emit(LoteListLoaded(
        lotes: result.data.lotes,
        total: result.data.total,
        hasNext: result.data.hasNext,
        searchQuery: _search,
        estadoFilter: _estado,
      ));
    } else if (result is Error<LotesPagina>) {
      emit(LoteListError(result.message));
    }
  }

  /// La página siguiente, con el mismo filtro.
  Future<void> loadMore() async {
    final actual = state;
    if (actual is! LoteListLoaded ||
        !actual.hasNext ||
        actual.cargandoMas ||
        actual.proximosVencer ||
        _nextCursor == null) {
      return;
    }
    final pedido = _pedido;
    emit(actual.copyWith(cargandoMas: true));

    final result = await _getLotesUseCase(
      empresaId: _empresaId!,
      sedeId: _sedeId,
      productoStockId: _productoStockId,
      estado: _estado,
      search: _search,
      limit: pageSize,
      cursor: _nextCursor,
    );
    if (isClosed || pedido != _pedido) return;

    if (result is Success<LotesPagina>) {
      final nuevos = result.data.lotes;
      _nextCursor = result.data.nextCursor;
      emit(actual.copyWith(
        lotes: [...actual.lotes, ...nuevos],
        total: result.data.total,
        // El backend marca `hasNext` cuando la página vino LLENA: si la
        // siguiente vino vacía, ya no había más.
        hasNext: result.data.hasNext && nuevos.isNotEmpty,
        cargandoMas: false,
      ));
    } else {
      // Se queda con lo cargado y el botón vuelve a estar disponible.
      emit(actual.copyWith(cargandoMas: false));
    }
  }

  Future<void> loadProximosVencer({
    required String empresaId,
    int dias = 30,
  }) async {
    _empresaId = empresaId;
    _proximosVencer = true;
    final pedido = ++_pedido;
    _nextCursor = null;
    emit(const LoteListLoading());

    final result = await _getLotesProximosVencerUseCase(
      empresaId: empresaId,
      dias: dias,
    );
    if (isClosed || pedido != _pedido) return;

    if (result is Success<List<Lote>>) {
      emit(LoteListLoaded(
        lotes: result.data,
        total: result.data.length,
        proximosVencer: true,
      ));
    } else if (result is Error<List<Lote>>) {
      emit(LoteListError(result.message));
    }
  }

  Future<void> reload() async {
    if (_empresaId == null) return;
    if (_proximosVencer) {
      await loadProximosVencer(empresaId: _empresaId!);
    } else {
      await _cargarPrimeraPagina();
    }
  }

  /// La búsqueda va al BACKEND (código, número de lote, proveedor o nombre del
  /// producto). Vacía = sin búsqueda.
  Future<void> search(String query) async {
    if (_empresaId == null) return;
    final q = query.trim();
    final nueva = q.isEmpty ? null : q;
    if (nueva == _search && !_proximosVencer) return;
    _search = nueva;
    _proximosVencer = false;
    await _cargarPrimeraPagina();
  }

  /// null = todos los estados. También sale de "Próximos a vencer".
  Future<void> filterByEstado(String? estado) async {
    if (_empresaId == null) return;
    _estado = estado;
    _proximosVencer = false;
    await _cargarPrimeraPagina();
  }

  Future<bool> marcarVencidos() async {
    if (_empresaId == null) return false;
    final result = await _marcarLotesVencidosUseCase(
      empresaId: _empresaId!,
    );
    if (result is Success) {
      await reload();
      return true;
    }
    return false;
  }
}
