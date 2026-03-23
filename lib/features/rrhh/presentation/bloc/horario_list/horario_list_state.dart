import 'package:equatable/equatable.dart';

import '../../../domain/entities/horario_plantilla.dart';

abstract class HorarioListState extends Equatable {
  const HorarioListState();

  @override
  List<Object?> get props => [];
}

class HorarioListInitial extends HorarioListState {
  const HorarioListInitial();
}

class HorarioListLoading extends HorarioListState {
  const HorarioListLoading();
}

class HorarioListLoaded extends HorarioListState {
  final List<HorarioPlantilla> horarios;

  const HorarioListLoaded(this.horarios);

  @override
  List<Object?> get props => [horarios];
}

class HorarioListError extends HorarioListState {
  final String message;

  const HorarioListError(this.message);

  @override
  List<Object?> get props => [message];
}

class HorarioListActionSuccess extends HorarioListState {
  final String message;

  const HorarioListActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
