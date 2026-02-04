import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../domain/entities/producto_list_item.dart';
import '../bloc/producto_search/producto_search_cubit.dart';
import '../bloc/producto_search/producto_search_state.dart';
import '../widgets/producto_list_tile.dart';

/// Cache LRU simple para búsquedas recientes
class _SearchCache {
  final int maxSize;
  final Map<String, ProductoSearchLoaded> _cache = {};
  final List<String> _keys = [];

  _SearchCache({this.maxSize = 15});

  void put(String query, ProductoSearchLoaded state) {
    if (_cache.containsKey(query)) {
      // Mover al final (más reciente)
      _keys.remove(query);
      _keys.add(query);
    } else {
      // Agregar nuevo
      if (_keys.length >= maxSize) {
        // Remover el más antiguo
        final oldestKey = _keys.removeAt(0);
        _cache.remove(oldestKey);
      }
      _keys.add(query);
    }
    _cache[query] = state;
  }

  ProductoSearchLoaded? get(String query) {
    if (_cache.containsKey(query)) {
      // Mover al final (más reciente)
      _keys.remove(query);
      _keys.add(query);
      return _cache[query];
    }
    return null;
  }

  void clear() {
    _cache.clear();
    _keys.clear();
  }

  bool containsKey(String query) => _cache.containsKey(query);
}

/// SearchDelegate para búsqueda de productos
/// Estilo MercadoLibre/YouTube con sugerencias y navegación directa al detalle
/// Usa ProductoSearchCubit para manejo de estado
class ProductoSearchDelegate extends SearchDelegate<ProductoListItem?> {
  final ProductoSearchCubit searchCubit;
  final SearchHistoryService searchHistoryService;
  final String empresaId;
  final String? sedeId;

  // Debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Control de guardado de historial
  String? _lastSavedQuery;

  // Cache de últimos resultados para mostrar mientras carga
  ProductoSearchLoaded? _lastLoadedState;

  // Cache LRU de búsquedas (ESTÁTICO para persistir entre instancias)
  static final _SearchCache _searchCache = _SearchCache(maxSize: 15);

  // Query anterior para búsqueda incremental
  String _previousQuery = '';

  // Constantes
  static const double _scrollThreshold = 0.9;
  static const EdgeInsets _listPadding = EdgeInsets.all(10);
  static const EdgeInsets _headerPadding = EdgeInsets.symmetric(horizontal: 10);

  ProductoSearchDelegate({
    required this.searchCubit,
    required this.searchHistoryService,
    required this.empresaId,
    this.sedeId,
  }) : super(
          searchFieldLabel: 'Buscar productos...',
          searchFieldStyle: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        );

