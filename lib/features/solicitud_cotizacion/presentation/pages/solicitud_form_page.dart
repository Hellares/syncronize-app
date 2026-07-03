import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../marketplace/data/datasources/marketplace_remote_datasource.dart';
import '../../../marketplace/data/models/producto_marketplace_model.dart';
import '../../../marketplace/domain/entities/producto_marketplace.dart';
import '../../../marketplace/presentation/widgets/producto_marketplace_card.dart';
import '../../../marketplace/presentation/widgets/variante_selector.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../bloc/solicitud_form_cubit.dart';
import '../bloc/solicitud_form_state.dart';

/// Solicitar cotización a una empresa del marketplace.
///
/// Los productos se muestran como CARDS (mismo grid masonry de la página de
/// tienda de la empresa): tap en la card = ver DETALLE del producto; el botón
/// circular junto al precio = agregar al carrito de la solicitud (con selector
/// de variante + cantidad si aplica), con badge de cantidad sobre la card.
/// El buscador (fijo, no scrollea) filtra el grid. Los items agregados, el
/// item manual, los items previos y las observaciones viven en un bottom
/// sheet (carrito).
class SolicitudFormPage extends StatefulWidget {
  final String empresaId;
  final String empresaNombre;
  final String subdominio;

  const SolicitudFormPage({
    super.key,
    required this.empresaId,
    required this.empresaNombre,
    required this.subdominio,
  });

  @override
  State<SolicitudFormPage> createState() => _SolicitudFormPageState();
}

class _SolicitudFormPageState extends State<SolicitudFormPage> {
  late final SolicitudFormCubit _formCubit;
  final _marketplaceDataSource = locator<MarketplaceRemoteDataSource>();
  final _searchController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _scrollController = ScrollController();

  // Grid de productos (paginado, igual que la tienda de la empresa)
  List<dynamic> _productos = [];
  bool _isLoadingProductos = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _formCubit = locator<SolicitudFormCubit>();
    _scrollController.addListener(_onScroll);
    _loadProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _observacionesController.dispose();
    _scrollController.dispose();
    _formCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// El debounce lo maneja el propio CustomSearchField.
  void _onSearchChanged(String query) {
    _loadProductos(search: query.trim().isEmpty ? null : query.trim());
  }

