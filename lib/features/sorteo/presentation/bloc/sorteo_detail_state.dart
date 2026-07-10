part of 'sorteo_detail_cubit.dart';

abstract class SorteoDetailState extends Equatable {
  const SorteoDetailState();
  @override
  List<Object?> get props => [];
}

class SorteoDetailLoading extends SorteoDetailState {
  const SorteoDetailLoading();
}

class SorteoDetailLoaded extends SorteoDetailState {
  final Sorteo sorteo;
  const SorteoDetailLoaded(this.sorteo);

  @override
  List<Object?> get props => [sorteo];
}

class SorteoDetailError extends SorteoDetailState {
  final String message;
  const SorteoDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
