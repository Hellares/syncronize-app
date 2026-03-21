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

  const ResumenFinancieroLoaded({
    required this.resumen,
    this.grafico,
  });

  @override
  List<Object?> get props => [resumen, grafico];
}

class ResumenFinancieroError extends ResumenFinancieroState {
  final String message;

  const ResumenFinancieroError(this.message);

  @override
  List<Object?> get props => [message];
}
