import 'package:equatable/equatable.dart';

import '../../../domain/entities/adelanto.dart';

abstract class AdelantoState extends Equatable {
  const AdelantoState();

  @override
  List<Object?> get props => [];
}

class AdelantoInitial extends AdelantoState {
  const AdelantoInitial();
}

class AdelantoLoading extends AdelantoState {
  const AdelantoLoading();
}

class AdelantoListLoaded extends AdelantoState {
  final List<Adelanto> adelantos;

  const AdelantoListLoaded(this.adelantos);

  @override
  List<Object?> get props => [adelantos];
}

class AdelantoActionSuccess extends AdelantoState {
  final String message;

  const AdelantoActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdelantoError extends AdelantoState {
  final String message;

  const AdelantoError(this.message);

  @override
  List<Object?> get props => [message];
}
