import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/adelanto.dart';
import '../../../domain/repositories/adelanto_repository.dart';
import 'adelanto_list_state.dart';

@injectable
class AdelantoListCubit extends Cubit<AdelantoListState> {
  final AdelantoRepository _repository;

  Map<String, dynamic> _lastFilters = {};

  AdelantoListCubit(this._repository) : super(const AdelantoListInitial());

  Future<void> loadAdelantos({Map<String, dynamic>? filters}) async {
    if (filters != null) {
      _lastFilters = filters;
    }

    emit(const AdelantoListLoading());

    final result = await _repository.getAll(queryParams: _lastFilters);
    if (isClosed) return;

    if (result is Success<List<Adelanto>>) {
      emit(AdelantoListLoaded(result.data));
    } else if (result is Error) {
      emit(AdelantoListError((result as Error).message));
    }
  }

  Future<void> crearAdelanto(Map<String, dynamic> data) async {
    emit(const AdelantoListLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoListActionSuccess('Adelanto creado exitosamente'));
      await loadAdelantos();
    } else if (result is Error) {
      emit(AdelantoListError((result as Error).message));
    }
  }

  Future<void> aprobar(String id) async {
    emit(const AdelantoListLoading());

    final result = await _repository.aprobar(id);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoListActionSuccess('Adelanto aprobado exitosamente'));
      await loadAdelantos();
    } else if (result is Error) {
      emit(AdelantoListError((result as Error).message));
    }
  }

  Future<void> rechazar(String id, String motivo) async {
    emit(const AdelantoListLoading());

    final result = await _repository.rechazar(id, motivo);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoListActionSuccess('Adelanto rechazado exitosamente'));
      await loadAdelantos();
    } else if (result is Error) {
      emit(AdelantoListError((result as Error).message));
    }
  }

  Future<void> pagar(String id, String metodoPago) async {
    emit(const AdelantoListLoading());

    final result = await _repository.pagar(id, {'metodoPago': metodoPago});
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoListActionSuccess('Adelanto pagado exitosamente'));
      await loadAdelantos();
    } else if (result is Error) {
      emit(AdelantoListError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadAdelantos();
  }
}
