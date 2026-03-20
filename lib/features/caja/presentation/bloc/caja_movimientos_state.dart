import 'package:equatable/equatable.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';

abstract class CajaMovimientosState extends Equatable {
  const CajaMovimientosState();

  @override
  List<Object?> get props => [];
}

class CajaMovimientosInitial extends CajaMovimientosState {
  const CajaMovimientosInitial();
}

class CajaMovimientosLoading extends CajaMovimientosState {
  const CajaMovimientosLoading();
}

class CajaMovimientosLoaded extends CajaMovimientosState {
  final List<MovimientoCaja> movimientos;
  final ResumenCaja? resumen;

  const CajaMovimientosLoaded({
    required this.movimientos,
    this.resumen,
  });

  @override
  List<Object?> get props => [movimientos, resumen];
}

class CajaMovimientosError extends CajaMovimientosState {
  final String message;

  const CajaMovimientosError(this.message);

  @override
  List<Object?> get props => [message];
}
