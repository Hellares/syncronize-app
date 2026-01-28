part of 'eliminar_item_cubit.dart';

abstract class EliminarItemState extends Equatable {
  const EliminarItemState();

  @override
  List<Object?> get props => [];
}

class EliminarItemInitial extends EliminarItemState {
  const EliminarItemInitial();
}

class EliminarItemLoading extends EliminarItemState {
  const EliminarItemLoading();
}

class EliminarItemSuccess extends EliminarItemState {
  const EliminarItemSuccess();
}

class EliminarItemError extends EliminarItemState {
  final String message;

  const EliminarItemError(this.message);

  @override
  List<Object?> get props => [message];
}
