import 'package:equatable/equatable.dart';
import '../../domain/entities/anulacion.dart';

/// Filtro por tipo de anulación.
enum FiltroTipoAnulacion {
  todas,
  cdb,
  rc;

  String get label => switch (this) {
        FiltroTipoAnulacion.todas => 'Todas',
        FiltroTipoAnulacion.cdb => 'CDB (Factura)',
        FiltroTipoAnulacion.rc => 'RC (Boleta)',
      };
}

abstract class AnulacionesState extends Equatable {
  const AnulacionesState();

  @override
  List<Object?> get props => [];
}

class AnulacionesInitial extends AnulacionesState {}

class AnulacionesLoading extends AnulacionesState {}

class AnulacionesLoaded extends AnulacionesState {
  final List<Anulacion> items;
  final int total;
  final int currentPage;
  final int totalPages;
  final FiltroTipoAnulacion filtroTipo;
  final String? filtroEstado;
  final String? fechaDesde;
  final String? fechaHasta;

  const AnulacionesLoaded({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.filtroTipo,
    this.filtroEstado,
    this.fechaDesde,
    this.fechaHasta,
  });

  AnulacionesLoaded copyWith({
    List<Anulacion>? items,
    int? total,
    int? currentPage,
    int? totalPages,
    FiltroTipoAnulacion? filtroTipo,
    String? filtroEstado,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return AnulacionesLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      filtroTipo: filtroTipo ?? this.filtroTipo,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      fechaDesde: fechaDesde ?? this.fechaDesde,
      fechaHasta: fechaHasta ?? this.fechaHasta,
    );
  }

  @override
  List<Object?> get props => [
        items,
        total,
        currentPage,
        totalPages,
        filtroTipo,
        filtroEstado,
        fechaDesde,
        fechaHasta,
      ];
}

class AnulacionesError extends AnulacionesState {
  final String message;
  const AnulacionesError(this.message);

  @override
  List<Object?> get props => [message];
}
