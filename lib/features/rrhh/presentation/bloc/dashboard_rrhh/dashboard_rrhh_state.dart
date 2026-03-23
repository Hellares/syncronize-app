import 'package:equatable/equatable.dart';

import '../../../domain/entities/dashboard_rrhh.dart';

abstract class DashboardRrhhState extends Equatable {
  const DashboardRrhhState();

  @override
  List<Object?> get props => [];
}

class DashboardRrhhInitial extends DashboardRrhhState {
  const DashboardRrhhInitial();
}

class DashboardRrhhLoading extends DashboardRrhhState {
  const DashboardRrhhLoading();
}

class DashboardRrhhLoaded extends DashboardRrhhState {
  final DashboardRrhh dashboard;

  const DashboardRrhhLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

class DashboardRrhhError extends DashboardRrhhState {
  final String message;

  const DashboardRrhhError(this.message);

  @override
  List<Object?> get props => [message];
}
