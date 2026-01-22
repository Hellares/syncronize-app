import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/transferencia_stock.dart';
import '../../../domain/usecases/crear_transferencia_usecase.dart';
import 'crear_transferencia_state.dart';

@injectable
class CrearTransferenciaCubit extends Cubit<CrearTransferenciaState> {
  final CrearTransferenciaUseCase _crearTransferenciaUseCase;

  CrearTransferenciaCubit(
    this._crearTransferenciaUseCase,
  ) : super(const CrearTransferenciaInitial());

  /// Crear transferencia
  Future<void> crear({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    String? productoId,
    String? varianteId,
    required int cantidad,
    String? motivo,
    String? observaciones,
  }) async {
    emit(const CrearTransferenciaProcessing());

    final result = await _crearTransferenciaUseCase(
      empresaId: empresaId,
      sedeOrigenId: sedeOrigenId,
      sedeDestinoId: sedeDestinoId,
      productoId: productoId,
      varianteId: varianteId,
      cantidad: cantidad,
      motivo: motivo,
      observaciones: observaciones,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(CrearTransferenciaSuccess(
        result.data,
        'Transferencia creada correctamente',
      ));
    } else if (result is Error<TransferenciaStock>) {
      emit(CrearTransferenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Resetea el estado
  void reset() {
    emit(const CrearTransferenciaInitial());
  }
}
