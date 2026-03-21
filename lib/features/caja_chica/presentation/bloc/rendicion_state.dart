import 'package:equatable/equatable.dart';
import '../../domain/entities/rendicion_caja_chica.dart';

abstract class RendicionState extends Equatable {
  const RendicionState();

  @override
  List<Object?> get props => [];
}

class RendicionInitial extends RendicionState {
  const RendicionInitial();
}

class RendicionLoading extends RendicionState {
  const RendicionLoading();
}

class RendicionDetailLoaded extends RendicionState {
  final RendicionCajaChica rendicion;

  const RendicionDetailLoaded(this.rendicion);

  @override
  List<Object?> get props => [rendicion];
}

class RendicionCreated extends RendicionState {
  final RendicionCajaChica rendicion;

  const RendicionCreated(this.rendicion);

  @override
  List<Object?> get props => [rendicion];
}

class RendicionApproved extends RendicionState {
  const RendicionApproved();
}

class RendicionRejected extends RendicionState {
  const RendicionRejected();
}

class RendicionError extends RendicionState {
  final String message;

  const RendicionError(this.message);

  @override
  List<Object?> get props => [message];
}
