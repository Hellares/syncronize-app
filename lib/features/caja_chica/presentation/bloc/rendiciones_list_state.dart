import 'package:equatable/equatable.dart';
import '../../domain/entities/rendicion_caja_chica.dart';

abstract class RendicionesListState extends Equatable {
  const RendicionesListState();

  @override
  List<Object?> get props => [];
}

class RendicionesListInitial extends RendicionesListState {
  const RendicionesListInitial();
}

class RendicionesListLoading extends RendicionesListState {
  const RendicionesListLoading();
}

class RendicionesListLoaded extends RendicionesListState {
  final List<RendicionCajaChica> rendiciones;

  const RendicionesListLoaded(this.rendiciones);

  @override
  List<Object?> get props => [rendiciones];
}

class RendicionesListError extends RendicionesListState {
  final String message;

  const RendicionesListError(this.message);

  @override
  List<Object?> get props => [message];
}
