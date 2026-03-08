import 'package:equatable/equatable.dart';
import '../../../domain/entities/servicio.dart';
import '../../../domain/entities/servicio_filtros.dart';

abstract class ServicioListState extends Equatable {
  const ServicioListState();
  @override
  List<Object?> get props => [];
}

class ServicioListInitial extends ServicioListState {
  const ServicioListInitial();
}

class ServicioListLoading extends ServicioListState {
  const ServicioListLoading();
}

class ServicioListLoadingMore extends ServicioListState {
  final List<Servicio> currentServicios;
  const ServicioListLoadingMore(this.currentServicios);
  @override
  List<Object?> get props => [currentServicios];
}

class ServicioListLoaded extends ServicioListState {
  final List<Servicio> servicios;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final ServicioFiltros filtros;

  const ServicioListLoaded({
    required this.servicios,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.filtros,
  });

  @override
  List<Object?> get props => [servicios, total, currentPage, totalPages, hasMore, filtros];
}

class ServicioListError extends ServicioListState {
  final String message;
  final String? errorCode;
  const ServicioListError(this.message, {this.errorCode});
  @override
  List<Object?> get props => [message, errorCode];
}
