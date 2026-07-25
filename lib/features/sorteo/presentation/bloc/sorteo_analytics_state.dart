import 'package:equatable/equatable.dart';

abstract class SorteoAnalyticsState extends Equatable {
  const SorteoAnalyticsState();
  @override
  List<Object?> get props => [];
}

class SorteoAnalyticsInitial extends SorteoAnalyticsState {
  const SorteoAnalyticsInitial();
}

class SorteoAnalyticsLoading extends SorteoAnalyticsState {
  const SorteoAnalyticsLoading();
}

class SorteoAnalyticsLoaded extends SorteoAnalyticsState {
  /// Respuesta completa de /sorteos/analytics/dashboard:
  /// { resumen, porTipo, porCanal, topSorteos, topJugadores,
  ///   premiosPorEstado, premiosPorModalidad, zonasPremios, serieDiaria }
  final Map<String, dynamic> data;

  /// Recarga manteniendo los datos visibles (sin flash de spinner).
  final bool refreshing;

  const SorteoAnalyticsLoaded({required this.data, this.refreshing = false});

  SorteoAnalyticsLoaded copyWith({bool? refreshing}) =>
      SorteoAnalyticsLoaded(data: data, refreshing: refreshing ?? this.refreshing);

  @override
  List<Object?> get props => [data, refreshing];
}

class SorteoAnalyticsError extends SorteoAnalyticsState {
  final String message;
  const SorteoAnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}
