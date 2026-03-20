import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pedido_marketplace.dart';
import '../../domain/usecases/get_mis_pedidos_usecase.dart';

part 'mis_pedidos_state.dart';

@injectable
class MisPedidosCubit extends Cubit<MisPedidosState> {
  final GetMisPedidosUseCase _getMisPedidosUseCase;

  MisPedidosCubit(this._getMisPedidosUseCase) : super(const MisPedidosInitial());

  EstadoPedidoMarketplace? _filtroEstado;

  Future<void> loadPedidos({EstadoPedidoMarketplace? estado}) async {
    _filtroEstado = estado;
    emit(const MisPedidosLoading());

    final result = await _getMisPedidosUseCase(estado: estado);
    if (isClosed) return;

    if (result is Success<List<PedidoMarketplace>>) {
      emit(MisPedidosLoaded(
        pedidos: result.data,
        filtroEstado: estado,
      ));
    } else if (result is Error<List<PedidoMarketplace>>) {
      emit(MisPedidosError(result.message));
    }
  }

  Future<void> reload() async {
    await loadPedidos(estado: _filtroEstado);
  }

  Future<void> filterByEstado(EstadoPedidoMarketplace? estado) async {
    await loadPedidos(estado: estado);
  }
}
