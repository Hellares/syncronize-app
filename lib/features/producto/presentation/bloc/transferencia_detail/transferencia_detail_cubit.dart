import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/transferencia_stock.dart';
import '../../../domain/usecases/gestionar_transferencia_usecase.dart';
import 'transferencia_detail_state.dart';

@injectable
class TransferenciaDetailCubit extends Cubit<TransferenciaDetailState> {
  final ObtenerTransferenciaUseCase _obtenerUseCase;

  TransferenciaDetailCubit(
    this._obtenerUseCase,
  ) : super(const TransferenciaDetailInitial());

  /// Carga el detalle de una transferencia
  Future<void> loadDetalle({
    required String transferenciaId,
    required String empresaId,
  }) async {
    emit(const TransferenciaDetailLoading());

    final result = await _obtenerUseCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(TransferenciaDetailLoaded(result.data));
    } else if (result is Error<TransferenciaStock>) {
      emit(TransferenciaDetailError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Recarga el detalle actual
  Future<void> reload({
    required String transferenciaId,
    required String empresaId,
  }) async {
    await loadDetalle(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
    );
  }
}
