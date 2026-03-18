import 'package:equatable/equatable.dart';
import '../../../domain/entities/direccion_persona.dart';

abstract class DireccionListState extends Equatable {
  const DireccionListState();

  @override
  List<Object?> get props => [];
}

class DireccionListInitial extends DireccionListState {
  const DireccionListInitial();
}

class DireccionListLoading extends DireccionListState {
  const DireccionListLoading();
}

class DireccionListLoaded extends DireccionListState {
  final List<DireccionPersona> direcciones;

  const DireccionListLoaded({required this.direcciones});

  @override
  List<Object?> get props => [direcciones];
}

class DireccionListError extends DireccionListState {
  final String message;

  const DireccionListError(this.message);

  @override
  List<Object?> get props => [message];
}
