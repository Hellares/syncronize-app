import 'package:equatable/equatable.dart';

/// Enum para ordenamiento de productos
enum OrdenProducto {
  nombreAsc,
  nombreDesc,
  precioAsc,
  precioDesc,
  stockAsc,
  stockDesc,
  recientes,
  antiguos,
}

/// Entity que representa los filtros de búsqueda de productos
class ProductoFiltros extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? empresaCategoriaId;
  final String? empresaMarcaId;
  final String? sedeId;
  final bool? visibleMarketplace;
  final bool? destacado;
  final bool? enOferta;
  final bool? stockBajo;
  final bool? soloProductos;
  final bool? soloCombos;
  final OrdenProducto? orden;

  const ProductoFiltros({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.empresaCategoriaId,
    this.empresaMarcaId,
    this.sedeId,
    this.visibleMarketplace,
    this.destacado,
    this.enOferta,
    this.stockBajo,
    this.soloProductos,
    this.soloCombos,
    this.orden,
  });

  /// Crea una copia con valores actualizados
  ///
  /// Para establecer un campo nullable a null, usa los parámetros clear*
  ProductoFiltros copyWith({
    int? page,
    int? limit,
    String? search,
    String? empresaCategoriaId,
    String? empresaMarcaId,
    String? sedeId,
    bool? visibleMarketplace,
    bool? destacado,
    bool? enOferta,
    bool? stockBajo,
    bool? soloProductos,
    bool? soloCombos,
    OrdenProducto? orden,
    // Flags para resetear valores nullable
    bool clearSearch = false,
    bool clearEmpresaCategoriaId = false,
    bool clearEmpresaMarcaId = false,
    bool clearSedeId = false,
    bool clearVisibleMarketplace = false,
    bool clearDestacado = false,
    bool clearEnOferta = false,
    bool clearStockBajo = false,
    bool clearSoloProductos = false,
    bool clearSoloCombos = false,
    bool clearOrden = false,
  }) {
    return ProductoFiltros(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      empresaCategoriaId: clearEmpresaCategoriaId ? null : (empresaCategoriaId ?? this.empresaCategoriaId),
      empresaMarcaId: clearEmpresaMarcaId ? null : (empresaMarcaId ?? this.empresaMarcaId),
      sedeId: clearSedeId ? null : (sedeId ?? this.sedeId),
      visibleMarketplace: clearVisibleMarketplace ? null : (visibleMarketplace ?? this.visibleMarketplace),
      destacado: clearDestacado ? null : (destacado ?? this.destacado),
      enOferta: clearEnOferta ? null : (enOferta ?? this.enOferta),
      stockBajo: clearStockBajo ? null : (stockBajo ?? this.stockBajo),
      soloProductos: clearSoloProductos ? null : (soloProductos ?? this.soloProductos),
      soloCombos: clearSoloCombos ? null : (soloCombos ?? this.soloCombos),
      orden: clearOrden ? null : (orden ?? this.orden),
    );
  }

  /// Resetea los filtros a valores por defecto
  ProductoFiltros reset() {
    return const ProductoFiltros();
  }

  /// Convierte a Map para query parameters
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (empresaCategoriaId != null) {
      params['empresaCategoriaId'] = empresaCategoriaId;
    }
    if (empresaMarcaId != null) {
      params['empresaMarcaId'] = empresaMarcaId;
    }
    if (sedeId != null) {
      params['sedeId'] = sedeId;
    }
    if (visibleMarketplace != null) {
      params['visibleMarketplace'] = visibleMarketplace.toString();
    }
    if (destacado != null) {
      params['destacado'] = destacado.toString();
    }
    if (enOferta != null) {
      params['enOferta'] = enOferta.toString();
    }
    if (stockBajo != null) {
      params['stockBajo'] = stockBajo.toString();
    }
    if (soloProductos != null) {
      params['soloProductos'] = soloProductos.toString();
    }
    if (soloCombos != null) {
      params['soloCombos'] = soloCombos.toString();
    }
    if (orden != null) {
      params['orden'] = _ordenToString(orden!);
    }

    return params;
  }

  String _ordenToString(OrdenProducto orden) {
    switch (orden) {
      case OrdenProducto.nombreAsc:
        return 'nombre_asc';
      case OrdenProducto.nombreDesc:
        return 'nombre_desc';
      case OrdenProducto.precioAsc:
        return 'precio_asc';
      case OrdenProducto.precioDesc:
        return 'precio_desc';
      case OrdenProducto.stockAsc:
        return 'stock_asc';
      case OrdenProducto.stockDesc:
        return 'stock_desc';
      case OrdenProducto.recientes:
        return 'recientes';
      case OrdenProducto.antiguos:
        return 'antiguos';
    }
  }

  @override
  List<Object?> get props => [
        page,
        limit,
        search,
        empresaCategoriaId,
        empresaMarcaId,
        sedeId,
        visibleMarketplace,
        destacado,
        enOferta,
        stockBajo,
        soloProductos,
        soloCombos,
        orden,
      ];
}

/// Entity que representa el resultado paginado de productos
class ProductosPaginados extends Equatable {
  final List<dynamic> data; // Puede ser List<Producto> o List<ProductoListItem>
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final int offset;
  final bool hasNext;
  final bool hasPrevious;

  const ProductosPaginados({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.offset,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Verifica si hay más páginas (alias para hasNext)
  bool get hasMore => hasNext;

  /// Verifica si es la primera página
  bool get isFirstPage => page == 1;

  /// Verifica si es la última página
  bool get isLastPage => !hasNext;

  /// Getter para mantener compatibilidad con código existente
  @Deprecated('Use data instead')
  List<dynamic> get productos => data;

  /// Getter para mantener compatibilidad con código existente
  @Deprecated('Use pageSize instead')
  int get limit => pageSize;

  @override
  List<Object?> get props => [data, total, page, pageSize, totalPages, offset, hasNext, hasPrevious];
}
