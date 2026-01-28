part of 'sedes_selector_cubit.dart';

abstract class SedesSelectorState extends Equatable {
  const SedesSelectorState();

  @override
  List<Object?> get props => [];
}

class SedesSelectorInitial extends SedesSelectorState {
  const SedesSelectorInitial();
}

class SedesSelectorLoading extends SedesSelectorState {
  const SedesSelectorLoading();
}

class SedesSelectorLoaded extends SedesSelectorState {
  final List<SedeSimple> sedes;

  const SedesSelectorLoaded(this.sedes);

  @override
  List<Object?> get props => [sedes];
}

class SedesSelectorError extends SedesSelectorState {
  final String message;

  const SedesSelectorError(this.message);

  @override
  List<Object?> get props => [message];
}
