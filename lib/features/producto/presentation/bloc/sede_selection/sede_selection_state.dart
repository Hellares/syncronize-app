import 'package:equatable/equatable.dart';

/// Estados del cubit de selección de sede
abstract class SedeSelectionState extends Equatable {
  const SedeSelectionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class SedeSelectionInitial extends SedeSelectionState {
  const SedeSelectionInitial();
}

/// Estado cuando se ha seleccionado una sede
class SedeSelected extends SedeSelectionState {
  final String sedeId;

  const SedeSelected(this.sedeId);

  @override
  List<Object?> get props => [sedeId];
}

/// Estado cuando no hay sede seleccionada
class NoSedeSelected extends SedeSelectionState {
  const NoSedeSelected();
}
