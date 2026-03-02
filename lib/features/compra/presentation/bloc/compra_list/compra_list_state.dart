import 'package:equatable/equatable.dart';
import '../../../domain/entities/compra.dart';

abstract class CompraListState extends Equatable {
  const CompraListState();

  @override
  List<Object?> get props => [];
}

class CompraListInitial extends CompraListState {
  const CompraListInitial();
}

class CompraListLoading extends CompraListState {
  const CompraListLoading();
}

class CompraListLoaded extends CompraListState {
  final List<Compra> compras;
  final String? searchQuery;
  final String? estadoFilter;

  const CompraListLoaded({
    required this.compras,
    this.searchQuery,
    this.estadoFilter,
  });

  List<Compra> get filteredCompras {
    var filtered = compras;

    if (estadoFilter != null && estadoFilter!.isNotEmpty) {
      filtered = filtered.where((c) => c.estado.name == estadoFilter).toList();
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((c) {
        return c.codigo.toLowerCase().contains(query) ||
            c.nombreProveedor.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  List<Object?> get props => [compras, searchQuery, estadoFilter];

  CompraListLoaded copyWith({
    List<Compra>? compras,
    String? searchQuery,
    String? estadoFilter,
  }) {
    return CompraListLoaded(
      compras: compras ?? this.compras,
      searchQuery: searchQuery ?? this.searchQuery,
      estadoFilter: estadoFilter ?? this.estadoFilter,
    );
  }
}

class CompraListError extends CompraListState {
  final String message;

  const CompraListError(this.message);

  @override
  List<Object?> get props => [message];
}
