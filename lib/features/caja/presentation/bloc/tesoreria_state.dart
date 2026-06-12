import 'package:equatable/equatable.dart';
import '../../domain/entities/tesoreria.dart';

abstract class TesoreriaState extends Equatable {
  const TesoreriaState();

  @override
  List<Object?> get props => [];
}

class TesoreriaInitial extends TesoreriaState {
  const TesoreriaInitial();
}

class TesoreriaLoading extends TesoreriaState {
  const TesoreriaLoading();
}

class TesoreriaLoaded extends TesoreriaState {
  final TesoreriaResumen resumen;
  final TesoreriaMovimientosPage movimientos;
  final TesoreriaMovimientosFilter filter;

  /// True mientras refrescamos movimientos sin perder el resumen visible.
  final bool refreshingMovimientos;

  /// True mientras cargamos la siguiente página (scroll infinito).
  final bool loadingMore;

  /// Error transitorio de filtros/paginación: la data anterior se conserva
  /// pero la UI debe avisar (snackbar) en vez de fallar en silencio.
  final String? errorMessage;

  const TesoreriaLoaded({
    required this.resumen,
    required this.movimientos,
    required this.filter,
    this.refreshingMovimientos = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => movimientos.items.length < movimientos.total;

  TesoreriaLoaded copyWith({
    TesoreriaResumen? resumen,
    TesoreriaMovimientosPage? movimientos,
    TesoreriaMovimientosFilter? filter,
    bool? refreshingMovimientos,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TesoreriaLoaded(
      resumen: resumen ?? this.resumen,
      movimientos: movimientos ?? this.movimientos,
      filter: filter ?? this.filter,
      refreshingMovimientos:
          refreshingMovimientos ?? this.refreshingMovimientos,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        resumen,
        movimientos,
        filter,
        refreshingMovimientos,
        loadingMore,
        errorMessage,
      ];
}

class TesoreriaError extends TesoreriaState {
  final String message;

  const TesoreriaError(this.message);

  @override
  List<Object?> get props => [message];
}
