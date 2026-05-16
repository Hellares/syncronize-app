import 'package:equatable/equatable.dart';
import '../../domain/entities/arqueo_caja.dart';

abstract class ArqueosCajaState extends Equatable {
  const ArqueosCajaState();

  @override
  List<Object?> get props => [];
}

class ArqueosCajaInitial extends ArqueosCajaState {
  const ArqueosCajaInitial();
}

class ArqueosCajaLoading extends ArqueosCajaState {
  const ArqueosCajaLoading();
}

class ArqueosCajaLoaded extends ArqueosCajaState {
  final List<ArqueoCaja> arqueos;
  final ArqueoCaja? recienCreado;

  const ArqueosCajaLoaded(this.arqueos, {this.recienCreado});

  @override
  List<Object?> get props => [arqueos, recienCreado];
}

class ArqueosCajaCreating extends ArqueosCajaState {
  const ArqueosCajaCreating();
}

class ArqueosCajaError extends ArqueosCajaState {
  final String message;

  const ArqueosCajaError(this.message);

  @override
  List<Object?> get props => [message];
}
