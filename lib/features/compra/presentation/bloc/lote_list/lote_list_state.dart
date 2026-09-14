import 'package:equatable/equatable.dart';
import '../../../domain/entities/lote.dart';

abstract class LoteListState extends Equatable {
  const LoteListState();

  @override
  List<Object?> get props => [];
}

class LoteListInitial extends LoteListState {
  const LoteListInitial();
}

class LoteListLoading extends LoteListState {
  const LoteListLoading();
}

/// Los lotes cargados hasta ahora.
///
/// 🔴 La búsqueda y el estado se aplican en el BACKEND, no acá: antes se
/// filtraba en el app sobre la única página cargada (10 lotes) y un lote que no
/// estaba en esa página "no existía".
class LoteListLoaded extends LoteListState {
  final List<Lote> lotes;

  /// Cuántos cumplen el filtro en total (no solo los cargados).
  final int total;
  final bool hasNext;
  final bool cargandoMas;
  final String? searchQuery;
  final String? estadoFilter;

  /// Mostrando "Próximos a vencer": otro endpoint, sin paginar.
  final bool proximosVencer;

  const LoteListLoaded({
    required this.lotes,
    this.total = 0,
    this.hasNext = false,
    this.cargandoMas = false,
    this.searchQuery,
    this.estadoFilter,
    this.proximosVencer = false,
  });

  bool get hayFiltro =>
      searchQuery != null || estadoFilter != null || proximosVencer;

  @override
  List<Object?> get props =>
      [lotes, total, hasNext, cargandoMas, searchQuery, estadoFilter, proximosVencer];

  /// Solo los datos de la página. 🔴 Los filtros NO pasan por acá: un
  /// `copyWith(estadoFilter: null)` con `??` conservaba el anterior, y así
  /// "Todos" y borrar la búsqueda no limpiaban nada.
  LoteListLoaded copyWith({
    List<Lote>? lotes,
    int? total,
    bool? hasNext,
    bool? cargandoMas,
  }) {
    return LoteListLoaded(
      lotes: lotes ?? this.lotes,
      total: total ?? this.total,
      hasNext: hasNext ?? this.hasNext,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      searchQuery: searchQuery,
      estadoFilter: estadoFilter,
      proximosVencer: proximosVencer,
    );
  }
}

class LoteListError extends LoteListState {
  final String message;

  const LoteListError(this.message);

  @override
  List<Object?> get props => [message];
}
