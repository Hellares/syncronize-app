part of 'marketplace_search_cubit.dart';

abstract class MarketplaceSearchState extends Equatable {
  const MarketplaceSearchState();

  @override
  List<Object?> get props => [];
}

class MarketplaceSearchInitial extends MarketplaceSearchState {
  const MarketplaceSearchInitial();
}

class MarketplaceSearchLoading extends MarketplaceSearchState {
  const MarketplaceSearchLoading();
}

class MarketplaceSearchLoaded extends MarketplaceSearchState {
  final List<dynamic> productos;
  final int total;
  final int page;
  final int totalPages;
  final String? search;
  final String? categoriaId;
  final List<dynamic>? categorias;

  const MarketplaceSearchLoaded({
    required this.productos,
    required this.total,
    required this.page,
    required this.totalPages,
    this.search,
    this.categoriaId,
    this.categorias,
  });

  MarketplaceSearchLoaded copyWith({
    List<dynamic>? productos,
    int? total,
    int? page,
    int? totalPages,
    String? search,
    String? categoriaId,
    List<dynamic>? categorias,
  }) {
    return MarketplaceSearchLoaded(
      productos: productos ?? this.productos,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      categoriaId: categoriaId ?? this.categoriaId,
      categorias: categorias ?? this.categorias,
    );
  }

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [productos, total, page, totalPages, search, categoriaId, categorias];
}

class MarketplaceSearchError extends MarketplaceSearchState {
  final String message;

  const MarketplaceSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
