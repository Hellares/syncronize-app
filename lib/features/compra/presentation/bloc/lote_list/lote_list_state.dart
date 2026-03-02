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

class LoteListLoaded extends LoteListState {
  final List<Lote> lotes;
  final String? searchQuery;
  final String? estadoFilter;

  const LoteListLoaded({
    required this.lotes,
    this.searchQuery,
    this.estadoFilter,
  });

  List<Lote> get filteredLotes {
    var filtered = lotes;

    if (estadoFilter != null && estadoFilter!.isNotEmpty) {
      filtered = filtered.where((l) => l.estado.name == estadoFilter).toList();
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((l) {
        return l.codigo.toLowerCase().contains(query) ||
            l.nombreProducto.toLowerCase().contains(query) ||
            (l.numeroLote?.toLowerCase().contains(query) ?? false) ||
            (l.nombreProveedor?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  List<Lote> get lotesActivos =>
      filteredLotes.where((l) => l.esActivo).toList();

  List<Lote> get lotesProximosVencer =>
      filteredLotes.where((l) => l.proximoAVencer && l.esActivo).toList();

  @override
  List<Object?> get props => [lotes, searchQuery, estadoFilter];

  LoteListLoaded copyWith({
    List<Lote>? lotes,
    String? searchQuery,
    String? estadoFilter,
  }) {
    return LoteListLoaded(
      lotes: lotes ?? this.lotes,
      searchQuery: searchQuery ?? this.searchQuery,
      estadoFilter: estadoFilter ?? this.estadoFilter,
    );
  }
}

class LoteListError extends LoteListState {
  final String message;

  const LoteListError(this.message);

  @override
  List<Object?> get props => [message];
}
