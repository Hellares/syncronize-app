import 'package:equatable/equatable.dart';

import '../../../domain/entities/horario_plantilla.dart';

abstract class HorarioPlantillaState extends Equatable {
  const HorarioPlantillaState();

  @override
  List<Object?> get props => [];
}

class HorarioPlantillaInitial extends HorarioPlantillaState {
  const HorarioPlantillaInitial();
}

class HorarioPlantillaLoading extends HorarioPlantillaState {
  const HorarioPlantillaLoading();
}

class HorarioPlantillaLoaded extends HorarioPlantillaState {
  final List<HorarioPlantilla> plantillas;

  const HorarioPlantillaLoaded(this.plantillas);

  @override
  List<Object?> get props => [plantillas];
}

class HorarioPlantillaError extends HorarioPlantillaState {
  final String message;

  const HorarioPlantillaError(this.message);

  @override
  List<Object?> get props => [message];
}

class HorarioPlantillaActionSuccess extends HorarioPlantillaState {
  final String message;

  const HorarioPlantillaActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
