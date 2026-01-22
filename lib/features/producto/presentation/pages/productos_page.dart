import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
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
import '../widgets/producto_list_tile.dart';
import '../widgets/filtros_productos_widget.dart';
import '../widgets/archivo_manager_bottom_sheet.dart';
import '../widgets/producto_variantes_bottom_sheet.dart';
import '../widgets/seleccionar_sede_stock_bottom_sheet.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/di/injection_container.dart';
// Imports para páginas de inventario/stock
import 'stock_por_sede_page.dart';
import 'alertas_stock_bajo_page.dart';
import 'transferencias_stock_page.dart';
import 'agregar_stock_inicial_page.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;
  ProductoFiltros _filtros = const ProductoFiltros();
  String? _currentEmpresaId;

  // Timer para debouncing de búsqueda
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Variable para controlar la visibilidad del botón clear
  String _searchText = '';

  // Enum para los tipos de tab
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    // Sincronizar estado del texto de búsqueda
    _searchText = _searchController.text;
    _loadProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
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
        filtros: filtrosConTab,
      );
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

  void _applyFiltros(ProductoFiltros filtros) {
    setState(() {
      _filtros = filtros;
    });
    _loadProductos();
  }

  void _onSearchChanged(String value) {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    // Actualizar UI inmediatamente (para mostrar/ocultar botón clear)
    setState(() {
      _searchText = value;
    });

    // Si el campo está vacío, aplicar filtros inmediatamente sin debounce
    if (value.isEmpty) {
      _applyFiltros(_filtros.copyWith(clearSearch: true));
      return;
    }

    // Si tiene contenido, usar debouncing para evitar requests excesivas
    _debounceTimer = Timer(_debounceDuration, () {
      _applyFiltros(_filtros.copyWith(search: value));
    });
  }

  void _showFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltrosProductosWidget(
        filtrosActuales: _filtros,
        onApply: _applyFiltros,
      ),
    );
  }

  Future<void> _showArchivoManager(String productoId, String productoNombre) async {
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
                  BlocProvider.value(
                    value: context.read<SedeListCubit>(),
                  ),
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
            child: AjustarStockDialog(
              stock: stock,
              empresaId: empresaId,
            ),
          ),
        ).then((result) {
          // Si se ajustó correctamente, recargar la lista
          if (result == true && mounted) {
            _loadProductos();
          }
        });
      } else if (result is Error<ProductoStock>) {
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
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
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
          showLogo: false,
          title: 'Productos',
          actions: [
            // Menú de inventario
            PopupMenuButton<String>(
              icon: const Icon(Icons.inventory_2, size: 18),
              tooltip: 'Inventario',
              onSelected: (value) {
                if (value == 'stock_por_sede') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StockPorSedePage(),
                    ),
                  );
                } else if (value == 'alertas') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AlertasStockBajoPage(),
                    ),
                  );
                } else if (value == 'transferencias') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransferenciasStockPage(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'stock_por_sede',
                  child: Row(
                    children: [
                      Icon(Icons.warehouse, size: 18),
                      SizedBox(width: 8),
                      Text('Stock por Sede'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'alertas',
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 18),
                      SizedBox(width: 8),
                      Text('Alertas de Stock'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'transferencias',
                  child: Row(
                    children: [
                      Icon(Icons.sync_alt, size: 18),
                      SizedBox(width: 8),
                      Text('Transferencias entre Sedes'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, size: 18),
              onPressed: _showFiltros,
              tooltip: 'Filtros',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadProductos,
              tooltip: 'Actualizar',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(37),
            child: TabBar(
              controller: _tabController,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              dividerHeight: 0,
              labelColor: AppColors.blue1,
              unselectedLabelColor: Colors.grey,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              indicatorPadding: const EdgeInsets.only(bottom: 13),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: AppColors.blue1),
              ),
              tabs: [
                Tab(text: 'TODOS'),
                Tab(text: 'PRODUCTOS'),
                Tab(text: 'COMBOS'),
              ],
            ),
          ),
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Column(
              children: [
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomText(
        borderColor: AppColors.cardBackground,
        borderWidth: 1,
        controller: _searchController,
        hintText: 'Buscar productos...',
        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                onPressed: () {
                  _searchController.clear();
                  // El onChanged se encargará de aplicar los filtros inmediatamente
                },
              )
            : null,
        // Desactivar validación para mostrar el suffixIcon personalizado
        showValidationIndicator: false,
        autovalidateMode: AutovalidateModeX.disabled,
        // Búsqueda automática mientras escribe (con debouncing)
        onChanged: _onSearchChanged,
        // Búsqueda inmediata al presionar Enter (cancelar debouncing)
        onSubmitted: (value) {
          _debounceTimer?.cancel(); // Cancelar timer pendiente
          if (value.isEmpty) {
            _applyFiltros(_filtros.copyWith(clearSearch: true));
          } else {
            _applyFiltros(_filtros.copyWith(search: value));
          }
        },
      ),
    );
  }

  Widget _buildProductList() {
    return BlocBuilder<ProductoListCubit, ProductoListState>(
      builder: (context, state) {
        if (state is ProductoListLoading) {
          return CustomLoading.small(message: 'Cargando productos...');
        }

        if (state is ProductoListError) {
          return _buildErrorView(state.message);
        }

        if (state is ProductoListLoaded) {
          final productos = state.productos;

          if (productos.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadProductos();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productos.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= productos.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final producto = productos[index];
                return ProductoListTile(
                  producto: producto,
                  onTap: () {
                    // Navegar a la página correcta según el tipo
                    if (producto.esCombo) {
                      final empresaState = context
                          .read<EmpresaContextCubit>()
                          .state;
                      if (empresaState is EmpresaContextLoaded) {
                        context.push(
                          '/empresa/combos/${producto.id}?empresaId=${empresaState.context.empresa.id}',
                        );
                      }
                    } else {
                      context.push('/empresa/productos/${producto.id}');
                    }
                  },
                  onManageFiles: () => _showArchivoManager(
                    producto.id,
                    producto.nombre,
                  ),
                  onViewVariants: producto.tieneVariantes
                      ? () => _showVariantes(
                            producto.id,
                            producto.nombre,
                          )
                      : null,
                  onStockDoubleTap: () => _handleStockDoubleTap(producto),
                );
              },
            ),
          );
        }

        if (state is ProductoListLoadingMore) {
          final productos = state.currentProducts;

          return RefreshIndicator(
            onRefresh: () async {
              _loadProductos();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productos.length + 1,
              itemBuilder: (context, index) {
                if (index >= productos.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final producto = productos[index];
                return ProductoListTile(
                  producto: producto,
                  onTap: () {
                    // Navegar a la página correcta según el tipo
                    if (producto.esCombo) {
                      final empresaState = context
                          .read<EmpresaContextCubit>()
                          .state;
                      if (empresaState is EmpresaContextLoaded) {
                        context.push(
                          '/empresa/combos/${producto.id}?empresaId=${empresaState.context.empresa.id}',
                        );
                      }
                    } else {
                      context.push('/empresa/productos/${producto.id}');
                    }
                  },
                  onManageFiles: () => _showArchivoManager(
                    producto.id,
                    producto.nombre,
                  ),
                  onViewVariants: producto.tieneVariantes
                      ? () => _showVariantes(
                            producto.id,
                            producto.nombre,
                          )
                      : null,
                  onStockDoubleTap: () => _handleStockDoubleTap(producto),
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
}
