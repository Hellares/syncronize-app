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

  const TesoreriaLoaded({
    required this.resumen,
    required this.movimientos,
    required this.filter,
    this.refreshingMovimientos = false,
  });

  TesoreriaLoaded copyWith({
    TesoreriaResumen? resumen,
    TesoreriaMovimientosPage? movimientos,
    TesoreriaMovimientosFilter? filter,
    bool? refreshingMovimientos,
  }) {
    return TesoreriaLoaded(
      resumen: resumen ?? this.resumen,
      movimientos: movimientos ?? this.movimientos,
      filter: filter ?? this.filter,
      refreshingMovimientos:
          refreshingMovimientos ?? this.refreshingMovimientos,
    );
  }

  @override
  List<Object?> get props => [
        resumen,
        movimientos,
        filter,
        refreshingMovimientos,
      ];
}

class TesoreriaError extends TesoreriaState {
  final String message;

  const TesoreriaError(this.message);

  @override
  List<Object?> get props => [message];
}
