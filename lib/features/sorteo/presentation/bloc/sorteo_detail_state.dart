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

  /// Sugerencias de pago Yape/Plin por clave de compra/participante
  /// (best-effort desde api-yape — vacío si no aplica).
  final Map<String, PagoYapeSugerido> pagosYape;

  const SorteoDetailLoaded(this.sorteo, {this.pagosYape = const {}});

  @override
  List<Object?> get props => [sorteo, pagosYape];
}

class SorteoDetailError extends SorteoDetailState {
  final String message;
  const SorteoDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
