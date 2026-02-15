import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/widgets/custom_sede_selector.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/custom_navigation_menu.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
// import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import '../../domain/entities/producto_filtros.dart';
import '../../domain/entities/producto_list_item.dart';
import '../../domain/entities/producto.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/usecases/get_producto_usecase.dart';
import '../../domain/usecases/get_stock_producto_en_sede_usecase.dart';
import '../bloc/producto_list/producto_list_cubit.dart';
import '../bloc/producto_list/producto_list_state.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../bloc/agregar_stock_inicial/agregar_stock_inicial_cubit.dart';
import '../bloc/sede_selection/sede_selection_cubit.dart';
import '../bloc/sede_selection/sede_selection_state.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../widgets/producto_list_tile.dart';
// import '../widgets/filtros_productos_widget.dart';
import '../widgets/archivo_manager_bottom_sheet.dart';
import '../widgets/producto_variantes_bottom_sheet.dart';
import '../widgets/seleccionar_sede_stock_bottom_sheet.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/configurar_precios_dialog.dart';
import '../../../../core/services/storage_service.dart';
// import '../../../../core/services/search_history_service.dart';
import '../../../../core/di/injection_container.dart';
// Imports para páginas de inventario/stock
import 'stock_por_sede_page.dart';
import 'alertas_stock_bajo_page.dart';
import 'transferencias_stock_page.dart';
import 'agregar_stock_inicial_page.dart';
// Import para SearchDelegate
// import '../search_delegate/producto_search_delegate.dart';
import '../bloc/producto_search/producto_search_cubit.dart';
import '../bloc/producto_search/producto_search_state.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late TabController _tabController;
  late ProductoSearchCubit _searchCubit;
  final ProductoFiltros _filtros = const ProductoFiltros();
  String? _currentEmpresaId;
  String _searchQuery = '';
  bool _useServerSearch = false; // Controla si usar búsqueda en servidor

  // Enum para los tipos de tab
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchCubit = locator<ProductoSearchCubit>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadProductos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _searchCubit.clear();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _loadProductos();
    }
  }

  void _loadProductos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;

      // Obtener sede seleccionada o usar la principal
      final sedeId = _getSedeIdActual(empresaState.context.sedes);

      // Aplicar filtro según el tab actual
      ProductoFiltros filtrosConTab = _filtros;

      switch (_currentTabIndex) {
        case 0: // Todos
          filtrosConTab = _filtros.copyWith(
            clearSoloProductos: true,
            clearSoloCombos: true,
          );
          break;
        case 1: // Productos
          filtrosConTab = _filtros.copyWith(
            soloProductos: true,
            clearSoloCombos: true,
          );
          break;
        case 2: // Combos
          filtrosConTab = _filtros.copyWith(
            clearSoloProductos: true,
            soloCombos: true,
          );
          break;
      }

      context.read<ProductoListCubit>().loadProductos(
        empresaId: empresaState.context.empresa.id,
        sedeId: sedeId,
        filtros: filtrosConTab,
      );
    }
  }

  /// Obtiene el sedeId actual (seleccionado o por defecto)
  /// Siempre retorna un sedeId válido, ya que ProductoStock requiere sede
  String _getSedeIdActual(List<dynamic> sedes) {
    // Si no hay sedes, esto es un error crítico del sistema
    if (sedes.isEmpty) {
      throw Exception('No hay sedes disponibles');
    }

    // Obtener sede seleccionada del cubit
    final selectedSedeId = context.read<SedeSelectionCubit>().selectedSedeId;

    // Si hay una sede seleccionada y es válida, usarla
    if (selectedSedeId != null && sedes.any((s) => s.id == selectedSedeId)) {
      return selectedSedeId;
    }

    // Si solo hay una sede, usarla automáticamente
    if (sedes.length == 1) {
      return sedes.first.id;
    }

    // Si hay múltiples sedes, usar la principal
    try {
      final sedePrincipal = sedes.firstWhere((s) => s.esPrincipal);
      return sedePrincipal.id;
    } catch (e) {
      // Si no hay sede principal, usar la primera
      return sedes.first.id;
    }
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductoListCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  // void _applyFiltros(ProductoFiltros filtros) {
  //   setState(() {
  //     _filtros = filtros;
  //   });
  //   _loadProductos();
  // }

  /// Maneja el cambio de sede
  Future<void> _onSedeChanged(String sedeId) async {
    // Esperar a que se actualice la sede seleccionada
    await context.read<SedeSelectionCubit>().selectSede(sedeId);

    if (!mounted) return;

    // Limpiar el estado actual antes de cargar productos de la nueva sede
    context.read<ProductoListCubit>().clear();
    _loadProductos();
  }

  // void _showFiltros() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => FiltrosProductosWidget(
  //       filtrosActuales: _filtros,
  //       onApply: _applyFiltros,
  //     ),
  //   );
  // }

  /// Abre el SearchDelegate para buscar productos
  /// COMENTADO - Se usará para marketplace en el futuro
  // void _openSearch() {
  //   final empresaState = context.read<EmpresaContextCubit>().state;
  //   if (empresaState is! EmpresaContextLoaded) return;
  //
  //   final sedeState = context.read<SedeSelectionCubit>().state;
  //   final sedeId = sedeState is SedeSelected ? sedeState.sedeId : null;
  //
  //   showSearch(
  //     context: context,
  //     delegate: ProductoSearchDelegate(
  //       searchCubit: locator<ProductoSearchCubit>(),
  //       searchHistoryService: locator<SearchHistoryService>(),
  //       empresaId: empresaState.context.empresa.id,
  //       sedeId: sedeId,
  //     ),
  //   );
  // }

  /// Filtrado local de productos por búsqueda
  /// Si no hay resultados locales, automáticamente busca en servidor
  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _searchQuery = query.toLowerCase();
      _useServerSearch = false; // Inicialmente búsqueda local
    });

    // Si el query es muy corto, no buscar en servidor
    if (query.length < 3) {
      _searchCubit.clear();
      return;
    }

    // Verificar si hay resultados locales
    final productoListState = context.read<ProductoListCubit>().state;
    if (productoListState is ProductoListLoaded) {
      final productosLocales = productoListState.productos.where((producto) {
        final searchText =
            '${producto.nombre} ${producto.codigoEmpresa} ${producto.categoriaNombre ?? ''} ${producto.marcaNombre ?? ''}'
                .toLowerCase();
        return searchText.contains(_searchQuery);
      }).toList();

      // Si NO hay resultados locales, buscar automáticamente en servidor
      if (productosLocales.isEmpty && query.isNotEmpty) {
        _triggerServerSearch(query);
      } else {
        // Hay resultados locales, limpiar búsqueda de servidor
        _searchCubit.clear();
      }
    }
  }

  /// Dispara búsqueda en servidor (automática o manual)
  void _triggerServerSearch(String query) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final sedeState = context.read<SedeSelectionCubit>().state;
    final sedeId = sedeState is SedeSelected ? sedeState.sedeId : null;

    setState(() {
      _useServerSearch = true;
    });

    _searchCubit.search(
      query: query,
      empresaId: empresaState.context.empresa.id,
      sedeId: sedeId,
    );
  }

  /// Búsqueda en servidor (al presionar Enter - fuerza búsqueda)
  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _useServerSearch = false;
      });
      _searchCubit.clear();
      return;
    }

    // Forzar búsqueda en servidor
    _triggerServerSearch(query);
  }

  Future<void> _showArchivoManager(
    String productoId,
    String productoNombre,
  ) async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    try {
      // Obtener archivos existentes del producto
      final storageService = locator<StorageService>();
      final archivosResponse = await storageService.getFilesByEntity(
        empresaId: empresaState.context.empresa.id,
        entidadTipo: 'PRODUCTO',
        entidadId: productoId,
      );

      // Convertir a ArchivoItem
      final archivosExistentes = archivosResponse.map((archivo) {
        TipoArchivo tipo;
        if (archivo.mimeType.startsWith('image/')) {
          tipo = TipoArchivo.imagen;
        } else if (archivo.mimeType == 'application/pdf') {
          tipo = TipoArchivo.pdf;
        } else {
          tipo = TipoArchivo.otro;
        }

        return ArchivoItem(
          id: archivo.id,
          url: archivo.url,
          urlThumbnail: archivo.urlThumbnail,
          nombreOriginal: archivo.nombreOriginal,
          tipoArchivo: tipo,
          isLocal: false,
        );
      }).toList();

      if (!mounted) return;

      // Mostrar bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ArchivoManagerBottomSheet(
          entidadId: productoId,
          entidadNombre: productoNombre,
          entidadTipo: 'PRODUCTO',
          empresaId: empresaState.context.empresa.id,
          storageService: storageService,
          archivosExistentes: archivosExistentes,
        ),
      );

      // Recargar lista de productos para actualizar imágenes
      if (mounted) {
        _loadProductos();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar archivos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVariantes(String productoId, String productoNombre) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    ProductoVariantesBottomSheet.show(
      context: context,
      productoId: productoId,
      empresaId: empresaState.context.empresa.id,
      productoNombre: productoNombre,
    );
  }

  Future<void> _handleStockDoubleTap(ProductoListItem producto) async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;

    // Caso 1: No tiene stock en ninguna sede - Agregar stock inicial
    if (producto.stockTotal == 0) {
      try {
        // Obtener el producto completo
        final getProductoUseCase = locator<GetProductoUseCase>();
        final result = await getProductoUseCase(
          productoId: producto.id,
          empresaId: empresaId,
        );

        if (!mounted) return;

        if (result is Success<Producto>) {
          final productoCompleto = result.data;
          // Navegar a la página de agregar stock inicial
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => locator<AgregarStockInicialCubit>(),
                  ),
                  BlocProvider.value(
                    value: context.read<EmpresaContextCubit>(),
                  ),
                  BlocProvider.value(value: context.read<SedeListCubit>()),
                ],
                child: AgregarStockInicialPage(producto: productoCompleto),
              ),
            ),
          ).then((result) {
            // Si se agregó stock, recargar la lista
            if (result == true && mounted) {
              _loadProductos();
            }
          });
        } else if (result is Error<Producto>) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar producto: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Caso 2: Tiene stock en una o más sedes
    final stocksPorSede = producto.stocksPorSede ?? [];

    if (stocksPorSede.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay información de stock por sede'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Caso 2a: Stock en una sola sede - Abrir dialog directamente
    if (stocksPorSede.length == 1) {
      final stockSede = stocksPorSede.first;
      await _openAjustarStockDialog(
        productoId: producto.id,
        sedeId: stockSede.sedeId,
        empresaId: empresaId,
      );
      return;
    }

    // Caso 2b: Stock en múltiples sedes - Mostrar selector
    final sedeSeleccionada = await SeleccionarSedeStockBottomSheet.show(
      context: context,
      stocksPorSede: stocksPorSede,
      productoNombre: producto.nombre,
    );

    if (sedeSeleccionada != null && mounted) {
      await _openAjustarStockDialog(
        productoId: producto.id,
        sedeId: sedeSeleccionada.sedeId,
        empresaId: empresaId,
      );
    }
  }

  Future<void> _openAjustarStockDialog({
    required String productoId,
    required String sedeId,
    required String empresaId,
  }) async {
    try {
      // Obtener el ProductoStock completo
      final getStockUseCase = locator<GetStockProductoEnSedeUseCase>();
      final result = await getStockUseCase(
        productoId: productoId,
        sedeId: sedeId,
      );

      if (!mounted) return;

      if (result is Success<ProductoStock>) {
        final stock = result.data;
        // Mostrar el dialog de ajustar stock
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider(
            create: (_) => locator<AjustarStockCubit>(),
            child: AjustarStockDialog(stock: stock, empresaId: empresaId),
          ),
        ).then((result) {
          // Si se ajustó correctamente, recargar la lista
          if (result == true && mounted) {
            _loadProductos();
          }
        });
      } else if (result is Error<ProductoStock>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Maneja el tap en el botón de configurar precios
  Future<void> _handlePrecioTap(ProductoListItem producto) async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;
    final sedeId = _getSedeIdActual(empresaState.context.sedes);

    try {
      // Obtener el ProductoStock completo para esta sede
      final getStockUseCase = locator<GetStockProductoEnSedeUseCase>();
      final result = await getStockUseCase(
        productoId: producto.id,
        sedeId: sedeId,
      );

      if (!mounted) return;

      if (result is Success<ProductoStock>) {
        final stock = result.data;

        // Mostrar el diálogo de configuración de precios
        showDialog(
          context: context,
          builder: (dialogContext) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => locator<ConfigurarPreciosCubit>()),
            ],
            child: ConfigurarPreciosDialog(stock: stock, empresaId: empresaId),
          ),
        ).then((result) {
          // Si se guardaron los precios correctamente, recargar la lista
          if (result == true && mounted) {
            _loadProductos();
          }
        });
      } else if (result is Error<ProductoStock>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          // Solo recargar si realmente cambió la empresa
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            // Cuando cambia la empresa, limpiar el estado de productos y recargar
            context.read<ProductoListCubit>().clear();
            _loadProductos();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Hacer el scaffold transparente
        extendBodyBehindAppBar: true, // Extender el body detrás del AppBar
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          title: 'Productos',
          centerTitle: false,
          actions: [
            // Selector de sede (solo si hay más de una)
            _buildSedeSelector(),
            // Menú de inventario
            CustomNavigationMenu(
              triggerIcon: Icons.inventory_2_outlined,
              triggerIconSize: 14,
              triggerIconColor: AppColors.white,
              tooltip: 'Inventario',
              menuWidth: 220,
              items: [
                NavigationMenuItem(
                  id: 'stock_por_sede',
                  label: 'Stock por Sede',
                  icon: Icons.warehouse,
                  iconColor: AppColors.blue1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StockPorSedePage(),
                      ),
                    );
                  },
                ),
                NavigationMenuItem(
                  id: 'alertas',
                  label: 'Alertas de Stock',
                  icon: Icons.warning,
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlertasStockBajoPage(),
                      ),
                    );
                  },
                ),
                NavigationMenuItem(
                  id: 'transferencias',
                  label: 'Transferencias entre Sedes',
                  icon: Icons.sync_alt,
                  iconColor: AppColors.blue1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransferenciasStockPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            // IconButton(
            //   icon: const Icon(Icons.filter_list, size: 18),
            //   onPressed: _showFiltros,
            //   tooltip: 'Filtros',
            // ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadProductos,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 40, // Mismo height que antes
                  color: AppColors
                      .blue1, // O el color de tu gradient si quieres seamless
                  child: TabBar(
                    controller: _tabController,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    dividerHeight: 0,
                    labelColor: AppColors.white,
                    unselectedLabelColor: Colors.grey,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    indicatorPadding: const EdgeInsets.only(bottom: 10),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 2,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 2, color: AppColors.white),
                    ),
                    tabs: const [
                      Tab(text: 'TODOS'),
                      Tab(text: 'PRODUCTOS'),
                      Tab(text: 'COMBOS'),
                    ],
                  ),
                ),

                SizedBox(height: 15),
                _buildSearchBar(),
                const SizedBox(height: 8),
                Expanded(child: _buildProductList()),
              ],
            ),
          ),
        ),
        floatingActionButton:
            BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
              builder: (context, state) {
                if (state is EmpresaContextLoaded &&
                    state.context.permissions.canManageProducts) {
                  return FloatingButtonIcon(
                    onPressed: () {
                      context.push('/empresa/productos/nuevo');
                    },
                    icon: Icons.add,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, left: 10),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar producto...',
        borderColor: AppColors.blue1,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        onClear: () {
          setState(() {
            _searchQuery = '';
            _useServerSearch = false;
          });
          _searchCubit.clear();
        },
      ),
    );
  }

  Widget _buildProductList() {
    // Si está usando búsqueda en servidor, mostrar resultados del SearchCubit
    if (_useServerSearch) {
      return BlocBuilder<ProductoSearchCubit, ProductoSearchState>(
        bloc: _searchCubit,
        builder: (context, searchState) {
          if (searchState is ProductoSearchLoading) {
            return CustomLoading.small(message: 'Buscando en servidor...');
          }

          if (searchState is ProductoSearchError) {
            return _buildErrorView(searchState.message);
          }

          if (searchState is ProductoSearchLoaded) {
            final productos = searchState.productos;

            if (productos.isEmpty) {
              return _buildEmptySearchView();
            }

            return _buildProductListView(
              productos,
              hasMore: searchState.hasMore,
            );
          }

          return _buildEmptyView();
        },
      );
    }

    // Búsqueda local en productos ya cargados
    return BlocBuilder<ProductoListCubit, ProductoListState>(
      builder: (context, state) {
        if (state is ProductoListLoading) {
          return CustomLoading.small(message: 'Cargando productos...');
        }

        if (state is ProductoListError) {
          return _buildErrorView(state.message);
        }

        if (state is ProductoListLoaded) {
          // Filtrar productos por búsqueda local
          final productos = _searchQuery.isEmpty
              ? state.productos
              : state.productos.where((producto) {
                  final searchText =
                      '${producto.nombre} ${producto.codigoEmpresa} ${producto.categoriaNombre ?? ''} ${producto.marcaNombre ?? ''}'
                          .toLowerCase();
                  return searchText.contains(_searchQuery);
                }).toList();

          if (productos.isEmpty) {
            return _buildEmptyLocalSearchView();
          }

          return _buildProductListView(productos, hasMore: state.hasMore);
        }

        if (state is ProductoListLoadingMore) {
          final productos = state.currentProducts;

          return RefreshIndicator(
            onRefresh: () async {
              _loadProductos();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: productos.length + 1,
              itemBuilder: (context, index) {
                if (index >= productos.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final producto = productos[index];
                final empresaContext = context
                    .read<EmpresaContextCubit>()
                    .state;

                // Si no hay empresa cargada, no renderizar el tile
                if (empresaContext is! EmpresaContextLoaded) {
                  return const SizedBox.shrink();
                }

                final sedeId = _getSedeIdActual(empresaContext.context.sedes);

                return ProductoListTile(
                  producto: producto,
                  sedeId: sedeId,
                  onTap: () async {
                    // Navegar a la página correcta según el tipo
                    if (producto.esCombo) {
                      context.push(
                        '/empresa/combos/${producto.id}?empresaId=${empresaContext.context.empresa.id}',
                      );
                    } else {
                      // Intentar obtener el producto completo del cache (evita petición duplicada)
                      final productoCompleto = context
                          .read<ProductoListCubit>()
                          .getProductoFromCache(producto.id);

                      // Esperar el resultado del detalle
                      final result = await context.push(
                        '/empresa/productos/${producto.id}?sedeId=$sedeId',
                        extra:
                            productoCompleto, // ✅ Pasar producto completo del cache
                      );

                      // ✅ Si retorna true (producto fue editado), recargar la lista
                      if (result == true && mounted) {
                        _loadProductos();
                      }
                    }
                  },
                  onManageFiles: () =>
                      _showArchivoManager(producto.id, producto.nombre),
                  onViewVariants: producto.tieneVariantes
                      ? () => _showVariantes(producto.id, producto.nombre)
                      : null,
                  onStockDoubleTap: () => _handleStockDoubleTap(producto),
                  onPrecioTap: () => _handlePrecioTap(producto),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay productos',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer producto',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLocalSearchView() {
    // Este widget ya no debería mostrarse porque automáticamente
    // busca en servidor cuando no hay resultados locales
    // Pero lo dejamos por si acaso (queries muy cortos < 3 caracteres)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No se encontró "$_searchQuery"',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe al menos 3 caracteres para buscar',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'para "$_searchQuery"',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductListView(
    List<ProductoListItem> productos, {
    bool hasMore = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_useServerSearch) {
          _onSearchSubmitted(_searchController.text);
        } else {
          _loadProductos();
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: productos.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= productos.length) {
            // Cargar más productos del servidor si es búsqueda en servidor
            if (_useServerSearch && hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchCubit.loadMore();
              });
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final producto = productos[index];
          final empresaContext = context.read<EmpresaContextCubit>().state;

          if (empresaContext is! EmpresaContextLoaded) {
            return const SizedBox.shrink();
          }

          final sedeId = _getSedeIdActual(empresaContext.context.sedes);

          return ProductoListTile(
            producto: producto,
            sedeId: sedeId,
            onTap: () async {
              if (producto.esCombo) {
                context.push(
                  '/empresa/combos/${producto.id}?empresaId=${empresaContext.context.empresa.id}',
                );
              } else {
                final productoCompleto = _useServerSearch
                    ? _searchCubit.getProductoFromCache(producto.id)
                    : context.read<ProductoListCubit>().getProductoFromCache(
                        producto.id,
                      );

                final result = await context.push(
                  '/empresa/productos/${producto.id}?sedeId=$sedeId',
                  extra: productoCompleto,
                );

                if (result == true && mounted) {
                  if (_useServerSearch) {
                    _onSearchSubmitted(_searchController.text);
                  } else {
                    _loadProductos();
                  }
                }
              }
            },
            onManageFiles: () =>
                _showArchivoManager(producto.id, producto.nombre),
            onViewVariants: producto.tieneVariantes
                ? () => _showVariantes(producto.id, producto.nombre)
                : null,
            onStockDoubleTap: () => _handleStockDoubleTap(producto),
            onPrecioTap: () => _handlePrecioTap(producto),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProductos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el selector de sede
  /// Solo se muestra si hay más de una sede disponible
  Widget _buildSedeSelector() {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        // Si no hay empresa cargada, no mostrar selector
        if (empresaState is! EmpresaContextLoaded) {
          return const SizedBox.shrink();
        }

        final sedes = empresaState.context.sedes;

        // Si solo hay una sede o ninguna, no mostrar selector
        if (sedes.length <= 1) return const SizedBox.shrink();

        return BlocBuilder<SedeSelectionCubit, SedeSelectionState>(
          builder: (context, sedeState) {
            // Obtener el sedeId actual
            final sedeIdActual = _getSedeIdActual(sedes);

            // Buscar la sede actual
            dynamic sedeActual;
            try {
              sedeActual = sedes.firstWhere((s) => s.id == sedeIdActual);
            } catch (e) {
              sedeActual = sedes.first;
            }
            return Tooltip(
              message: 'Cambiar sede',
              child: CustomSedeSelector(
                sedes: sedes,
                currentSede: sedeActual,
                onSelected: _onSedeChanged,
                // Opcional: personaliza si quieres
                // menuWidth: 280,
                // borderRadius: 16,
              ),
            );
          },
        );
      },
    );
  }
}
