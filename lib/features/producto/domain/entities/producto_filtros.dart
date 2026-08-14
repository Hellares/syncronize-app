import 'package:equatable/equatable.dart';
import 'producto.dart';

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
  /// Con `sedeId`, el backend devuelve SOLO los productos que ya tienen
  /// `ProductoStock` en esa sede. `mostrarTodos: true` se salta ese filtro y
  /// trae todo el catálogo de la empresa. Necesario donde el producto todavía
  /// NO vive en la sede y justamente se lo está por dar de alta ahí (una
  /// recepción de compra), si no el usuario lo crea duplicado.
  final bool? mostrarTodos;
  final bool? visibleMarketplace;
  final bool? destacado;
  final bool? enOferta;
  /// Filtrar productos con liquidación activa en al menos una sede (o en
  /// la sede indicada por `sedeId` si se proporciona).
  final bool? enLiquidacion;
  final bool? stockBajo;
  final bool? soloProductos;
  final bool? soloCombos;
  /// Filtra por flag esInsumo: true=solo insumos, false=excluir insumos,
  /// null=todos (incluyendo insumos). Default null deja al frontend decidir
  /// según el tab activo. Cada tab manda el valor que le interesa.
  final bool? esInsumo;
  /// Listar SOLO productos eliminados (papelera). true → deletedAt != null.
  final bool? soloEliminados;
  /// Filtrar por estado activo. null = ambos. Independiente de soloEliminados.
  final bool? isActive;

  /// Filtro por valor de atributo: `clave del atributo` → valores elegidos.
  ///
  /// Claves distintas se combinan con **Y** y los valores de una misma clave
  /// con **O**, que es lo que hace el backend. Así se puede pedir "Qualcomm o
  /// Samsung, y con 8GB de RAM".
  final Map<String, List<String>> atributos;

  final OrdenProducto? orden;

  const ProductoFiltros({
    this.page = 1,
    this.limit = 50,
    this.search,
    this.empresaCategoriaId,
    this.empresaMarcaId,
    this.sedeId,
    this.mostrarTodos,
    this.visibleMarketplace,
    this.destacado,
    this.enOferta,
    this.enLiquidacion,
    this.stockBajo,
    this.soloProductos,
    this.soloCombos,
    this.esInsumo,
    this.soloEliminados,
    this.isActive,
    this.atributos = const {},
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
    bool? mostrarTodos,
    bool? visibleMarketplace,
    bool? destacado,
    bool? enOferta,
    bool? enLiquidacion,
    bool? stockBajo,
    bool? soloProductos,
    bool? soloCombos,
    bool? esInsumo,
    Map<String, List<String>>? atributos,
    OrdenProducto? orden,
    // Flags para resetear valores nullable
    bool clearSearch = false,
    bool clearEmpresaCategoriaId = false,
    bool clearEmpresaMarcaId = false,
    bool clearSedeId = false,
    bool clearMostrarTodos = false,
    bool clearVisibleMarketplace = false,
    bool clearDestacado = false,
    bool clearEnOferta = false,
    bool clearEnLiquidacion = false,
    bool clearStockBajo = false,
    bool clearSoloProductos = false,
    bool clearSoloCombos = false,
    bool clearEsInsumo = false,
    bool clearOrden = false,
  }) {
    return ProductoFiltros(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      empresaCategoriaId: clearEmpresaCategoriaId ? null : (empresaCategoriaId ?? this.empresaCategoriaId),
      empresaMarcaId: clearEmpresaMarcaId ? null : (empresaMarcaId ?? this.empresaMarcaId),
      sedeId: clearSedeId ? null : (sedeId ?? this.sedeId),
      mostrarTodos: clearMostrarTodos ? null : (mostrarTodos ?? this.mostrarTodos),
      visibleMarketplace: clearVisibleMarketplace ? null : (visibleMarketplace ?? this.visibleMarketplace),
      destacado: clearDestacado ? null : (destacado ?? this.destacado),
      enOferta: clearEnOferta ? null : (enOferta ?? this.enOferta),
      enLiquidacion: clearEnLiquidacion ? null : (enLiquidacion ?? this.enLiquidacion),
      stockBajo: clearStockBajo ? null : (stockBajo ?? this.stockBajo),
      soloProductos: clearSoloProductos ? null : (soloProductos ?? this.soloProductos),
      soloCombos: clearSoloCombos ? null : (soloCombos ?? this.soloCombos),
      esInsumo: clearEsInsumo ? null : (esInsumo ?? this.esInsumo),
      // Un mapa vacío es un valor legítimo —"saqué todos los filtros"— así que
      // no alcanza con `??`: eso lo confundiría con "no lo toqué".
      atributos: atributos ?? this.atributos,
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
    // Solo cuando es true: el backend lo lee con `value === 'true'` y su
    // default ya es false.
    if (mostrarTodos == true) {
      params['mostrarTodos'] = 'true';
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
    if (enLiquidacion != null) {
      params['enLiquidacion'] = enLiquidacion.toString();
    }
    if (stockBajo != null) {
      params['stockBajo'] = stockBajo.toString();
    }
    if (soloProductos == true) {
      params['soloProductos'] = 'true';
    }
    if (soloCombos == true) {
      params['soloCombos'] = 'true';
    }
    if (esInsumo != null) {
      params['esInsumo'] = esInsumo.toString();
    }
    if (soloEliminados == true) {
      params['soloEliminados'] = 'true';
    }
    if (isActive != null) {
      params['isActive'] = isActive.toString();
    }
    if (orden != null) {
      params['orden'] = _ordenToString(orden!);
    }
    // Se manda como lista de `clave:valor`; Dio la serializa repetida
    // (atributos=a:b&atributos=a:c), que es como la lee el backend.
    if (atributos.isNotEmpty) {
      final entradas = <String>[
        for (final e in atributos.entries)
          for (final v in e.value) '${e.key}:$v',
      ];
      if (entradas.isNotEmpty) params['atributos'] = entradas;
    }

    return params;
  }

  /// Cuántos valores hay elegidos en total, para el contador del botón.
  int get cantidadFiltrosAtributo =>
      atributos.values.fold(0, (total, v) => total + v.length);

  /// Devuelve una copia con [valor] agregado o sacado de [clave].
  ///
  /// Las claves que se quedan sin valores se eliminan del mapa: si no, quedan
  /// entradas vacías que hacen creer que hay un filtro puesto.
  Map<String, List<String>> alternarAtributo(String clave, String valor) {
    final copia = {
      for (final e in atributos.entries) e.key: List<String>.from(e.value),
    };
    final actuales = copia.putIfAbsent(clave, () => <String>[]);
    if (actuales.contains(valor)) {
      actuales.remove(valor);
    } else {
      actuales.add(valor);
    }
    if (actuales.isEmpty) copia.remove(clave);
    return copia;
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
        mostrarTodos,
        visibleMarketplace,
        destacado,
        enOferta,
        enLiquidacion,
        stockBajo,
        soloProductos,
        soloCombos,
        esInsumo,
        soloEliminados,
        isActive,
        atributos,
        orden,
      ];
}

/// Entity que representa el resultado paginado de productos
class ProductosPaginados extends Equatable {
  final List<dynamic> data;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final int offset;
  final bool hasNext;
  final bool hasPrevious;

  /// Cache de productos completos (para evitar peticiones duplicadas al ver detalle)
  // /// Tipado como Map<String, Producto> para evitar casts inseguros en tiempo de ejecución
  final Map<String, Producto>? fullProductosCache;

  const ProductosPaginados({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.offset,
    required this.hasNext,
    required this.hasPrevious,
    this.fullProductosCache,
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
  List<Object?> get props => [data, total, page, pageSize, totalPages, offset, hasNext, hasPrevious, fullProductosCache];
}
