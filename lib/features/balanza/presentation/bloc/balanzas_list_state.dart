import 'package:equatable/equatable.dart';
import '../../domain/entities/balanza_config.dart';

abstract class BalanzasListState extends Equatable {
  const BalanzasListState();
  @override
  List<Object?> get props => [];
}

class BalanzasListInitial extends BalanzasListState {
  const BalanzasListInitial();
}

class BalanzasListLoading extends BalanzasListState {
  const BalanzasListLoading();
}

class BalanzasListLoaded extends BalanzasListState {
  final List<BalanzaConfig> balanzas;
  const BalanzasListLoaded(this.balanzas);
  @override
  List<Object?> get props => [balanzas];
}

class BalanzasListError extends BalanzasListState {
  final String message;
  const BalanzasListError(this.message);
  @override
  List<Object?> get props => [message];
}
