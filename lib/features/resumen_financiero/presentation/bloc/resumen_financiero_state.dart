import 'package:equatable/equatable.dart';
import '../../domain/entities/resumen_financiero.dart';

abstract class ResumenFinancieroState extends Equatable {
  const ResumenFinancieroState();

  @override
  List<Object?> get props => [];
}

class ResumenFinancieroInitial extends ResumenFinancieroState {
  const ResumenFinancieroInitial();
}

class ResumenFinancieroLoading extends ResumenFinancieroState {
  const ResumenFinancieroLoading();
}

class ResumenFinancieroLoaded extends ResumenFinancieroState {
  final ResumenFinanciero resumen;
  final GraficoDiario? grafico;

  /// true mientras se recargan los datos manteniendo los actuales en
  /// pantalla (evita el flash de loading al recargar/cambiar de sede).
  final bool refreshing;

  const ResumenFinancieroLoaded({
    required this.resumen,
    this.grafico,
    this.refreshing = false,
  });

  ResumenFinancieroLoaded copyWith({bool? refreshing}) =>
      ResumenFinancieroLoaded(
        resumen: resumen,
        grafico: grafico,
        refreshing: refreshing ?? this.refreshing,
      );

  @override
  List<Object?> get props => [resumen, grafico, refreshing];
}

class ResumenFinancieroError extends ResumenFinancieroState {
  final String message;

  const ResumenFinancieroError(this.message);

  @override
  List<Object?> get props => [message];
}
