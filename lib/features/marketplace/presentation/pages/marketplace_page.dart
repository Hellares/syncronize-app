import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/categoria_marketplace.dart';
import '../../domain/entities/marketplace_home.dart';
import '../../domain/entities/producto_marketplace.dart';
import '../../../carrito/presentation/widgets/carrito_badge.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';
import '../../data/models/banner_marketplace_model.dart';
import '../../domain/usecases/get_marketplace_home_usecase.dart';
import '../../domain/usecases/get_productos_vistos_usecase.dart';
import '../../domain/usecases/get_recomendados_usecase.dart';
import '../bloc/marketplace_search_cubit.dart';
import '../widgets/animated_search_bar.dart';
import '../widgets/banner_empresas_slider.dart';
import '../widgets/marketplace_drawer.dart';
import '../widgets/promo_popup.dart';
import '../widgets/producto_marketplace_card.dart';
import '../widgets/favorito_button.dart';
// ignore: unused_import  (UbicacionSelector oculto temporalmente para pruebas)
import '../widgets/ubicacion_selector.dart';

/// Departamentos del Perú para el filtro de ubicación del marketplace.
const List<String> _departamentosPeru = [
  'Amazonas', 'Áncash', 'Apurímac', 'Arequipa', 'Ayacucho', 'Cajamarca',
  'Callao', 'Cusco', 'Huancavelica', 'Huánuco', 'Ica', 'Junín', 'La Libertad',
  'Lambayeque', 'Lima', 'Loreto', 'Madre de Dios', 'Moquegua', 'Pasco',
  'Piura', 'Puno', 'San Martín', 'Tacna', 'Tumbes', 'Ucayali',
];

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<MarketplaceSearchCubit>()
        ..searchProductos()
        ..loadCategorias(),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  const _MarketplaceView();

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _getHome = locator<GetMarketplaceHomeUseCase>();
  final _getVistos = locator<GetProductosVistosUseCase>();
  final _getRecomendados = locator<GetRecomendadosUseCase>();

  /// Destino de la animación "vuela al carrito" desde las cards del grid.
  final _cartIconKey = GlobalKey();
  // Banners publicitarios (pinneados bajo las categorías).
  List<BannerMarketplaceModel> _banners = const [];
  String? _selectedCategoriaId;
  // ignore: unused_field  (ubicación oculta temporalmente para pruebas)
  double? _ubicacionLat;
  // ignore: unused_field
  double? _ubicacionLng;
  // ignore: unused_field
  String? _ubicacionLabel;
  List<ProductoMarketplace> _vistos = [];
  List<ProductoMarketplace> _recomendados = [];
  List<ProductoMarketplace> _ofertas = [];
  List<ProductoMarketplace> _masVistos = [];
  // ignore: unused_field  ("Lo más vendido" oculto temporalmente para pruebas)
  List<ProductoMarketplace> _masVendidos = [];
  // Cortina de plataforma: cuando el super admin la activa tapa TODA la
  // sección de productos (chips, secciones del home y grid) con un mensaje.
  CortinaMarketplace _cortina = const CortinaMarketplace();

  /// URLs ya precargadas, para no relanzar precache en cada rebuild de la grilla.
  final Set<String> _prefetchedImages = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserData();
    _loadCarritoCount();
    _loadHome();
    _loadBanners();
    // Popup de publicidad ~3s después de entrar (máx 1-2 veces/día).
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) PromoPopup.mostrarSiCorresponde(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MarketplaceSearchCubit>().loadMore();
    }
  }

  /// Precarga (descarga + decode) las imágenes de las próximas cards para que
  /// al hacer scroll ya estén en cache y aparezcan al instante. Se llama al
  /// construir cada card; el [_prefetchedImages] evita relanzarlo por rebuild.
  void _prefetchUpcoming(
    BuildContext context,
    List<ProductoMarketplace> productos,
    int index,
  ) {
    const ahead = 4;
    final mq = MediaQuery.of(context);
    final cacheW = (mq.size.width / 2 * mq.devicePixelRatio).round();
    for (var i = index + 1; i <= index + ahead && i < productos.length; i++) {
      final url = productos[i].imagen;
      if (url == null || url.isEmpty || !_prefetchedImages.add(url)) continue;
      precacheImage(
        CachedNetworkImageProvider(url, maxWidth: cacheW),
        context,
      ).catchError((_) {
        // Si falla la precarga, la card la reintentará al construirse.
        _prefetchedImages.remove(url);
      });
    }
  }

  /// El contador vive en [CarritoBadgeController] (badge global compartido con
  /// el detalle de producto); aquí solo se pide un refresh desde el server.
  void _loadCarritoCount() {
    CarritoBadgeController.sync();
  }

  void _clearBusqueda() {
    _searchController.clear();
    setState(() => _selectedCategoriaId = null);
    context.read<MarketplaceSearchCubit>().searchProductos(
          search: null,
          categoriaId: null,
        );
  }

  /// Abre la página de búsqueda con autocomplete y aplica lo seleccionado.
  Future<void> _openBuscar() async {
    final result = await context.push<Object?>(
      '/marketplace/buscar',
      extra: _searchController.text,
    );
    if (result is! Map || !mounted) return;
    if (result['search'] != null) {
      final term = result['search'] as String;
      _searchController.text = term;
      setState(() => _selectedCategoriaId = null);
      context.read<MarketplaceSearchCubit>().searchProductos(
            search: term.isEmpty ? null : term,
            categoriaId: null,
          );
    } else if (result['categoriaId'] != null) {
      final id = result['categoriaId'] as String;
      final nombre = result['categoriaNombre'] as String?;
      _searchController.text = nombre ?? '';
      setState(() => _selectedCategoriaId = id);
      context.read<MarketplaceSearchCubit>().searchProductos(
            search: null,
            categoriaId: id,
          );
    }
  }

  /// Carga las secciones del home (ofertas, más vistos). Público, sin auth.
  Future<void> _loadHome() async {
    final result = await _getHome();
    if (result is! Success<MarketplaceHome> || !mounted) return;
    final home = result.data;
    setState(() {
      _ofertas = home.ofertas;
      _masVendidos = home.masVendidos;
      _masVistos = home.masVistos;
      _cortina = home.cortina;
    });
  }

  /// Banners publicitarios (empresas con plan vigente). Público, sin auth.
  Future<void> _loadBanners() async {
    try {
      final banners =
          await locator<MarketplaceRemoteDataSource>().getBanners();
      if (mounted) setState(() => _banners = banners);
    } catch (_) {
      // Silencioso: sin banners el sliver simplemente no se incluye.
    }
  }

  Future<void> _loadUserData() async {
    final storage = locator<LocalStorageService>();
    final token = storage.getString(StorageConstants.accessToken);
    if (token == null || token.isEmpty) return;

    FavoritoButton.loadFavoritos();

    final vistos = await _getVistos(limit: 10);
    if (vistos is Success<List<ProductoMarketplace>> && mounted) {
      setState(() => _vistos = vistos.data);
    }
    // Recomendados por historial de navegación (sección "Recomendados para ti").
    final recomendados = await _getRecomendados(limit: 12);
    if (recomendados is Success<List<ProductoMarketplace>> && mounted) {
      setState(() => _recomendados = recomendados.data);
    }
  }

  void _onCategoriaSelected(String? categoriaId) {
    setState(() => _selectedCategoriaId = categoriaId);
    context.read<MarketplaceSearchCubit>().searchProductos(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          categoriaId: categoriaId,
        );
  }

  void _mostrarFiltros() {
    final cubit = context.read<MarketplaceSearchCubit>();
    String? orden = cubit.ordenActual;
    String? departamento = cubit.departamentoActual;
    final minCtrl = TextEditingController(
      text: cubit.precioMinActual?.toStringAsFixed(0) ?? '',
    );
    final maxCtrl = TextEditingController(
      text: cubit.precioMaxActual?.toStringAsFixed(0) ?? '',
    );

    const tituloStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget chipOrden(String label, String? value) {
            final sel = orden == value;
            return ChoiceChip(
              label: Text(label),
              selected: sel,
              showCheckmark: false,
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.blue1.withValues(alpha: 0.15),
              side: BorderSide(
                color: sel
                    ? AppColors.blue1.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                color: sel ? AppColors.blue1 : Colors.grey.shade700,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => setSheetState(() => orden = value),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 20, color: AppColors.blue1),
                      const SizedBox(width: 8),
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          cubit.limpiarFiltros();
                        },
                        child: Text(
                          'Limpiar',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Ordenar por', style: tituloStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chipOrden('Relevancia', null),
                      chipOrden('Menor precio', 'precio_asc'),
                      chipOrden('Mayor precio', 'precio_desc'),
                      chipOrden('Más recientes', 'recientes'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Precio (S/)', style: tituloStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: deco('Mín'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: deco('Máx'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Departamento', style: tituloStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: departamento,
                    isExpanded: true,
                    decoration: deco('Todos'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos', style: TextStyle(fontSize: 13)),
                      ),
                      ..._departamentosPeru.map(
                        (d) => DropdownMenuItem<String?>(
                          value: d,
                          child:
                              Text(d, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => departamento = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final min = double.tryParse(
                            minCtrl.text.trim().replaceAll(',', '.'));
                        final max = double.tryParse(
                            maxCtrl.text.trim().replaceAll(',', '.'));
                        Navigator.pop(sheetContext);
                        cubit.aplicarFiltros(
                          precioMin: min,
                          precioMax: max,
                          departamento: departamento,
                          orden: orden,
                        );
                      },
                      child: const Text(
                        'Aplicar filtros',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      minCtrl.dispose();
      maxCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const MarketplaceDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            toolbarHeight: 50,
            // Menos espacio a los lados del título → el search ocupa ~10px más
            // de ancho horizontal (default titleSpacing es 16).
            titleSpacing: 6,
            title: AnimatedSearchBar(
              onTap: _openBuscar,
              query: _searchController.text,
              height: 33,
              borderRadius: 24,
            ),
            actions: [
              if (_searchController.text.isNotEmpty ||
                  _selectedCategoriaId != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: _clearBusqueda,
                  tooltip: 'Limpiar búsqueda',
                ),
              BlocBuilder<MarketplaceSearchCubit, MarketplaceSearchState>(
                builder: (context, state) {
                  final activos = context
                      .read<MarketplaceSearchCubit>()
                      .tieneFiltrosActivos;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: activos,
                      smallSize: 8,
                      child: const Icon(Icons.tune, size: 22),
                    ),
                    onPressed: _mostrarFiltros,
                    tooltip: 'Filtros',
                    // Íconos bien juntos → el search gana ancho a la derecha.
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                  );
                },
              ),
              Center(
                child: CarritoBadge(
                  child: IconButton(
                    key: _cartIconKey,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                    onPressed: () async {
                      await context.push('/carrito');
                      _loadCarritoCount();
                    },
                    tooltip: 'Mi carrito',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.blue2,
          onRefresh: () async {
            await context.read<MarketplaceSearchCubit>().refresh();
            await _loadHome();
            await _loadUserData();
            await _loadBanners();
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            // Cortina activa: se reemplaza TODO (chips, banners, secciones y
            // grid) por la pantalla de cortina. Pull-to-refresh sigue vivo
            // para re-consultar cuando el admin la desactive.
            slivers: _cortina.activa
                ? [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CortinaMarketplaceView(cortina: _cortina),
                    ),
                  ]
                : [
              // Ocultos temporalmente para pruebas (widget de ubicación +
              // slider de banners). Reactivar descomentando.
              // SliverToBoxAdapter(
              //   child: UbicacionSelector(
              //     lat: _ubicacionLat,
              //     lng: _ubicacionLng,
              //     label: _ubicacionLabel,
              //     onChanged: (result) {
              //       setState(() {
              //         _ubicacionLat = result.lat;
              //         _ubicacionLng = result.lng;
              //         _ubicacionLabel = result.label;
              //       });
              //       context.read<MarketplaceSearchCubit>().setUbicacion(
              //             result.lat,
              //             result.lng,
              //           );
              //     },
              //   ),
              // ),
              // SliverToBoxAdapter(child: _buildBannerCarousel()),
              // Chips de categoría fijos (tipo Temu): quedan pinneados arriba
              // mientras se hace scroll del grid filtrado.
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedChipsDelegate(
                  height: 30,
                  child: _buildCategoriaChips(),
                ),
              ),
              // Banners publicitarios PINNEADOS bajo las categorías: siempre
              // visibles (es pequeño y es el espacio que se vende por plan).
              if (_banners.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedChipsDelegate(
                    height: BannerEmpresasSlider.sliverHeight,
                    child: ColoredBox(
                      color: Colors.white,
                      child: BannerEmpresasSlider(banners: _banners),
                    ),
                  ),
                ),
              // Secciones del home: solo cuando no hay búsqueda/categoría/filtros.
              SliverToBoxAdapter(
                child: BlocBuilder<MarketplaceSearchCubit,
                    MarketplaceSearchState>(
                  builder: (context, state) {
                    final esHome = _searchController.text.isEmpty &&
                        _selectedCategoriaId == null &&
                        !context
                            .read<MarketplaceSearchCubit>()
                            .tieneFiltrosActivos;
                    if (!esHome) return const SizedBox.shrink();
                    return Column(
                      children: [
                        if (_recomendados.isNotEmpty)
                          _buildSeccionCarrusel(
                              'Recomendados para ti', _recomendados),
                        if (_ofertas.isNotEmpty)
                          _buildSeccionCarrusel('Ofertas', _ofertas,
                              acento: AppColors.blue1),
                        // Oculto temporalmente para pruebas (Lo más vendido).
                        // if (_masVendidos.isNotEmpty)
                        //   _buildSeccionCarrusel(
                        //       'Lo más vendido', _masVendidos),
                        if (_masVistos.isNotEmpty)
                          _buildSeccionCarrusel('Lo más visto', _masVistos),
                      ],
                    );
                  },
                ),
              ),
              if (_vistos.isNotEmpty)
                SliverToBoxAdapter(child: _buildVistosSection()),
              // Grid de productos
              BlocBuilder<MarketplaceSearchCubit, MarketplaceSearchState>(
                builder: (context, state) {
                  if (state is MarketplaceSearchLoading) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child:
                              CircularProgressIndicator(color: AppColors.blue2),
                        ),
                      ),
                    );
                  }

                  if (state is MarketplaceSearchError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Error al cargar productos',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context
                                    .read<MarketplaceSearchCubit>()
                                    .refresh(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is MarketplaceSearchLoaded) {
                    if (state.productos.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                AppTitle(
                                  'No se encontraron productos',
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                if (state.search != null) ...[
                                  const SizedBox(height: 4),
                                  AppSubtitle(
                                    'Intenta con otros términos de búsqueda',
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      // Sin padding horizontal: el grid queda pegado a los
                      // bordes izq/der de la pantalla (edge-to-edge tipo Temu).
                      padding: EdgeInsets.zero,
                      // Masonry/staggered: cada card se ajusta a su alto y las
                      // columnas fluyen independientes (cards escalonadas, tipo Temu).
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                        childCount: state.productos.length,
                        itemBuilder: (context, index) {
                          final producto = state.productos[index];
                          // Head-start: precargar imágenes de las próximas cards.
                          _prefetchUpcoming(context, state.productos, index);
                          return ProductoMarketplaceCard(
                            producto: producto,
                            staggered: true,
                            cartIconKey: _cartIconKey,
                            onTap: () async {
                              await context.push('/producto-detalle/${producto.id}');
                              _loadCarritoCount();
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
              // Footer de paginación (loadMore)
              BlocBuilder<MarketplaceSearchCubit, MarketplaceSearchState>(
                builder: (context, state) {
                  if (state is MarketplaceSearchLoaded && state.hasMore) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element  (oculto temporalmente para pruebas; ver sliver arriba)
  Widget _buildBannerCarousel() {
    // Banner siempre muestra imágenes estáticas (publicidad)
    // Más adelante: ofertas, productos top, publicidad pagada
    return const _StaticBannerCarousel();
  }

  Widget _buildCategoriaChips() {
    return BlocBuilder<MarketplaceSearchCubit, MarketplaceSearchState>(
      buildWhen: (prev, curr) {
        final prevCats = prev is MarketplaceSearchLoaded ? prev.categorias : null;
        final currCats = curr is MarketplaceSearchLoaded ? curr.categorias : null;
        return prevCats != currCats ||
               (prev is MarketplaceSearchLoaded ? prev.categoriaId : null) !=
               (curr is MarketplaceSearchLoaded ? curr.categoriaId : null);
      },
      builder: (context, state) {
        List<CategoriaMarketplace> categorias = [];
        if (state is MarketplaceSearchLoaded && state.categorias != null) {
          categorias = state.categorias!;
        }

        if (categorias.isEmpty) return const SizedBox.shrink();

        return Container(
          color: Colors.white,
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categorias.length + 1,
            itemBuilder: (context, index) {
              final bool isSelected;
              final String label;
              final VoidCallback onTap;

              if (index == 0) {
                isSelected = _selectedCategoriaId == null;
                label = 'Todos';
                onTap = () => _onCategoriaSelected(null);
              } else {
                final cat = categorias[index - 1];
                final catId = cat.id;
                isSelected = _selectedCategoriaId == catId;
                label = cat.nombre;
                onTap = () => _onCategoriaSelected(isSelected ? null : catId);
              }

              // Tab de texto estilo Temu: seleccionado en negro/negrita con un
              // subrayado corto; el resto en gris. Sin píldora ni borde.
              return GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Subrayado indicador (solo el seleccionado).
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.blue2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Carrusel horizontal de productos para una sección del home
  /// (Ofertas, Lo más visto). Reusa el card del carrusel de "vistos".
  Widget _buildSeccionCarrusel(
    String titulo,
    List<ProductoMarketplace> items, {
    Color? acento,
  }) {
    return Container(
      color: Colors.white,
      // margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (acento != null) ...[
                  Icon(Icons.local_offer, size: 14, color: acento),
                  const SizedBox(width: 6),
                ],
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: acento ?? Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            // Alto para la card compacta (imagen + precio + rating/vendidos +
            // nombre). Mismo patrón que el perfil público de tienda.
            height: 158,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final v = items[index];
                // Reutiliza la card profesional (rating, N vendidos, precio con
                // tachado, badges) en modo compacto, en vez de la mini-card
                // plana anterior.
                return SizedBox(
                  width: 126,
                  child: ProductoMarketplaceCard(
                    producto: v,
                    compact: true,
                    onTap: () async {
                      await context.push('/producto-detalle/${v.id}');
                      _loadHome();
                      _loadCarritoCount();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistosSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Visto recientemente',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _vistos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final v = _vistos[index];
                final nombre = v.nombre;
                final imagen = v.imagen;
                final enOferta = v.enOferta;
                final precioFinal = v.precioFinal;

                return GestureDetector(
                  onTap: () async {
                    await context.push('/producto-detalle/${v.id}');
                    _loadUserData();
                    _loadCarritoCount();
                  },
                  child: Container(
                    width: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          width: double.infinity,
                          color: Colors.grey.shade50,
                          child: imagen != null
                              ? CachedNetworkImage(imageUrl: imagen, fit: BoxFit.contain,
                                  placeholder: (_, __) => const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Colors.grey))
                              : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (precioFinal != null)
                                Text('S/ ${precioFinal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: enOferta ? Colors.green.shade600 : Colors.black87,
                                    )),
                              Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade700, height: 1.2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Delegate para pinnear los chips de categoría arriba del scroll (tipo Temu).
class _PinnedChipsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _PinnedChipsDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedChipsDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

/// Carrusel de banners estáticos (imágenes locales)
class _StaticBannerCarousel extends StatefulWidget {
  const _StaticBannerCarousel();

  @override
  State<_StaticBannerCarousel> createState() => _StaticBannerCarouselState();
}

class _StaticBannerCarouselState extends State<_StaticBannerCarousel> {
  static const _banners = [
    'assets/banner/banner.png',
    'assets/banner/banner2.png',
  ];

  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _autoScroll();
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _autoScroll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.fromLTRB(5, 8, 5, 4),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.asset(
                  _banners[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            },
          ),
        ),
        if (_banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _current == i ? AppColors.blue2 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cortina de plataforma: pantalla que tapa toda la sección de productos del
/// marketplace cuando el super admin la activa desde syncronize-admin
/// (Configuración del Sistema → Marketplace).
class _CortinaMarketplaceView extends StatelessWidget {
  final CortinaMarketplace cortina;

  const _CortinaMarketplaceView({required this.cortina});

  @override
  Widget build(BuildContext context) {
    final titulo = (cortina.titulo ?? '').trim().isEmpty
        ? 'Marketplace en mantenimiento'
        : cortina.titulo!.trim();
    final mensaje = (cortina.mensaje ?? '').trim();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.blue2, AppColors.blue1],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (mensaje.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                'Desliza hacia abajo para actualizar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
