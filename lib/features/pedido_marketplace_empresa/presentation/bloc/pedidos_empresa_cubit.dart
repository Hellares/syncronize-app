import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/pedido_empresa_remote_datasource.dart';

// States
abstract class PedidosEmpresaState {}

class PedidosEmpresaInitial extends PedidosEmpresaState {}

class PedidosEmpresaLoading extends PedidosEmpresaState {}

class PedidosEmpresaLoaded extends PedidosEmpresaState {
  final List<Map<String, dynamic>> pedidos;
  PedidosEmpresaLoaded(this.pedidos);
}

class PedidosEmpresaError extends PedidosEmpresaState {
  final String message;
  PedidosEmpresaError(this.message);
}

// Cubit
@injectable
class PedidosEmpresaCubit extends Cubit<PedidosEmpresaState> {
  final PedidoEmpresaRemoteDataSource _dataSource;
  String? _filtroEstado;

  PedidosEmpresaCubit(this._dataSource) : super(PedidosEmpresaInitial());

  Future<void> loadPedidos({String? estado}) async {
    _filtroEstado = estado;
    emit(PedidosEmpresaLoading());
    try {
      final pedidos = await _dataSource.listarPedidos(estado: estado);
      emit(PedidosEmpresaLoaded(pedidos));
    } catch (e) {
      emit(PedidosEmpresaError(e.toString()));
    }
  }

  Future<void> reload() => loadPedidos(estado: _filtroEstado);
}
