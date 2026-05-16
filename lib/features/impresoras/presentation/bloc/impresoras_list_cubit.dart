import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/services/impresoras_manager.dart';
import 'impresoras_list_state.dart';

@injectable
class ImpresorasListCubit extends Cubit<ImpresorasListState> {
  final ImpresorasManager _manager;
  ImpresorasListCubit(this._manager) : super(const ImpresorasListInitial());

  Future<void> cargar() async {
    emit(const ImpresorasListLoading());
    try {
      final lista = await _manager.listar();
      if (isClosed) return;
      emit(ImpresorasListLoaded(lista));
    } catch (e) {
      if (isClosed) return;
      emit(ImpresorasListError('No se pudo cargar la lista: $e'));
    }
  }

  Future<void> marcarPrincipal(String id) async {
    await _manager.marcarPrincipal(id);
    await cargar();
  }

  Future<void> eliminar(String id) async {
    await _manager.eliminar(id);
    await cargar();
  }
}
