part of 'resolver_item_cubit.dart';

abstract class ResolverItemState extends Equatable {
  const ResolverItemState();

  @override
  List<Object?> get props => [];
}

class ResolverItemInitial extends ResolverItemState {
  const ResolverItemInitial();
}

class ResolverItemLoading extends ResolverItemState {
  const ResolverItemLoading();
}

class ResolverItemSuccess extends ResolverItemState {
  final ReporteIncidenciaItem item;

  const ResolverItemSuccess(this.item);

  @override
  List<Object?> get props => [item];
}

class ResolverItemError extends ResolverItemState {
  final String message;

  const ResolverItemError(this.message);

  @override
  List<Object?> get props => [message];
}
