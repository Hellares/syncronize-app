import 'package:equatable/equatable.dart';
import '../../domain/entities/caja_monitor.dart';

sealed class CajaMonitorState extends Equatable {
  const CajaMonitorState();
}

final class CajaMonitorInitial extends CajaMonitorState {
  const CajaMonitorInitial();
  @override
  List<Object?> get props => [];
}

final class CajaMonitorLoading extends CajaMonitorState {
  const CajaMonitorLoading();
  @override
  List<Object?> get props => [];
}

final class CajaMonitorLoaded extends CajaMonitorState {
  final CajaMonitorData data;
  const CajaMonitorLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

final class CajaMonitorError extends CajaMonitorState {
  final String message;
  const CajaMonitorError(this.message);
  @override
  List<Object?> get props => [message];
}
