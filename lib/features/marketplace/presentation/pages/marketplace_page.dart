import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../bloc/marketplace_search_cubit.dart';
import '../widgets/marketplace_drawer.dart';
import '../widgets/producto_marketplace_card.dart';
import '../widgets/favorito_button.dart';
import '../widgets/ubicacion_selector.dart';

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
  String? _selectedCategoriaId;
  double? _ubicacionLat;
  double? _ubicacionLng;
  String? _ubicacionLabel;
  List<dynamic> _vistos = [];
  int _carritoCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserData();
    _loadCarritoCount();
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

  Future<void> _loadCarritoCount() async {
    try {
      final secureStorage = locator<SecureStorageService>();
      final token = await secureStorage.read(key: StorageConstants.accessToken);
      if (token == null || token.isEmpty) return;

      final response = await locator<DioClient>().get('/marketplace/carrito/contador');
      if (mounted) {
        setState(() {
          _carritoCount = (response.data['totalCantidad'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  void _onSearch(String query) {
    context.read<MarketplaceSearchCubit>().searchProductos(
          search: query.isEmpty ? null : query,
          categoriaId: _selectedCategoriaId,
        );
  }

  Future<void> _loadUserData() async {
    final storage = locator<LocalStorageService>();
    final token = await storage.getString(StorageConstants.accessToken);
    if (token == null || token.isEmpty) return;

    FavoritoButton.loadFavoritos();
    try {
      final dio = locator<DioClient>();
      final response = await dio.get(
        '${ApiConstants.marketplaceUsuario}/vistos',
        queryParameters: {'limit': '10'},
      );
      if (mounted) setState(() => _vistos = response.data as List);
    } catch (_) {}
  }

  void _onCategoriaSelected(String? categoriaId) {
    setState(() => _selectedCategoriaId = categoriaId);
    context.read<MarketplaceSearchCubit>().searchProductos(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          categoriaId: categoriaId,
        );
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
            toolbarHeight: 60,
            title: CustomSearchField(
              controller: _searchController,
              hintText: 'Buscar productos, marcas y más...',
              backgroundColor: Colors.white,
              borderRadius: 24,
              height: 35,
              showClearButton: true,
              onSubmitted: _onSearch,
              onClear: () {
                _searchController.clear();
                _onSearch('');
              },
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                    onPressed: () async {
                      await context.push('/carrito');
                      _loadCarritoCount();
                    },
                    tooltip: 'Mi carrito',
                  ),
                  if (_carritoCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          _carritoCount > 99 ? '99+' : '$_carritoCount',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
        body: Column(
          children: [
            // Ubicación
            UbicacionSelector(
              lat: _ubicacionLat,
              lng: _ubicacionLng,
              label: _ubicacionLabel,
              onChanged: (result) {
                setState(() {
                  _ubicacionLat = result.lat;
                  _ubicacionLng = result.lng;
                  _ubicacionLabel = result.label;
                });
                context.read<MarketplaceSearchCubit>().setUbicacion(
                  result.lat,
                  result.lng,
                );
              },
            ),

            // Banner carrusel
            _buildBannerCarousel(),

            // Categorías chips
            _buildCategoriaChips(),

            // Visto recientemente
            if (_vistos.isNotEmpty) _buildVistosSection(),

            // Grid de productos
            Expanded(
              child: BlocBuilder<MarketplaceSearchCubit, MarketplaceSearchState>(
                builder: (context, state) {
                  if (state is MarketplaceSearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.blue2),
                    );
                  }

                  if (state is MarketplaceSearchError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Error al cargar productos', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.read<MarketplaceSearchCubit>().refresh(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MarketplaceSearchLoaded) {
                    if (state.productos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
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
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => context.read<MarketplaceSearchCubit>().refresh(),
                      color: AppColors.blue2,
                      child: GridView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: state.productos.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.productos.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final producto = state.productos[index] as Map<String, dynamic>;
                          return ProductoMarketplaceCard(
                            producto: producto,
                            onTap: () async {
                              final id = producto['id'] as String?;
                              if (id != null) {
                                await context.push('/producto-detalle/$id');
                                _loadCarritoCount();
                              }
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        List<dynamic> categorias = [];
        if (state is MarketplaceSearchLoaded && state.categorias != null) {
          categorias = state.categorias!;
        }

        if (categorias.isEmpty) return const SizedBox.shrink();

        return Container(
          color: Colors.white,
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: categorias.length + 1,
            itemBuilder: (context, index) {
              final bool isSelected;
              final String label;
              final VoidCallback onTap;

              if (index == 0) {
                isSelected = _selectedCategoriaId == null;
                label = 'Todas';
                onTap = () => _onCategoriaSelected(null);
              } else {
                final cat = categorias[index - 1] as Map<String, dynamic>;
                final catId = cat['id'] as String;
                isSelected = _selectedCategoriaId == catId;
                label = cat['nombre'] as String? ?? '';
                onTap = () => _onCategoriaSelected(isSelected ? null : catId);
              }

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blue2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.blue2 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
                final nombre = v['nombre'] as String? ?? '';
                final imagen = v['imagen'] as String?;
                final precio = v['precio'] as num?;
                final precioOferta = v['precioOferta'] as num?;
                final enOferta = v['enOferta'] as bool? ?? false;
                final precioFinal = enOferta && precioOferta != null ? precioOferta : precio;

                return GestureDetector(
                  onTap: () async {
                    await context.push('/producto-detalle/${v['id']}');
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
                              ? Image.network(imagen, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Colors.grey))
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