  /// Limpia recursos al cerrar el SearchDelegate
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Obtiene el historial de búsquedas
  List<String> _getSearchHistory() {
    return searchHistoryService.getHistory('productos');
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blue1,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
        ),
        border: InputBorder.none,
      ),

    );
  }

  /// Guarda una búsqueda en el historial
  Future<void> _saveToHistory(String query) async {
    await searchHistoryService.addToHistory('productos', query);
  }

  /// Elimina una búsqueda del historial
  Future<void> _removeFromHistory(String query) async {
    await searchHistoryService.removeFromHistory('productos', query);
  }

  /// Limpia todo el historial
  Future<void> _clearHistory() async {
    await searchHistoryService.clearHistory('productos');
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            searchCubit.clear();
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        searchCubit.clear();
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Cancelar debounce anterior
    _debounceTimer?.cancel();

    // Limpiar y normalizar query
    final trimmedQuery = query.trim();

    // Si query está vacío o solo tiene espacios, mostrar historial
    if (trimmedQuery.isEmpty) {
      return _buildSearchHistory(context);
    }

    // Normalizar espacios múltiples a uno solo
    final normalizedQuery = trimmedQuery.replaceAll(RegExp(r'\s+'), ' ');

    // Verificar cache primero (búsqueda instantánea)
    final cachedResult = _searchCache.get(normalizedQuery);
    bool skipServerRequest = false;

    if (cachedResult != null) {
      // Tenemos resultado en cache, mostrarlo inmediatamente
      _lastLoadedState = cachedResult;
      skipServerRequest = true; // No hacer petición al servidor
    } else {
      // Búsqueda incremental: si el query nuevo contiene el anterior
      if (normalizedQuery.startsWith(_previousQuery) &&
          _previousQuery.isNotEmpty &&
          _lastLoadedState != null &&
          _lastLoadedState!.hasResults) {
        // Filtrar resultados locales del query anterior
        final filteredResults = _lastLoadedState!.productos.where((producto) {
          final searchText = '${producto.nombre} ${producto.codigoEmpresa} ${producto.categoriaNombre ?? ''} ${producto.marcaNombre ?? ''}'.toLowerCase();
          return searchText.contains(normalizedQuery.toLowerCase());
        }).toList();

        // Crear estado temporal con resultados filtrados
        _lastLoadedState = ProductoSearchLoaded(
          productos: filteredResults,
          query: normalizedQuery,
          currentPage: 1,
          totalResults: filteredResults.length,
          hasMore: false,
          productosCache: _lastLoadedState!.productosCache,
        );
        // Mostrar resultados filtrados inmediatamente, pero sí hacer petición al servidor
        // para obtener resultados más precisos del backend
      }
    }

    // Guardar query actual para búsqueda incremental
    _previousQuery = normalizedQuery;

    // Realizar búsqueda real con debouncing SOLO si no hay cache exacto
    // Si hay cache exacto, NO hacemos petición
    // Si hay filtrado incremental, SÍ hacemos petición para resultados precisos del servidor
    if (!skipServerRequest) {
      _debounceTimer = Timer(_debounceDuration, () {
        searchCubit.search(
          query: normalizedQuery,
          empresaId: empresaId,
          sedeId: sedeId,
        );
      });
    }

    // Usar BlocBuilder para escuchar cambios de estado
    return BlocBuilder<ProductoSearchCubit, ProductoSearchState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is ProductoSearchLoading) {
          // Si hay resultados previos (cache o filtrados), mostrarlos con indicador
          if (_lastLoadedState != null && _lastLoadedState!.hasResults) {
            return _buildResultsWithLoadingIndicator(context, _lastLoadedState!);
          }
          // Sin resultados previos, mostrar loading sutil
          return _buildSubtleLoadingState(context);
        }

        if (state is ProductoSearchLoaded) {
          // Guardar en cache para búsquedas futuras
          _searchCache.put(normalizedQuery, state);
          // Guardar estado para uso posterior
          _lastLoadedState = state;
          return _buildResultsList(context, state);
        }

        if (state is ProductoSearchError) {
          return _buildErrorState(context, state.message);
        }

        // Si tenemos resultados en cache o filtrados, mostrarlos
        if (_lastLoadedState != null && _lastLoadedState!.hasResults) {
          return _buildResultsList(context, _lastLoadedState!);
        }

        // Estado inicial sin resultados
        return _buildEmptyState(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Limpiar y normalizar query
    final trimmedQuery = query.trim();
    final normalizedQuery = trimmedQuery.replaceAll(RegExp(r'\s+'), ' ');

    // Verificar cache primero
    final cachedResult = _searchCache.get(normalizedQuery);
    if (cachedResult != null) {
      _lastLoadedState = cachedResult;
    }

    // Realizar búsqueda inmediata si el query cambió
    if (normalizedQuery.isNotEmpty && normalizedQuery != searchCubit.currentQuery) {
      searchCubit.search(
        query: normalizedQuery,
        empresaId: empresaId,
        sedeId: sedeId,
      );
    }

    return BlocBuilder<ProductoSearchCubit, ProductoSearchState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is ProductoSearchLoading) {
          // Si hay resultados previos, mostrarlos con indicador de carga
          if (_lastLoadedState != null && _lastLoadedState!.hasResults) {
            return _buildResultsWithLoadingIndicator(context, _lastLoadedState!);
          }
          // Sin resultados previos, mostrar loading sutil
          return _buildSubtleLoadingState(context);
        }

        if (state is ProductoSearchLoaded) {
          // Guardar en cache para búsquedas futuras
          _searchCache.put(normalizedQuery, state);
          // Guardar estado para uso posterior
          _lastLoadedState = state;
          // Guardar en historial SOLO si hay resultados y es una búsqueda confirmada
          final trimmedQuery = query.trim();
          final normalizedForHistory = trimmedQuery.replaceAll(RegExp(r'\s+'), ' ');
          if (state.hasResults &&
              normalizedForHistory.isNotEmpty &&
              _lastSavedQuery != normalizedForHistory) {
            _lastSavedQuery = normalizedForHistory;
            _saveToHistory(normalizedForHistory);
          }
          return _buildResultsList(context, state);
        }

        if (state is ProductoSearchLoadingMore) {
          return _buildResultsList(
            context,
            ProductoSearchLoaded(
              productos: state.currentResults,
              query: query,
              currentPage: state.currentPage,
              totalResults: state.currentResults.length,
              hasMore: state.hasMore,
            ),
            isLoadingMore: true,
          );
        }

        if (state is ProductoSearchError) {
          return _buildErrorState(context, state.message);
        }

        return _buildEmptyState(context);
      },
    );
  }

  /// Widget para mostrar el historial de búsquedas
  Widget _buildSearchHistory(BuildContext context) {
    final searchHistory = _getSearchHistory();

    if (searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppColors.blue1.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            AppSubtitle(
              'Busca productos por nombre, SKU o código',
              color: AppColors.blue1.withOpacity(0.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con "Limpiar historial"
        Padding(
          padding: _headerPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSubtitle(
                'Búsquedas recientes',
                color: AppColors.blue1.withOpacity(0.7),
              ),
              TextButton.icon(
                onPressed: () {
                  _clearHistory().then((_) {
                    if (context.mounted) {
                      showSuggestions(context);
                    }
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                ),
              ),
            ],
          ),
        ),
        // Lista de búsquedas recientes
        Expanded(
          child: ListView.builder(
            itemCount: searchHistory.length,
            itemBuilder: (context, index) {
              final searchTerm = searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: AppColors.blue1),
                title: AppSubtitle(searchTerm),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.blue1.withOpacity(0.5),
                  ),
                  onPressed: () {
                    _removeFromHistory(searchTerm).then((_) {
                      if (context.mounted) {
                        showSuggestions(context);
                      }
                    });
                  },
                ),
                onTap: () {
                  query = searchTerm;
                  showResults(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Widget para mostrar la lista de resultados
  Widget _buildResultsList(
    BuildContext context,
    ProductoSearchLoaded state, {
    bool isLoadingMore = false,
  }) {
    if (state.isEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Center(
          key: const ValueKey('empty'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.blue1.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              AppSubtitle(
                'No se encontraron productos',
                color: AppColors.blue1.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              AppSubtitle(
                'Intenta con otros términos de búsqueda',
                color: AppColors.blue1.withOpacity(0.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: NotificationListener<ScrollNotification>(
        key: ValueKey('results_${state.query}_${state.productos.length}'),
      onNotification: (scrollInfo) {
        // Cargar más al llegar al final
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * _scrollThreshold) {
          if (state.hasMore && !isLoadingMore) {
            searchCubit.loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: _listPadding,
        itemCount: state.productos.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Indicador de carga al final
          if (index == state.productos.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CustomLoading(
              message: 'Cargando...',
            ),
              ),
            );
          }

          final producto = state.productos[index];

          return ProductoListTile(
            producto: producto,
            sedeId: sedeId ?? '',
            onTap: () {
              // Cerrar búsqueda y navegar al detalle
              _navigateToDetail(context, producto);
            },
            // Deshabilitar acciones en búsqueda
            onManageFiles: null,
            onViewVariants: null,
            onStockDoubleTap: null,
            onPrecioTap: null,
          );
        },
      ),
      ),
    );
  }

  /// Widget para mostrar resultados con indicador de carga sutil
  Widget _buildResultsWithLoadingIndicator(
    BuildContext context,
    ProductoSearchLoaded state,
  ) {
    return Column(
      children: [
        // Indicador de carga sutil en la parte superior con animación
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.blue1.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue1.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue1),
                ),
              ),
              const SizedBox(width: 12),
              AppSubtitle(
                'Actualizando resultados...',
                color: AppColors.blue1,
                fontSize: 12,
              ),
            ],
          ),
        ),
        // Lista de resultados anteriores con fade
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 0.7, // Hacer los resultados un poco transparentes
            child: _buildResultsList(context, state),
          ),
        ),
      ],
    );
  }

  /// Widget para loading sutil sin resultados previos
  Widget _buildSubtleLoadingState(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: 1.0,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue1),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: AlwaysStoppedAnimation(0.7),
              child: AppSubtitle(
                'Buscando productos...',
                color: AppColors.blue1.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para estado vacío
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.blue1.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          AppSubtitle(
            'Escribe para buscar productos',
            color: AppColors.blue1.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// Widget para estado de error
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          AppSubtitle(
            'Error al buscar',
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AppSubtitle(
              message,
              color: AppColors.blue1.withOpacity(0.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              searchCubit.search(
                query: query,
                empresaId: empresaId,
                sedeId: sedeId,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Navega al detalle del producto
  void _navigateToDetail(BuildContext context, ProductoListItem producto) {
    // Guardar búsqueda exitosa en el historial (normalizada)
    final trimmedQuery = query.trim();
    final normalizedQuery = trimmedQuery.replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedQuery.isNotEmpty && _lastSavedQuery != normalizedQuery) {
      _lastSavedQuery = normalizedQuery;
      _saveToHistory(normalizedQuery);
    }

    // Obtener producto completo del cache si existe
    final productoCompleto = searchCubit.getProductoFromCache(producto.id);

    // Cerrar el SearchDelegate
    close(context, producto);

    // Navegar al detalle
    context.pushNamed(
      'empresa-productos-detail',
      pathParameters: {'id': producto.id},
      queryParameters: sedeId != null ? {'sedeId': sedeId!} : {},
      extra: productoCompleto, // Pasar producto del cache si existe
    );
  }
}

