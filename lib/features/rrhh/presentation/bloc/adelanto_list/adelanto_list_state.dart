import 'package:equatable/equatable.dart';

import '../../../domain/entities/adelanto.dart';

abstract class AdelantoListState extends Equatable {
  const AdelantoListState();

  @override
  List<Object?> get props => [];
}

class AdelantoListInitial extends AdelantoListState {
  const AdelantoListInitial();
}

class AdelantoListLoading extends AdelantoListState {
  const AdelantoListLoading();
}

class AdelantoListLoaded extends AdelantoListState {
  final List<Adelanto> adelantos;

  const AdelantoListLoaded(this.adelantos);

  @override
  List<Object?> get props => [adelantos];
}

class AdelantoListError extends AdelantoListState {
  final String message;

  const AdelantoListError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdelantoListActionSuccess extends AdelantoListState {
  final String message;

  const AdelantoListActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
