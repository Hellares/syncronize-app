import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_vendedor.dart';

abstract class DashboardVendedorState extends Equatable {
  const DashboardVendedorState();
  @override
  List<Object?> get props => [];
}

class DashboardVendedorInitial extends DashboardVendedorState {
  const DashboardVendedorInitial();
}

class DashboardVendedorLoading extends DashboardVendedorState {
  const DashboardVendedorLoading();
}

class DashboardVendedorLoaded extends DashboardVendedorState {
  final DashboardVendedor data;

  const DashboardVendedorLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class DashboardVendedorError extends DashboardVendedorState {
  final String message;
  const DashboardVendedorError(this.message);
  @override
  List<Object?> get props => [message];
}
