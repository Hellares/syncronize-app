import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';

// States
abstract class GuiaRemisionDetailState {}

class GuiaRemisionDetailInitial extends GuiaRemisionDetailState {}

class GuiaRemisionDetailLoading extends GuiaRemisionDetailState {}

class GuiaRemisionDetailLoaded extends GuiaRemisionDetailState {
  final GuiaRemision guia;
  GuiaRemisionDetailLoaded(this.guia);
}

class GuiaRemisionDetailError extends GuiaRemisionDetailState {
  final String message;
  GuiaRemisionDetailError(this.message);
}

class GuiaRemisionDetailCubit extends Cubit<GuiaRemisionDetailState> {
  final GuiaRemisionRepository _repository;

  GuiaRemisionDetailCubit(this._repository) : super(GuiaRemisionDetailInitial());

  Future<void> cargar(String guiaId) async {
    emit(GuiaRemisionDetailLoading());
    final result = await _repository.obtener(guiaId);
    if (result is Success) {
      emit(GuiaRemisionDetailLoaded((result as Success).data));
    } else {
      emit(GuiaRemisionDetailError((result as Error).message));
    }
  }

  Future<void> enviar(String guiaId) async {
    final result = await _repository.enviar(guiaId);
    if (result is Success) {
      cargar(guiaId);
    } else {
      emit(GuiaRemisionDetailError((result as Error).message));
    }
  }

  Future<void> consultar(String guiaId) async {
    final result = await _repository.consultar(guiaId);
    if (result is Success) {
      cargar(guiaId);
    } else {
      emit(GuiaRemisionDetailError((result as Error).message));
    }
  }
}
