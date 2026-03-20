import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/pedido_empresa_remote_datasource.dart';

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
  final Map<String, dynamic> pedido;
  PedidoEmpresaDetailLoaded(this.pedido);
}

// Cubit
@injectable
class PedidoEmpresaActionCubit extends Cubit<PedidoEmpresaActionState> {
  final PedidoEmpresaRemoteDataSource _dataSource;

  PedidoEmpresaActionCubit(this._dataSource) : super(PedidoEmpresaActionInitial());

  Future<void> loadDetalle(String pedidoId) async {
    emit(PedidoEmpresaActionLoading());
    try {
      final pedido = await _dataSource.detallePedido(pedidoId);
      emit(PedidoEmpresaDetailLoaded(pedido));
    } catch (e) {
      emit(PedidoEmpresaActionError(e.toString()));
    }
  }

  Future<void> aprobarPago(String pedidoId) async {
    emit(PedidoEmpresaActionLoading());
    try {
      await _dataSource.validarPago(pedidoId, accion: 'APROBADO');
      emit(PedidoEmpresaActionSuccess('Pago aprobado'));
    } catch (e) {
      emit(PedidoEmpresaActionError(e.toString()));
    }
  }

  Future<void> rechazarPago(String pedidoId, String motivo) async {
    emit(PedidoEmpresaActionLoading());
    try {
      await _dataSource.validarPago(pedidoId, accion: 'RECHAZADO', motivoRechazo: motivo);
      emit(PedidoEmpresaActionSuccess('Pago rechazado'));
    } catch (e) {
      emit(PedidoEmpresaActionError(e.toString()));
    }
  }

  Future<void> cambiarEstado(String pedidoId, String estado, {String? codigoSeguimiento}) async {
    emit(PedidoEmpresaActionLoading());
    try {
      await _dataSource.cambiarEstado(pedidoId, estado: estado, codigoSeguimiento: codigoSeguimiento);
      emit(PedidoEmpresaActionSuccess('Estado actualizado'));
    } catch (e) {
      emit(PedidoEmpresaActionError(e.toString()));
    }
  }
}
