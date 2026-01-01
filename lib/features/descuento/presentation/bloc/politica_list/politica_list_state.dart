import 'package:equatable/equatable.dart';
import '../../../domain/entities/politica_descuento.dart';

/// Estados de la lista de políticas de descuento
abstract class PoliticaListState extends Equatable {
  const PoliticaListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PoliticaListInitial extends PoliticaListState {
  const PoliticaListInitial();
}

/// Estado de carga
class PoliticaListLoading extends PoliticaListState {
  const PoliticaListLoading();
}

/// Estado de carga de más políticas (paginación)
class PoliticaListLoadingMore extends PoliticaListState {
  final List<PoliticaDescuento> currentPoliticas;

  const PoliticaListLoadingMore(this.currentPoliticas);

  @override
  List<Object?> get props => [currentPoliticas];
}

/// Estado de éxito con políticas cargadas
class PoliticaListLoaded extends PoliticaListState {
  final List<PoliticaDescuento> politicas;
  final int total;
  final int currentPage;
  final int limit;
  final String? tipoDescuentoFiltro;
  final bool? isActiveFiltro;

  const PoliticaListLoaded({
    required this.politicas,
    required this.total,
    required this.currentPage,
    required this.limit,
    this.tipoDescuentoFiltro,
    this.isActiveFiltro,
  });

  bool get hasMore => politicas.length < total;

  @override
  List<Object?> get props => [
        politicas,
        total,
        currentPage,
        limit,
        tipoDescuentoFiltro,
        isActiveFiltro,
      ];
}

/// Estado de error
class PoliticaListError extends PoliticaListState {
  final String message;
  final String? errorCode;

  const PoliticaListError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
