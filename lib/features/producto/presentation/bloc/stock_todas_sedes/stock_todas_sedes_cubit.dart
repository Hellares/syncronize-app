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

      // Parse stocks
      final stocks = (data['stocks'] as List)
          .map((e) => ProductoStockModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Parse resumen
      final resumen = data['resumen'] as Map<String, dynamic>;

      emit(StockTodasSedesLoaded(
        stocks: stocks,
        totalSedes: resumen['totalSedes'] as int,
        stockTotal: resumen['stockTotal'] as int,
        sedesConStock: resumen['sedesConStock'] as int,
        sedesSinStock: resumen['sedesSinStock'] as int,
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
