import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:syncronize/core/utils/resource.dart';

import '../../../domain/entities/adelanto.dart';
import '../../../domain/repositories/adelanto_repository.dart';
import 'adelanto_state.dart';

@injectable
class AdelantoCubit extends Cubit<AdelantoState> {
  final AdelantoRepository _repository;

  Map<String, dynamic> _lastParams = {};

  AdelantoCubit(this._repository) : super(const AdelantoInitial());

  Future<void> loadAdelantos({Map<String, dynamic>? queryParams}) async {
    if (queryParams != null) _lastParams = queryParams;
    emit(const AdelantoLoading());

    final result = await _repository.getAll(queryParams: queryParams);
    if (isClosed) return;

    if (result is Success<List<Adelanto>>) {
      emit(AdelantoListLoaded(result.data));
    } else if (result is Error) {
      emit(AdelantoError((result as Error).message));
    }
  }

  Future<void> crearAdelanto(Map<String, dynamic> data) async {
    emit(const AdelantoLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoActionSuccess('Adelanto creado exitosamente'));
    } else if (result is Error) {
      emit(AdelantoError((result as Error).message));
    }
  }

  Future<void> aprobar(String id) async {
    emit(const AdelantoLoading());

    final result = await _repository.aprobar(id);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoActionSuccess('Adelanto aprobado'));
      await loadAdelantos(queryParams: _lastParams);
    } else if (result is Error) {
      emit(AdelantoError((result as Error).message));
    }
  }

  Future<void> rechazar(String id, String motivoRechazo) async {
    emit(const AdelantoLoading());

    final result = await _repository.rechazar(id, motivoRechazo);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoActionSuccess('Adelanto rechazado'));
      await loadAdelantos(queryParams: _lastParams);
    } else if (result is Error) {
      emit(AdelantoError((result as Error).message));
    }
  }

  Future<void> pagar(String id, Map<String, dynamic> data) async {
    emit(const AdelantoLoading());

    final result = await _repository.pagar(id, data);
    if (isClosed) return;

    if (result is Success<Adelanto>) {
      emit(const AdelantoActionSuccess('Adelanto pagado exitosamente'));
      await loadAdelantos(queryParams: _lastParams);
    } else if (result is Error) {
      emit(AdelantoError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadAdelantos(queryParams: _lastParams);
  }
}
