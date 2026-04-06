import 'package:equatable/equatable.dart';
import '../../domain/entities/guia_remision.dart';

abstract class GuiaRemisionListState extends Equatable {
  const GuiaRemisionListState();
  @override
  List<Object?> get props => [];
}

class GuiaRemisionListInitial extends GuiaRemisionListState {}

class GuiaRemisionListLoading extends GuiaRemisionListState {}

class GuiaRemisionListLoaded extends GuiaRemisionListState {
  final List<GuiaRemision> guias;
  final int total;
  final int totalPages;
  final int currentPage;

  const GuiaRemisionListLoaded({
    required this.guias,
    required this.total,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [guias, total, currentPage];
}

class GuiaRemisionListError extends GuiaRemisionListState {
  final String message;
  const GuiaRemisionListError(this.message);
  @override
  List<Object?> get props => [message];
}
