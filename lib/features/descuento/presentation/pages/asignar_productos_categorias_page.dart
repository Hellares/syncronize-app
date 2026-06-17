import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/usecases/get_productos_usecase.dart';
import '../../../catalogo/domain/entities/empresa_categoria.dart';
import '../../../catalogo/domain/usecases/get_categorias_empresa_usecase.dart';
import '../bloc/asignar_productos/asignar_productos_cubit.dart';
import '../bloc/asignar_productos/asignar_productos_state.dart';

class AsignarProductosCategoriasPage extends StatefulWidget {
  final String politicaId;
  final String politicaNombre;

  const AsignarProductosCategoriasPage({
    super.key,
    required this.politicaId,
    required this.politicaNombre,
  });

  @override
  State<AsignarProductosCategoriasPage> createState() =>
      _AsignarProductosCategoriasPageState();
}

class _AsignarProductosCategoriasPageState
    extends State<AsignarProductosCategoriasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedProductos = {};
  final Set<String> _selectedCategorias = {};

  // Cubit de asignación: lo sostenemos como field y lo proveemos con
  // BlocProvider.value para que los métodos _asignar* puedan llamarlo
  // directamente (el `context` del State es ANCESTRO del provider, así que
  // un context.read desde aquí no lo encontraría).
  late final AsignarProductosCubit _asignarCubit;

  late final String _empresaId;

  // ─── Productos (búsqueda + paginación) ───────────────────────────
  final GetProductosUseCase _getProductos = locator<GetProductosUseCase>();
  // El repo devuelve ProductoListItem (no Producto) en ProductosPaginados.data.
  final List<ProductoListItem> _productos = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _productosScroll = ScrollController();
  Timer? _debounce;
  String _productoSearch = '';
  int _productosPage = 1;
  bool _productosHasMore = false;
  bool _loadingProductos = false;
  bool _loadingMoreProductos = false;
  String? _errorProductos;

  // ─── Categorías (lista completa, sin paginación) ─────────────────
  final GetCategoriasEmpresaUseCase _getCategorias =
      locator<GetCategoriasEmpresaUseCase>();
  final List<EmpresaCategoria> _categorias = [];
  bool _loadingCategorias = false;
  String? _errorCategorias;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _asignarCubit = locator<AsignarProductosCubit>();
    // empresaId del CONTEXTO VIVO (como las demás pantallas). El tenantId del
    // storage podía quedar desfasado → se consultaban productos de otra empresa
    // (o vacío) y por eso el buscador "no traía nada". Fallback al storage.
    final empresaState = context.read<EmpresaContextCubit>().state;
    _empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : (locator<LocalStorageService>().getString(StorageConstants.tenantId) ??
            '');
    _productosScroll.addListener(_onProductosScroll);
    _cargarProductos(reset: true);
    _cargarCategorias();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _productosScroll.dispose();
    _tabController.dispose();
    _asignarCubit.close();
    super.dispose();
  }

  // ─── Carga de datos ──────────────────────────────────────────────

  void _onProductosScroll() {
    if (_productosScroll.position.pixels >=
            _productosScroll.position.maxScrollExtent - 200 &&
        _productosHasMore &&
        !_loadingMoreProductos &&
        !_loadingProductos) {
      _cargarProductos(reset: false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = value.trim();
      if (q == _productoSearch) return;
      _productoSearch = q;
      _cargarProductos(reset: true);
    });
  }

  Future<void> _cargarProductos({required bool reset}) async {
    if (_empresaId.isEmpty) {
      setState(() => _errorProductos = 'ID de empresa no disponible');
      return;
    }
    if (reset) {
      setState(() {
        _loadingProductos = true;
        _errorProductos = null;
      });
    } else {
      if (_loadingMoreProductos || !_productosHasMore) return;
      setState(() => _loadingMoreProductos = true);
    }

    final page = reset ? 1 : _productosPage + 1;
    final result = await _getProductos(
      empresaId: _empresaId,
      filtros: ProductoFiltros(
        page: page,
        limit: 30,
        search: _productoSearch.isEmpty ? null : _productoSearch,
        isActive: true,
      ),
    );

    if (!mounted) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      final nuevos = data.data.whereType<ProductoListItem>().toList();
      setState(() {
        if (reset) {
          _productos
            ..clear()
            ..addAll(nuevos);
        } else {
          _productos.addAll(nuevos);
        }
        _productosPage = data.page;
        _productosHasMore = data.hasMore;
        _loadingProductos = false;
        _loadingMoreProductos = false;
      });
    } else if (result is Error<ProductosPaginados>) {
      setState(() {
        _errorProductos = result.message;
        _loadingProductos = false;
        _loadingMoreProductos = false;
      });
    }
  }

  Future<void> _cargarCategorias() async {
    if (_empresaId.isEmpty) {
      setState(() => _errorCategorias = 'ID de empresa no disponible');
      return;
    }
    setState(() {
      _loadingCategorias = true;
      _errorCategorias = null;
    });

    final result = await _getCategorias(_empresaId);

    if (!mounted) return;

    if (result is Success<List<EmpresaCategoria>>) {
      setState(() {
        _categorias
          ..clear()
          ..addAll(result.data);
        _loadingCategorias = false;
      });
    } else if (result is Error<List<EmpresaCategoria>>) {
      setState(() {
        _errorCategorias = result.message;
        _loadingCategorias = false;
      });
    }
  }

  String _nombreCategoria(EmpresaCategoria c) =>
      c.nombrePersonalizado ??
      c.nombreLocal ??
      c.categoriaMaestra?.nombre ??
      'Sin nombre';

  String _descCategoria(EmpresaCategoria c) =>
      c.descripcionPersonalizada ??
      c.categoriaMaestra?.descripcion ??
      'Sin descripción';

  // ─── Asignación ──────────────────────────────────────────────────

  void _asignarProductos() {
    if (_selectedProductos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final productos =
        _selectedProductos.map((id) => {'productoId': id}).toList();

    _asignarCubit.asignarProductos(
      politicaId: widget.politicaId,
      productos: productos,
    );

    setState(() => _selectedProductos.clear());
  }

  void _asignarCategorias() {
    if (_selectedCategorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final categorias =
        _selectedCategorias.map((id) => {'categoriaId': id}).toList();

    _asignarCubit.asignarCategorias(
      politicaId: widget.politicaId,
      categorias: categorias,
    );

    setState(() => _selectedCategorias.clear());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _asignarCubit,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          showLogo: false,
          title: 'Asignar Productos/Categorías',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.blue1,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.blue1,
              tabs: const [
                Tab(text: 'PRODUCTOS'),
                Tab(text: 'CATEGORÍAS'),
              ],
            ),
          ),
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: BlocConsumer<AsignarProductosCubit, AsignarProductosState>(
              listener: (context, state) {
                if (state is AsignarProductosSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is AsignarProductosError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductosTab(),
                    _buildCategoriasTab(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductosTab() {
    return Column(
      children: [
        _buildHeader('Selecciona los productos a asignar'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar producto por nombre o código...',
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(child: _buildProductosContent()),
        if (_selectedProductos.isNotEmpty)
          _buildAssignButton(
            'Asignar Productos (${_selectedProductos.length})',
            _asignarProductos,
          ),
      ],
    );
  }

  Widget _buildProductosContent() {
    if (_loadingProductos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorProductos != null) {
      return _buildErrorState(
        _errorProductos!,
        () => _cargarProductos(reset: true),
      );
    }
    if (_productos.isEmpty) {
      return _productoSearch.isEmpty
          ? _buildEmptyState('productos', Icons.inventory_2)
          : _buildSinResultados('productos');
    }
    return _buildProductosList();
  }

  Widget _buildCategoriasTab() {
    return Column(
      children: [
        _buildHeader('Selecciona las categorías a asignar'),
        Expanded(child: _buildCategoriasContent()),
        if (_selectedCategorias.isNotEmpty)
          _buildAssignButton(
            'Asignar Categorías (${_selectedCategorias.length})',
            _asignarCategorias,
          ),
      ],
    );
  }

  Widget _buildCategoriasContent() {
    if (_loadingCategorias) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorCategorias != null) {
      return _buildErrorState(_errorCategorias!, _cargarCategorias);
    }
    if (_categorias.isEmpty) {
      return _buildEmptyState('categorías', Icons.category);
    }
    return _buildCategoriasList();
  }

  Widget _buildHeader(String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Política: ${widget.politicaNombre}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tipo, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay $tipo disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega $tipo a tu empresa primero',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSinResultados(String tipo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Sin $tipo para "$_productoSearch"',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosList() {
    return ListView.builder(
      controller: _productosScroll,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _productos.length + (_loadingMoreProductos ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _productos.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final producto = _productos[index];
        final isSelected = _selectedProductos.contains(producto.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedProductos.add(producto.id);
                } else {
                  _selectedProductos.remove(producto.id);
                }
              });
            },
            title: Text(
              producto.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Código: ${producto.codigoEmpresa}'),
            secondary: CircleAvatar(
              backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
              child: const Icon(Icons.inventory_2, color: AppColors.blue1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriasList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final categoria = _categorias[index];
        final isSelected = _selectedCategorias.contains(categoria.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedCategorias.add(categoria.id);
                } else {
                  _selectedCategorias.remove(categoria.id);
                }
              });
            },
            title: Text(
              _nombreCategoria(categoria),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(_descCategoria(categoria)),
            secondary: CircleAvatar(
              backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
              child: const Icon(Icons.category, color: AppColors.blue1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignButton(String label, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
