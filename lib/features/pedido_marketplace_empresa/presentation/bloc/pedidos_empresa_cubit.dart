import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/pedido_empresa.dart';
import '../../domain/usecases/get_pedidos_empresa_usecase.dart';

// States
abstract class PedidosEmpresaState {}

class PedidosEmpresaInitial extends PedidosEmpresaState {}

class PedidosEmpresaLoading extends PedidosEmpresaState {}

class PedidosEmpresaLoaded extends PedidosEmpresaState {
  final List<PedidoMarketplaceEmpresa> pedidos;
  PedidosEmpresaLoaded(this.pedidos);
}

class PedidosEmpresaError extends PedidosEmpresaState {
  final String message;
  PedidosEmpresaError(this.message);
}

// Cubit
@injectable
class PedidosEmpresaCubit extends Cubit<PedidosEmpresaState> {
  final GetPedidosEmpresaUseCase _getPedidosUseCase;
  String? _filtroEstado;

  PedidosEmpresaCubit(this._getPedidosUseCase) : super(PedidosEmpresaInitial());

  Future<void> loadPedidos({String? estado}) async {
    _filtroEstado = estado;
    emit(PedidosEmpresaLoading());
    final result = await _getPedidosUseCase(estado: estado);
    if (isClosed) return;
    if (result is Success<List<PedidoMarketplaceEmpresa>>) {
      emit(PedidosEmpresaLoaded(result.data));
    } else if (result is Error<List<PedidoMarketplaceEmpresa>>) {
      emit(PedidosEmpresaError(result.message));
    }
  }

  Future<void> reload() => loadPedidos(estado: _filtroEstado);
}
