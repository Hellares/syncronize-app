part of 'agregar_item_cubit.dart';

abstract class AgregarItemState extends Equatable {
  const AgregarItemState();

  @override
  List<Object?> get props => [];
}

class AgregarItemInitial extends AgregarItemState {
  const AgregarItemInitial();
}

class AgregarItemLoading extends AgregarItemState {
  const AgregarItemLoading();
}

class AgregarItemSuccess extends AgregarItemState {
  final ReporteIncidenciaItem item;

  const AgregarItemSuccess(this.item);

  @override
  List<Object?> get props => [item];
}

class AgregarItemError extends AgregarItemState {
  final String message;

  const AgregarItemError(this.message);

  @override
  List<Object?> get props => [message];
}
