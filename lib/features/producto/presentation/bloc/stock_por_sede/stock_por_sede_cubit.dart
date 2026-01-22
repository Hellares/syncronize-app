import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/producto_stock_model.dart';
import '../../../domain/entities/producto_stock.dart';
import '../../../domain/usecases/get_stock_por_sede_usecase.dart';
import 'stock_por_sede_state.dart';

@injectable
class StockPorSedeCubit extends Cubit<StockPorSedeState> {
  final GetStockPorSedeUseCase _getStockPorSedeUseCase;

  StockPorSedeCubit(
    this._getStockPorSedeUseCase,
  ) : super(const StockPorSedeInitial());

  String? _currentSedeId;
  String? _currentEmpresaId;
  List<ProductoStock> _allStocks = [];
  int _currentPage = 1;

  /// Convierte un valor dinámico a int de forma segura
  int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Carga el stock de una sede
  Future<void> loadStockPorSede({
    required String sedeId,
    required String empresaId,
    int page = 1,
  }) async {
    _currentSedeId = sedeId;
    _currentEmpresaId = empresaId;
    _currentPage = page;

    if (page == 1) {
      _allStocks = [];
      emit(const StockPorSedeLoading());
      
    }

    final result = await _getStockPorSedeUseCase(
      sedeId: sedeId,
      empresaId: empresaId,
      page: page,
      limit: 50,
    );

    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;

      // Soportar tanto estructura con 'data' como sin ella (migración gradual)
      final stocksList = (data['data'] ?? data['stocks']) as List? ?? [];
      final meta = data['meta'] as Map<String, dynamic>?;

      final stocks = stocksList
          .map((e) => ProductoStockModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        _allStocks = stocks;
      } else {
        _allStocks.addAll(stocks);
      }

      // Usar meta si existe, sino usar datos directos (retrocompatibilidad)
      final total = meta != null
          ? _safeToInt(meta['total'])
          : _safeToInt(data['total']);
      final currentPage = meta != null
          ? _safeToInt(meta['page'], defaultValue: page)
          : _safeToInt(data['page'], defaultValue: page);
      final totalPages = meta != null
          ? _safeToInt(meta['totalPages'], defaultValue: 1)
          : _safeToInt(data['totalPages'], defaultValue: 1);
      final hasMore = meta != null
          ? (meta['hasNext'] as bool? ?? false)
          : (data['hasNext'] as bool? ?? false);

      emit(StockPorSedeLoaded(
        stocks: _allStocks,
        total: total,
        currentPage: currentPage,
        totalPages: totalPages,
        hasMore: hasMore,
        sedeId: sedeId,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(StockPorSedeError(result.message, errorCode: result.errorCode));
    }
  }

  /// Carga más stock (paginación)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! StockPorSedeLoaded) return;
    if (!currentState.hasMore) return;
    if (_currentSedeId == null || _currentEmpresaId == null) return;

    emit(StockPorSedeLoadingMore(_allStocks));

    await loadStockPorSede(
      sedeId: _currentSedeId!,
      empresaId: _currentEmpresaId!,
      page: _currentPage + 1,
    );
  }

  /// Recarga la lista actual
  Future<void> reload() async {
    if (_currentSedeId == null || _currentEmpresaId == null) return;
    await loadStockPorSede(
      sedeId: _currentSedeId!,
      empresaId: _currentEmpresaId!,
      page: 1,
    );
  }

  /// Limpia el estado
  void clear() {
    _currentSedeId = null;
    _currentEmpresaId = null;
    _allStocks = [];
    _currentPage = 1;
    emit(const StockPorSedeInitial());
  }
}
