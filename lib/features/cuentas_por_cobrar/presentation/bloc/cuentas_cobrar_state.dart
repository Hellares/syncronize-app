import 'package:equatable/equatable.dart';
import '../../domain/entities/cuenta_por_cobrar.dart';

abstract class CuentasCobrarState extends Equatable {
  const CuentasCobrarState();
  @override
  List<Object?> get props => [];
}

class CuentasCobrarInitial extends CuentasCobrarState {
  const CuentasCobrarInitial();
}

class CuentasCobrarLoading extends CuentasCobrarState {
  const CuentasCobrarLoading();
}

class CuentasCobrarLoaded extends CuentasCobrarState {
  final List<CuentaPorCobrar> cuentas;
  final ResumenCuentasCobrar? resumen;

  const CuentasCobrarLoaded({required this.cuentas, this.resumen});

  @override
  List<Object?> get props => [cuentas, resumen];
}

class CuentasCobrarError extends CuentasCobrarState {
  final String message;
  const CuentasCobrarError(this.message);
  @override
  List<Object?> get props => [message];
}
