import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/usecases/subir_comprobante_usecase.dart';
import '../../domain/usecases/cancelar_pedido_usecase.dart';
import '../../domain/usecases/confirmar_recepcion_usecase.dart';

part 'pedido_action_state.dart';

@injectable
class PedidoActionCubit extends Cubit<PedidoActionState> {
  final SubirComprobanteUseCase _subirComprobanteUseCase;
  final CancelarPedidoUseCase _cancelarPedidoUseCase;
  final ConfirmarRecepcionUseCase _confirmarRecepcionUseCase;

  PedidoActionCubit(
    this._subirComprobanteUseCase,
    this._cancelarPedidoUseCase,
    this._confirmarRecepcionUseCase,
  ) : super(const PedidoActionInitial());

  Future<void> subirComprobante({
    required String pedidoId,
    required File file,
  }) async {
    emit(const PedidoActionLoading());

    final result = await _subirComprobanteUseCase(
      pedidoId: pedidoId,
      file: file,
    );
    if (isClosed) return;

    if (result is Success<String>) {
      emit(const PedidoActionSuccess('Comprobante enviado exitosamente'));
    } else if (result is Error<String>) {
      emit(PedidoActionError(result.message));
    }
  }

  Future<void> cancelarPedido(String pedidoId) async {
    emit(const PedidoActionLoading());

    final result = await _cancelarPedidoUseCase(pedidoId);
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const PedidoActionSuccess('Pedido cancelado exitosamente'));
    } else if (result is Error<void>) {
      emit(PedidoActionError(result.message));
    }
  }

  Future<void> confirmarRecepcion(String pedidoId) async {
    emit(const PedidoActionLoading());

    final result = await _confirmarRecepcionUseCase(pedidoId);
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const PedidoActionSuccess('Recepcion confirmada exitosamente'));
    } else if (result is Error<void>) {
      emit(PedidoActionError(result.message));
    }
  }

  void reset() {
    emit(const PedidoActionInitial());
  }
}
