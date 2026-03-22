import 'package:equatable/equatable.dart';
import '../../domain/entities/monitor_productos.dart';

abstract class MonitorProductosState extends Equatable {
  const MonitorProductosState();
  @override
  List<Object?> get props => [];
}

class MonitorProductosInitial extends MonitorProductosState {
  const MonitorProductosInitial();
}

class MonitorProductosLoading extends MonitorProductosState {
  const MonitorProductosLoading();
}

class MonitorProductosLoaded extends MonitorProductosState {
  final MonitorProductos data;

  const MonitorProductosLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class MonitorProductosError extends MonitorProductosState {
  final String message;
  const MonitorProductosError(this.message);
  @override
  List<Object?> get props => [message];
}
