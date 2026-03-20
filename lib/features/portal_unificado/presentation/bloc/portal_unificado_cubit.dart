import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/actividad_unificada.dart';
import '../../domain/usecases/get_actividad_unificada_usecase.dart';

abstract class PortalUnificadoState {}

class PortalUnificadoInitial extends PortalUnificadoState {}

class PortalUnificadoLoading extends PortalUnificadoState {}

class PortalUnificadoLoaded extends PortalUnificadoState {
  final ActividadUnificada actividad;
  PortalUnificadoLoaded(this.actividad);
}

class PortalUnificadoError extends PortalUnificadoState {
  final String message;
  PortalUnificadoError(this.message);
}

class PortalUnificadoCubit extends Cubit<PortalUnificadoState> {
  final GetActividadUnificadaUseCase _getActividadUnificada;

  PortalUnificadoCubit(this._getActividadUnificada) : super(PortalUnificadoInitial());

  Future<void> loadActividad() async {
    emit(PortalUnificadoLoading());

    final result = await _getActividadUnificada();

    if (result is Success<ActividadUnificada>) {
      emit(PortalUnificadoLoaded(result.data));
    } else if (result is Error<ActividadUnificada>) {
      emit(PortalUnificadoError(result.message));
    }
  }
}
