import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/estadisticas_servicio.dart';
import '../../../domain/repositories/estadisticas_servicio_repository.dart';

// States
abstract class ServicioDashboardState extends Equatable {
  const ServicioDashboardState();
}

class ServicioDashboardInitial extends ServicioDashboardState {
  const ServicioDashboardInitial();
  @override
  List<Object?> get props => [];
}

class ServicioDashboardLoading extends ServicioDashboardState {
  const ServicioDashboardLoading();
  @override
  List<Object?> get props => [];
}

class ServicioDashboardLoaded extends ServicioDashboardState {
  final EstadisticasServicio estadisticas;
  const ServicioDashboardLoaded(this.estadisticas);
  @override
  List<Object?> get props => [estadisticas];
}

class ServicioDashboardError extends ServicioDashboardState {
  final String message;
  const ServicioDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
@injectable
class ServicioDashboardCubit extends Cubit<ServicioDashboardState> {
  final EstadisticasServicioRepository _repository;

  ServicioDashboardCubit(this._repository)
      : super(const ServicioDashboardInitial());

  Future<void> loadEstadisticas({
    required String empresaId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    emit(const ServicioDashboardLoading());

    final result = await _repository.getEstadisticas(
      empresaId: empresaId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );

    if (isClosed) return;

    if (result is Success<EstadisticasServicio>) {
      emit(ServicioDashboardLoaded(result.data));
    } else if (result is Error<EstadisticasServicio>) {
      emit(ServicioDashboardError(result.message));
    }
  }
}
