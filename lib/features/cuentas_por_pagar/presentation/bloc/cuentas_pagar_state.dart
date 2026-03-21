import 'package:equatable/equatable.dart';
import '../../domain/entities/cuenta_por_pagar.dart';

abstract class CuentasPagarState extends Equatable {
  const CuentasPagarState();
  @override
  List<Object?> get props => [];
}

class CuentasPagarInitial extends CuentasPagarState {
  const CuentasPagarInitial();
}

class CuentasPagarLoading extends CuentasPagarState {
  const CuentasPagarLoading();
}

class CuentasPagarLoaded extends CuentasPagarState {
  final List<CuentaPorPagar> cuentas;
  final ResumenCuentasPagar? resumen;

  const CuentasPagarLoaded({required this.cuentas, this.resumen});

  @override
  List<Object?> get props => [cuentas, resumen];
}

class CuentasPagarError extends CuentasPagarState {
  final String message;
  const CuentasPagarError(this.message);
  @override
  List<Object?> get props => [message];
}
