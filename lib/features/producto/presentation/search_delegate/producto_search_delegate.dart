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

/// SearchDelegate para búsqueda de productos
/// Estilo MercadoLibre/YouTube con sugerencias y navegación directa al detalle
/// Usa ProductoSearchCubit para manejo de estado
class ProductoSearchDelegate extends SearchDelegate<ProductoListItem?> {
  final ProductoSearchCubit searchCubit;
  final SearchHistoryService searchHistoryService;
  final String empresaId;
  final String? sedeId;

  // Historial de búsquedas
  List<String> _searchHistory = [];

  // Debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

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
        ) {
    _loadSearchHistory();
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

  /// Carga el historial de búsquedas
  void _loadSearchHistory() {
    _searchHistory = searchHistoryService.getHistory('productos');
  }

  /// Guarda una búsqueda en el historial
  Future<void> _saveToHistory(String query) async {
    await searchHistoryService.addToHistory('productos', query);
    _searchHistory = searchHistoryService.getHistory('productos');
  }

  /// Elimina una búsqueda del historial
  Future<void> _removeFromHistory(String query) async {
    await searchHistoryService.removeFromHistory('productos', query);
    _searchHistory = searchHistoryService.getHistory('productos');
  }

  /// Limpia todo el historial
  Future<void> _clearHistory() async {
    await searchHistoryService.clearHistory('productos');
    _searchHistory = [];
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

    // Si query está vacío, mostrar historial
    if (query.isEmpty) {
      return _buildSearchHistory(context);
    }

    // Realizar búsqueda con debouncing
    _debounceTimer = Timer(_debounceDuration, () {
      searchCubit.search(
        query: query,
        empresaId: empresaId,
        sedeId: sedeId,
      );
    });

    // Usar BlocBuilder para escuchar cambios de estado
    return BlocBuilder<ProductoSearchCubit, ProductoSearchState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is ProductoSearchLoading) {
          return const Center(
            child: CustomLoading(
              message: 'Cargando...',
            ),
          );
        }

        if (state is ProductoSearchLoaded) {
          // Guardar en historial si hay resultados
          if (state.hasResults) {
            _saveToHistory(state.query);
          }

          return _buildResultsList(context, state);
        }

        if (state is ProductoSearchError) {
          return _buildErrorState(context, state.message);
        }

        // Estado inicial o sin resultados previos
        return _buildEmptyState(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Realizar búsqueda inmediata si el query cambió
    if (query.trim().isNotEmpty && query != searchCubit.currentQuery) {
      searchCubit.search(
        query: query,
        empresaId: empresaId,
        sedeId: sedeId,
      );
    }

    return BlocBuilder<ProductoSearchCubit, ProductoSearchState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is ProductoSearchLoading) {
          return const Center(
            child: CustomLoading(
              message: 'Cargando...',
            ),
          );
        }

        if (state is ProductoSearchLoaded) {
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
    if (_searchHistory.isEmpty) {
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
          padding: const EdgeInsets.only(right: 10, left: 10),
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
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final searchTerm = _searchHistory[index];
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
      return Center(
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
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // Cargar más al llegar al final
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
          if (state.hasMore && !isLoadingMore) {
            searchCubit.loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
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
