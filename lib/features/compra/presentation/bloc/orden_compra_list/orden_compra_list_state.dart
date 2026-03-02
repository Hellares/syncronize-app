import 'package:equatable/equatable.dart';
import '../../../domain/entities/orden_compra.dart';

abstract class OrdenCompraListState extends Equatable {
  const OrdenCompraListState();

  @override
  List<Object?> get props => [];
}

class OrdenCompraListInitial extends OrdenCompraListState {
  const OrdenCompraListInitial();
}

class OrdenCompraListLoading extends OrdenCompraListState {
  const OrdenCompraListLoading();
}

class OrdenCompraListLoaded extends OrdenCompraListState {
  final List<OrdenCompra> ordenes;
  final String? searchQuery;
  final String? estadoFilter;

  const OrdenCompraListLoaded({
    required this.ordenes,
    this.searchQuery,
    this.estadoFilter,
  });

  List<OrdenCompra> get filteredOrdenes {
    var filtered = ordenes;

    if (estadoFilter != null && estadoFilter!.isNotEmpty) {
      filtered = filtered.where((o) => o.estado.name == estadoFilter).toList();
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((o) {
        return o.codigo.toLowerCase().contains(query) ||
            o.nombreProveedor.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  List<Object?> get props => [ordenes, searchQuery, estadoFilter];

  OrdenCompraListLoaded copyWith({
    List<OrdenCompra>? ordenes,
    String? searchQuery,
    String? estadoFilter,
  }) {
    return OrdenCompraListLoaded(
      ordenes: ordenes ?? this.ordenes,
      searchQuery: searchQuery ?? this.searchQuery,
      estadoFilter: estadoFilter ?? this.estadoFilter,
    );
  }
}

class OrdenCompraListError extends OrdenCompraListState {
  final String message;

  const OrdenCompraListError(this.message);

  @override
  List<Object?> get props => [message];
}
