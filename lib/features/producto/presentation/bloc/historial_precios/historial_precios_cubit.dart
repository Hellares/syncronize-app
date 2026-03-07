import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/cursor_page.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../empresa/domain/entities/sede.dart';
import '../../../../sede/domain/usecases/get_sedes_usecase.dart';
import '../../../domain/entities/precio_historial_sede.dart';
import '../../../domain/usecases/get_historial_precios_global_usecase.dart';
import 'historial_precios_state.dart';

@injectable
class HistorialPreciosCubit extends Cubit<HistorialPreciosState> {
  final GetHistorialPreciosGlobalUseCase _getHistorialUseCase;
  final ExportHistorialPreciosUseCase _exportUseCase;
  final GetSedesUseCase _getSedesUseCase;

  String _empresaId = '';
  String? _sedeId;
  String? _productoId;
  String? _fechaInicio;
  String? _fechaFin;
  String? _tipoCambio;
  String? _search;
  String? _nextCursor;
  bool _hasNext = false;
  static const int _limit = 50;
  List<Sede> _sedes = [];
  bool _isLoadingMore = false;

  HistorialPreciosCubit(
    this._getHistorialUseCase,
    this._exportUseCase,
    this._getSedesUseCase,
  ) : super(HistorialPreciosInitial());

  Future<void> load({
    required String empresaId,
    String? sedeId,
    String? productoId,
    String? fechaInicio,
    String? fechaFin,
    String? tipoCambio,
    String? search,
  }) async {
    _empresaId = empresaId;
    _sedeId = sedeId;
    _productoId = productoId;
    _fechaInicio = fechaInicio;
    _fechaFin = fechaFin;
    _tipoCambio = tipoCambio;
    _search = search;
    _nextCursor = null;
    _hasNext = false;

    emit(HistorialPreciosLoading());

    // Cargar sedes solo la primera vez
    if (_sedes.isEmpty) {
      final sedesResult = await _getSedesUseCase(_empresaId);
      if (sedesResult is Success<List<Sede>>) {
        _sedes = sedesResult.data;
      }
    }

    await _fetch();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext || _nextCursor == null) return;
    final currentState = state;
    if (currentState is! HistorialPreciosLoaded) return;

    _isLoadingMore = true;

    final result = await _getHistorialUseCase(
      empresaId: _empresaId,
      sedeId: _sedeId,
      productoId: _productoId,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      tipoCambio: _tipoCambio,
      search: _search,
      cursor: _nextCursor,
      limit: _limit,
    );

    if (result is Success<CursorPage<PrecioHistorialSede>>) {
      final page = result.data;
      _nextCursor = page.nextCursor;
      _hasNext = page.hasNext;
      emit(HistorialPreciosLoaded(
        items: [...currentState.items, ...page.items],
        sedes: _sedes,
        hasMore: page.hasNext,
      ));
    }

    _isLoadingMore = false;
  }

  Future<void> reload() async {
    _nextCursor = null;
    _hasNext = false;
    emit(HistorialPreciosLoading());
    await _fetch();
  }

  Future<Resource<List<int>>> exportExcel({
    required String fechaInicio,
    required String fechaFin,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _exportUseCase(
      empresaId: _empresaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      sedeId: _sedeId,
      productoId: _productoId,
      tipoCambio: _tipoCambio,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<void> _fetch() async {
    final result = await _getHistorialUseCase(
      empresaId: _empresaId,
      sedeId: _sedeId,
      productoId: _productoId,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      tipoCambio: _tipoCambio,
      search: _search,
      cursor: null,
      limit: _limit,
    );

    if (result is Success<CursorPage<PrecioHistorialSede>>) {
      final page = result.data;
      _nextCursor = page.nextCursor;
      _hasNext = page.hasNext;
      emit(HistorialPreciosLoaded(
        items: page.items,
        sedes: _sedes,
        hasMore: page.hasNext,
      ));
    } else if (result is Error<CursorPage<PrecioHistorialSede>>) {
      emit(HistorialPreciosError(result.message));
    }
  }
}
