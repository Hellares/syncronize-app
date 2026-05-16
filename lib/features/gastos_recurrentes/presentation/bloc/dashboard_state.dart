import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_gastos.dart';

abstract class DashboardGastosState extends Equatable {
  const DashboardGastosState();
  @override
  List<Object?> get props => [];
}

class DashboardGastosInitial extends DashboardGastosState {
  const DashboardGastosInitial();
}

class DashboardGastosLoading extends DashboardGastosState {
  const DashboardGastosLoading();
}

class DashboardGastosLoaded extends DashboardGastosState {
  final DashboardGastos data;
  final String periodo;
  const DashboardGastosLoaded(this.data, this.periodo);

  @override
  List<Object?> get props => [data, periodo];
}

class DashboardGastosError extends DashboardGastosState {
  final String message;
  const DashboardGastosError(this.message);
  @override
  List<Object?> get props => [message];
}
