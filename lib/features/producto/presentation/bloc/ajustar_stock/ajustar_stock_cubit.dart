import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/movimiento_stock.dart';
import '../../../domain/usecases/ajustar_stock_usecase.dart';
import 'ajustar_stock_state.dart';

@injectable
class AjustarStockCubit extends Cubit<AjustarStockState> {
  final AjustarStockUseCase _ajustarStockUseCase;

  AjustarStockCubit(
    this._ajustarStockUseCase,
  ) : super(const AjustarStockInitial());

  /// Ajusta el stock (entrada o salida)
  Future<void> ajustarStock({
    required String stockId,
    required String empresaId,
    required TipoMovimientoStock tipo,
    required int cantidad,
    String? motivo,
    String? observaciones,
    String? tipoDocumento,
    String? numeroDocumento,
  }) async {
    emit(const AjustarStockProcessing());

    final result = await _ajustarStockUseCase(
      stockId: stockId,
      empresaId: empresaId,
      tipo: tipo,
      cantidad: cantidad,
      motivo: motivo,
      observaciones: observaciones,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
    );

    if (isClosed) return;

    if (result is Success) {
      final successResult = result as Success;
      emit(AjustarStockSuccess(
        stockActualizado: successResult.data,
        message: tipo.esEntrada
            ? 'Stock incrementado correctamente'
            : 'Stock reducido correctamente',
      ));
    } else if (result is Error) {
      final errorResult = result as Error;
      emit(AjustarStockError(errorResult.message, errorCode: errorResult.errorCode));
    }
  }

  /// Resetea al estado inicial
  void reset() {
    emit(const AjustarStockInitial());
  }
}
