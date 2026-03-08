import 'package:equatable/equatable.dart';
import '../../../domain/entities/orden_servicio.dart';
import '../../../domain/entities/servicio_filtros.dart';

abstract class OrdenServicioListState extends Equatable {
  const OrdenServicioListState();
  @override
  List<Object?> get props => [];
}

class OrdenServicioListInitial extends OrdenServicioListState {
  const OrdenServicioListInitial();
}

class OrdenServicioListLoading extends OrdenServicioListState {
  const OrdenServicioListLoading();
}

class OrdenServicioListLoadingMore extends OrdenServicioListState {
  final List<OrdenServicio> currentOrdenes;
  const OrdenServicioListLoadingMore(this.currentOrdenes);
  @override
  List<Object?> get props => [currentOrdenes];
}

class OrdenServicioListLoaded extends OrdenServicioListState {
  final List<OrdenServicio> ordenes;
  final int total;
  final bool hasMore;
  final String? nextCursor;
  final OrdenServicioFiltros filtros;

  const OrdenServicioListLoaded({
    required this.ordenes,
    required this.total,
    required this.hasMore,
    this.nextCursor,
    required this.filtros,
  });

  @override
  List<Object?> get props => [ordenes, total, hasMore, nextCursor, filtros];
}

class OrdenServicioListError extends OrdenServicioListState {
  final String message;
  final String? errorCode;
  const OrdenServicioListError(this.message, {this.errorCode});
  @override
  List<Object?> get props => [message, errorCode];
}
