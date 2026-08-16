import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/services/balanzas_manager.dart';
import 'balanzas_list_state.dart';

@injectable
class BalanzasListCubit extends Cubit<BalanzasListState> {
  final BalanzasManager _manager;
  BalanzasListCubit(this._manager) : super(const BalanzasListInitial());

  Future<void> cargar() async {
    emit(const BalanzasListLoading());
    try {
      final lista = await _manager.listar();
      if (isClosed) return;
      emit(BalanzasListLoaded(lista));
    } catch (e) {
      if (isClosed) return;
      emit(BalanzasListError('No se pudo cargar la lista: $e'));
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
