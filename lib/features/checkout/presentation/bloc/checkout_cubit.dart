import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/usecases/get_opciones_envio_usecase.dart';
import '../../domain/usecases/confirmar_pedido_usecase.dart';
import 'checkout_state.dart';

@injectable
class CheckoutCubit extends Cubit<CheckoutState> {
  final GetOpcionesEnvioUseCase _getOpcionesEnvioUseCase;
  final ConfirmarPedidoUseCase _confirmarPedidoUseCase;

  CheckoutCubit(this._getOpcionesEnvioUseCase, this._confirmarPedidoUseCase)
      : super(const CheckoutInitial());

  final Map<String, OpcionesEnvio> _opcionesPorEmpresa = {};

  Map<String, OpcionesEnvio> get opcionesPorEmpresa => _opcionesPorEmpresa;

  Future<void> loadOpcionesEnvio(List<String> empresaIds) async {
    emit(const CheckoutLoadingEnvio());

    for (final empresaId in empresaIds) {
      final result = await _getOpcionesEnvioUseCase(empresaId: empresaId);
      if (result is Success<OpcionesEnvio>) {
        _opcionesPorEmpresa[empresaId] = result.data;
      } else {
        _opcionesPorEmpresa[empresaId] = const OpcionesEnvio();
      }
    }
    if (isClosed) return;

    emit(CheckoutReady(opcionesPorEmpresa: Map.from(_opcionesPorEmpresa)));
  }

  Future<void> confirmarPedido({
    required String metodoPago,
    String? direccionEnvioId,
    String? notasComprador,
    required List<Map<String, dynamic>> entregaPorEmpresa,
  }) async {
    emit(CheckoutConfirmando(opcionesPorEmpresa: Map.from(_opcionesPorEmpresa)));

    final result = await _confirmarPedidoUseCase(
      metodoPago: metodoPago,
      direccionEnvioId: direccionEnvioId,
      notasComprador: notasComprador,
      entregaPorEmpresa: entregaPorEmpresa,
    );
    if (isClosed) return;

    if (result is Success<CheckoutResult>) {
      emit(CheckoutExito(codigos: result.data.codigos));
    } else if (result is Error<CheckoutResult>) {
      emit(CheckoutError(result.message, opcionesPorEmpresa: Map.from(_opcionesPorEmpresa)));
    }
  }
}
