import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pedido_empresa.dart';
import '../../domain/usecases/get_detalle_pedido_empresa_usecase.dart';
import '../../domain/usecases/validar_pago_usecase.dart';
import '../../domain/usecases/cambiar_estado_pedido_usecase.dart';

// States
abstract class PedidoEmpresaActionState {}

class PedidoEmpresaActionInitial extends PedidoEmpresaActionState {}

class PedidoEmpresaActionLoading extends PedidoEmpresaActionState {}

class PedidoEmpresaActionSuccess extends PedidoEmpresaActionState {
  final String message;
  PedidoEmpresaActionSuccess(this.message);
}

class PedidoEmpresaActionError extends PedidoEmpresaActionState {
  final String message;
  PedidoEmpresaActionError(this.message);
}

// Detail state
class PedidoEmpresaDetailLoaded extends PedidoEmpresaActionState {
  final PedidoMarketplaceEmpresa pedido;
  PedidoEmpresaDetailLoaded(this.pedido);
}

// Cubit
@injectable
class PedidoEmpresaActionCubit extends Cubit<PedidoEmpresaActionState> {
  final GetDetallePedidoEmpresaUseCase _getDetalleUseCase;
  final ValidarPagoUseCase _validarPagoUseCase;
  final CambiarEstadoPedidoUseCase _cambiarEstadoUseCase;

  PedidoEmpresaActionCubit(
    this._getDetalleUseCase,
    this._validarPagoUseCase,
    this._cambiarEstadoUseCase,
  ) : super(PedidoEmpresaActionInitial());

  Future<void> loadDetalle(String pedidoId) async {
    emit(PedidoEmpresaActionLoading());
    final result = await _getDetalleUseCase(pedidoId);
    if (isClosed) return;
    if (result is Success<PedidoMarketplaceEmpresa>) {
      emit(PedidoEmpresaDetailLoaded(result.data));
    } else if (result is Error<PedidoMarketplaceEmpresa>) {
      emit(PedidoEmpresaActionError(result.message));
    }
  }

  Future<void> aprobarPago(String pedidoId) async {
    emit(PedidoEmpresaActionLoading());
    final result = await _validarPagoUseCase(pedidoId, accion: 'APROBADO');
    if (isClosed) return;
    if (result is Success) {
      emit(PedidoEmpresaActionSuccess('Pago aprobado'));
    } else if (result is Error) {
      emit(PedidoEmpresaActionError((result).message));
    }
  }

  Future<void> rechazarPago(String pedidoId, String motivo) async {
    emit(PedidoEmpresaActionLoading());
    final result = await _validarPagoUseCase(
      pedidoId,
      accion: 'RECHAZADO',
      motivoRechazo: motivo,
    );
    if (isClosed) return;
    if (result is Success) {
      emit(PedidoEmpresaActionSuccess('Pago rechazado'));
    } else if (result is Error) {
      emit(PedidoEmpresaActionError((result).message));
    }
  }

  Future<void> cambiarEstado(String pedidoId, String estado, {String? codigoSeguimiento}) async {
    emit(PedidoEmpresaActionLoading());
    final result = await _cambiarEstadoUseCase(
      pedidoId,
      estado: estado,
      codigoSeguimiento: codigoSeguimiento,
    );
    if (isClosed) return;
    if (result is Success) {
      emit(PedidoEmpresaActionSuccess('Estado actualizado'));
    } else if (result is Error) {
      emit(PedidoEmpresaActionError((result).message));
    }
  }
}
