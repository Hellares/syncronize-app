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

/// Dashboard consolidado (shape crudo del backend):
/// { resumen, porEstado, porTipo, porPrioridad, porMes, topTecnicos,
///   topEquipos }
class ServicioDashboardDataLoaded extends ServicioDashboardState {
  final Map<String, dynamic> data;

  /// Recarga manteniendo los datos visibles (sin flash de spinner).
  final bool refreshing;

  const ServicioDashboardDataLoaded({
    required this.data,
    this.refreshing = false,
  });

  ServicioDashboardDataLoaded copyWith({bool? refreshing}) =>
      ServicioDashboardDataLoaded(
          data: data, refreshing: refreshing ?? this.refreshing);

  @override
  List<Object?> get props => [data, refreshing];
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

  /// Dashboard consolidado en UN request, con recarga sin blanqueo (los
  /// datos quedan visibles y se intercambian al llegar los nuevos).
  Future<void> loadDashboard({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final current = state;
    if (current is ServicioDashboardDataLoaded) {
      emit(current.copyWith(refreshing: true));
    } else {
      emit(const ServicioDashboardLoading());
    }

    final result = await _repository.getDashboard(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      emit(ServicioDashboardDataLoaded(data: result.data));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(ServicioDashboardError(result.message));
    }
  }
}
