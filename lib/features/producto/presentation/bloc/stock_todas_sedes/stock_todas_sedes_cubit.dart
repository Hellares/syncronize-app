import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/producto_stock_model.dart';
import '../../../domain/usecases/get_stock_todas_sedes_usecase.dart';
import 'stock_todas_sedes_state.dart';

@injectable
class StockTodasSedesCubit extends Cubit<StockTodasSedesState> {
  final GetStockTodasSedesUseCase _getStockTodasSedesUseCase;

  StockTodasSedesCubit(
    this._getStockTodasSedesUseCase,
  ) : super(const StockTodasSedesInitial());

  /// Carga el stock de un producto en todas las sedes
  Future<void> loadStockTodasSedes({
    required String productoId,
    required String empresaId,
    String? varianteId,
  }) async {
    emit(const StockTodasSedesLoading());

    final result = await _getStockTodasSedesUseCase(
      productoId: productoId,
      empresaId: empresaId,
      varianteId: varianteId,
    );

    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;

      // Parse stocks con validación de tipos
      final stocksRaw = data['stocks'];
      final stocks = stocksRaw is List
          ? stocksRaw
              .whereType<Map<String, dynamic>>()
              .map((e) => ProductoStockModel.fromJson(e))
              .toList()
          : <ProductoStockModel>[];

      // Parse resumen con null-safety
      final resumen = data['resumen'] is Map<String, dynamic>
          ? data['resumen'] as Map<String, dynamic>
          : <String, dynamic>{};

      emit(StockTodasSedesLoaded(
        stocks: stocks,
        totalSedes: (resumen['totalSedes'] as int?) ?? 0,
        stockTotal: (resumen['stockTotal'] as int?) ?? 0,
        sedesConStock: (resumen['sedesConStock'] as int?) ?? 0,
        sedesSinStock: (resumen['sedesSinStock'] as int?) ?? 0,
        productoId: productoId,
        varianteId: varianteId,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(StockTodasSedesError(result.message, errorCode: result.errorCode));
    }
  }

  /// Recarga los datos
  Future<void> reload() async {
    final currentState = state;
    if (currentState is StockTodasSedesLoaded) {
      await loadStockTodasSedes(
        productoId: currentState.productoId,
        empresaId: '', // Se necesitará pasar desde el widget
        varianteId: currentState.varianteId,
      );
    }
  }

  /// Limpia el estado
  void clear() {
    emit(const StockTodasSedesInitial());
  }
}