  Future<void> _loadProductos({String? search}) async {
    setState(() {
      _isLoadingProductos = true;
      _page = 1;
    });
    try {
      final data = await _marketplaceDataSource.getProductosEmpresa(
        widget.subdominio,
        page: 1,
        limit: 20,
        search: search,
      );
      if (mounted) {
        setState(() {
          _productos = (data['data'] as List<dynamic>?) ?? [];
          _totalPages = (data['pagination']?['totalPages'] as int?) ?? 1;
          _isLoadingProductos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProductos = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    _isLoadingMore = true;
    final nextPage = _page + 1;
    try {
      final data = await _marketplaceDataSource.getProductosEmpresa(
        widget.subdominio,
        page: nextPage,
        limit: 20,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _productos.addAll((data['data'] as List<dynamic>?) ?? []);
          _page = nextPage;
          _totalPages = (data['pagination']?['totalPages'] as int?) ?? 1;
        });
      }
    } catch (_) {}
    _isLoadingMore = false;
  }

  /// Tap en la card = +1 al carrito (el cubit incrementa si ya existe).
  /// Producto con variantes → primero el selector de variante.
  void _addProducto(ProductoMarketplace producto) {
    if (producto.tieneVariantes) {
      _showVarianteSheet(producto);
      return;
    }
    HapticFeedback.selectionClick();
    _formCubit.agregarItemCatalogo(
      productoId: producto.id,
      descripcion: producto.nombre,
      cantidad: 1,
      imagenUrl: producto.imagen,
    );
  }

  /// Sheet para elegir la variante (mismo `VarianteSelector` del detalle del
  /// marketplace). Las variantes se cargan del detalle del producto; al
  /// confirmar se agrega la línea con `varianteId` y la descripción
  /// "PRODUCTO — Color / Talla".
  Future<void> _showVarianteSheet(ProductoMarketplace producto) async {
    Map<String, dynamic>? varianteSel;
    var cantidad = 1;
    final detalleFuture = _marketplaceDataSource.getProductoDetalle(producto.id);

    final elegida = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSubtitle(producto.nombre, fontSize: 12),
              const SizedBox(height: 8),
              Flexible(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: detalleFuture,
                  builder: (context, snap) {
                    // Estados de carga/error con ALTURA FIJA: si el spinner
                    // va dentro de un Center expandible, el sheet abre a su
                    // altura máxima y "se encoge" al llegar los datos.
                    if (snap.hasError) {
                      return SizedBox(
                        height: 90,
                        child: Center(
                          child: AppText(
                            'No se pudieron cargar las variantes',
                            size: 11,
                            color: AppColors.red,
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const SizedBox(
                        height: 90,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final variantes =
                        (snap.data!['variantes'] as List<dynamic>?) ?? [];
                    if (variantes.isEmpty) {
                      return SizedBox(
                        height: 90,
                        child: Center(
                          child: AppText(
                            'Este producto no tiene variantes activas',
                            size: 11,
                            color: AppColors.blueGrey,
                          ),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VarianteSelector(
                            variantes: variantes,
                            onChanged: (v) =>
                                setSheet(() => varianteSel = v),
                          ),
                          if (varianteSel != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _precioVarianteLabel(varianteSel!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Cantidad [-][+] + Agregar en una fila
              Row(
                children: [
                  _stepperBtn(
                    icon: Icons.remove,
                    enabled: cantidad > 1,
                    onTap: () => setSheet(() => cantidad--),
                  ),
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                  ),
                  _stepperBtn(
                    icon: Icons.add,
                    enabled: true,
                    onTap: () => setSheet(() => cantidad++),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Agregar a la solicitud',
                      enabled: varianteSel != null,
                      gradient: const LinearGradient(
                        colors: [AppColors.blue2, AppColors.blue3],
                      ),
                      textColor: Colors.white,
                      fontSize: 11,
                      height: 40,
                      onPressed: varianteSel != null
                          ? () => Navigator.of(sheetContext).pop(varianteSel)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (elegida == null || !mounted) return;
    HapticFeedback.selectionClick();

    // Descripción legible: "PRODUCTO — Negro / M" (atributos) o el nombre
    // de la variante como fallback.
    final atributos = ((elegida['atributos'] as List?) ?? [])
        .map((a) => (a as Map)['valor']?.toString())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .join(' / ');
    final label = atributos.isNotEmpty
        ? atributos
        : (elegida['nombre']?.toString() ?? '');

    // Imagen de la variante (fallback: la del producto).
    String? imagen;
    final imgs = (elegida['imagenes'] as List?) ?? [];
    if (imgs.isNotEmpty) {
      final first = Map<String, dynamic>.from(imgs.first as Map);
      imagen = (first['thumbnail'] ?? first['url'])?.toString();
    }

    _formCubit.agregarItemCatalogo(
      productoId: producto.id,
      varianteId: elegida['id']?.toString(),
      descripcion:
          label.isNotEmpty ? '${producto.nombre} — $label' : producto.nombre,
      cantidad: cantidad,
      imagenUrl: imagen ?? producto.imagen,
    );
  }

  String _precioVarianteLabel(Map<String, dynamic> v) {
    final precio = v['precioOferta'] ?? v['precio'];
    if (precio is num) return 'S/ ${precio.toStringAsFixed(2)}';
    return 'Precio a cotizar';
  }

  /// Botón redondo [-]/[+] del stepper de cantidad.
  Widget _stepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.blue1 : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.blue1 : Colors.grey.shade400,
        ),
      ),
    );
  }

  /// Cantidad de un producto en el carrito (para el badge de la card).
  int _cantidadEnCarrito(SolicitudFormState state, String productoId) {
    List<SolicitudItem> items = [];
    if (state is SolicitudFormEditing) items = state.items;
    if (state is SolicitudFormError) items = state.items;
    var total = 0;
    for (final i in items) {
      if (!i.esManual && i.productoId == productoId) total += i.cantidad;
    }
    return total;
  }

  List<SolicitudItem> _itemsDe(SolicitudFormState state) {
    if (state is SolicitudFormEditing) return state.items;
    if (state is SolicitudFormError) return state.items;
    return [];
  }

  void _showAgregarItemManualDialog() {
    final descripcionController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final notasController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppSubtitle('Agregar item manual', fontSize: 14),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripcion',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notasController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: 11, color: AppColors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              final descripcion = descripcionController.text.trim();
              final cantidadText = cantidadController.text.trim();
              final notas = notasController.text.trim();

              if (descripcion.isEmpty) return;

              final cantidad = int.tryParse(cantidadText) ?? 1;

              _formCubit.agregarItemManual(
                descripcion: descripcion,
                cantidad: cantidad,
                notasItem: notas.isEmpty ? null : notas,
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Agregar',
              style: TextStyle(fontSize: 11, color: AppColors.blue2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocListener<SolicitudFormCubit, SolicitudFormState>(
        listener: (context, state) {
          if (state is SolicitudFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is SolicitudFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
        child: GradientBackground(
          style: GradientStyle.minimal,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: SmartAppBar(title: 'Solicitar Cotizacion'),
            body: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Header + buscador FIJOS: solo el grid de productos scrollea.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildEmpresaHeader(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _buildSearchField(),
        ),
        Expanded(
          child: BlocBuilder<SolicitudFormCubit, SolicitudFormState>(
            builder: (context, state) => CustomScrollView(
              controller: _scrollController,
              slivers: [
                ..._buildProductosGrid(state),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildEmpresaHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.blue3.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.store, color: AppColors.blue3, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSubtitle(widget.empresaNombre, fontSize: 12),
              const SizedBox(height: 2),
              AppText(
                'Toca un producto para agregarlo a la solicitud',
                size: 10,
                color: AppColors.blueGrey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador de la casa (debounce y botón ✕ integrados): filtra el
        // grid de productos.
        CustomSearchField(
          controller: _searchController,
          hintText: 'Buscar producto...',
          borderColor: AppColors.blue1,
          debounceDelay: const Duration(milliseconds: 400),
          onChanged: _onSearchChanged,
        ),
        // Acceso al item manual sin depender del carrito (ej. producto que
        // la tienda no tiene publicado).
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showAgregarItemManualDialog,
            icon: Icon(Icons.edit_note, size: 14, color: AppColors.blue2),
            label: Text(
              '¿No lo encuentras? Agregar item manual',
              style: TextStyle(fontSize: 10, color: AppColors.blue2),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  /// Grid masonry de productos, mismo patrón visual que la página de tienda
  /// de la empresa. Tap en la card = agregar al carrito (badge de cantidad).
  List<Widget> _buildProductosGrid(SolicitudFormState state) {
    if (_isLoadingProductos) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ];
    }

    if (_productos.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  AppSubtitle(
                    'No se encontraron productos',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'Puedes agregarlo como item manual',
                    size: 10,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childCount: _productos.length + (_page < _totalPages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _productos.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final producto = ProductoMarketplaceModel.fromJson(
              _productos[index] as Map<String, dynamic>,
            ).toEntity();
            final enCarrito = _cantidadEnCarrito(state, producto.id);

            return Stack(
              children: [
                // Tap en la card = ver el detalle del producto; el botón
                // circular junto al precio agrega a la solicitud.
                ProductoMarketplaceCard(
                  producto: producto,
                  staggered: true,
                  onTap: () =>
                      context.push('/producto-detalle/${producto.id}'),
                  onAgregarTap: () => _addProducto(producto),
                ),
                // Badge de cantidad en el carrito de la solicitud
                if (enCarrito > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.blue1,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'x$enCarrito',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ];
  }

  /// Barra inferior: carrito (contador + abre el sheet de items) + Enviar.
  Widget _buildBottomBar() {
    return BlocBuilder<SolicitudFormCubit, SolicitudFormState>(
      builder: (context, state) {
        final isSubmitting = state is SolicitudFormSubmitting;
        final items = _itemsDe(state);
        final totalUnidades =
            items.fold<int>(0, (s, i) => s + i.cantidad);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Carrito de la solicitud
                GestureDetector(
                  onTap: items.isEmpty ? null : _showCarritoSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: items.isEmpty
                          ? Colors.grey.shade100
                          : AppColors.blue1.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: items.isEmpty
                            ? Colors.grey.shade300
                            : AppColors.blue1,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 18,
                          color: items.isEmpty
                              ? Colors.grey.shade400
                              : AppColors.blue1,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          items.isEmpty
                              ? 'Sin items'
                              : '${items.length} item${items.length == 1 ? '' : 's'} ($totalUnidades)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: items.isEmpty
                                ? Colors.grey.shade500
                                : AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: 'Enviar Solicitud',
                    isLoading: isSubmitting,
                    loadingText: 'Enviando...',
                    enabled: items.isNotEmpty && !isSubmitting,
                    gradient: const LinearGradient(
                      colors: [AppColors.blue2, AppColors.blue3],
                    ),
                    textColor: Colors.white,
                    fontSize: 11,
                    height: 40,
                    onPressed: items.isNotEmpty && !isSubmitting
                        ? () => _formCubit.submit(empresaId: widget.empresaId)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom sheet con los items agregados + item manual + items previos +
  /// observaciones (el "carrito" de la solicitud).
  void _showCarritoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: _formCubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const AppSubtitle('Items de la solicitud', fontSize: 12),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          _formCubit.cargarItemsPrevios(widget.empresaId),
                      icon: Icon(Icons.history,
                          size: 14, color: AppColors.blueGrey),
                      label: Text(
                        'Anteriores',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.blueGrey),
                      ),
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAgregarItemManualDialog,
                      icon: Icon(Icons.edit_note,
                          size: 14, color: AppColors.blue2),
                      label: Text(
                        'Manual',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.blue2),
                      ),
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: BlocBuilder<SolicitudFormCubit, SolicitudFormState>(
                    builder: (context, state) {
                      final items = _itemsDe(state);
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: AppText(
                              'No hay items agregados',
                              size: 11,
                              color: AppColors.blueGrey,
                            ),
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              _buildItemCard(items[i], i),
                              if (i < items.length - 1)
                                const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 16),
                            const AppSubtitle('Observaciones (opcional)',
                                fontSize: 11),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _observacionesController,
                              onChanged: (value) =>
                                  _formCubit.actualizarObservaciones(value),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'Escribe observaciones o instrucciones adicionales...',
                                hintStyle: TextStyle(
                                    fontSize: 11, color: AppColors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AppColors.greyLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AppColors.greyLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.blue2),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(SolicitudItem item, int index) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Imagen o icono
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.imagenUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imagenUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.greyLight,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.image, size: 18),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.esManual
                          ? AppColors.orange.withValues(alpha: 0.1)
                          : AppColors.blue3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      item.esManual
                          ? Icons.edit_note
                          : Icons.inventory_2_outlined,
                      size: 20,
                      color: item.esManual ? AppColors.orange : AppColors.blue3,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Descripcion y badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.descripcion,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.esManual)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Manual',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.numbers, size: 12, color: AppColors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      'Cantidad: ${item.cantidad}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.blueGrey,
                      ),
                    ),
                    if (item.notasItem != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.note_outlined,
                          size: 12, color: AppColors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.notasItem!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.blueGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Boton eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.red,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _formCubit.eliminarItem(index),
          ),
        ],
      ),
    );
  }
}
