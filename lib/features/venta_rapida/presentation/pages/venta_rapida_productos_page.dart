import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../combo/domain/entities/combo.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../bloc/venta_rapida_cubit.dart';
import '../widgets/precios_mayor_sheet.dart';

class VentaRapidaProductosPage extends StatelessWidget {
  const VentaRapidaProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final authState = context.read<AuthBloc>().state;

    String? empresaId;
    String? sedeId;
    String? vendedorId;
    if (empresaState is EmpresaContextLoaded) {
      empresaId = empresaState.context.empresa.id;
      sedeId = empresaState.context.sedePrincipal?.id ??
          (empresaState.context.sedes.isNotEmpty
              ? empresaState.context.sedes.first.id
              : null);
    }
    if (authState is Authenticated) {
      vendedorId = authState.user.id;
    }

    if (empresaId == null || sedeId == null || vendedorId == null) {
      return const Scaffold(
        body: Center(child: Text('Falta contexto de empresa/sede')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: () {
            final cubit = locator<VentaRapidaCubit>();
            cubit.setContexto(
              empresaId: empresaId!,
              sedeId: sedeId!,
              vendedorId: vendedorId!,
            );
            return cubit;
          }(),
        ),
        BlocProvider(
          // Venta Rápida solo debe mostrar productos disponibles para venta
          // (isActive=true). Productos inactivos o eliminados quedan ocultos
          // en este flujo de cobro.
          create: (_) => locator<ProductoListCubit>()
            ..loadProductos(
              empresaId: empresaId!,
              sedeId: sedeId,
              filtros: const ProductoFiltros(isActive: true),
            ),
        ),
      ],
      child: _ProductosView(sedeId: sedeId),
    );
  }
}

class _ProductosView extends StatefulWidget {
  final String sedeId;
  const _ProductosView({required this.sedeId});

  @override
  State<_ProductosView> createState() => _ProductosViewState();
}

class _ProductosViewState extends State<_ProductosView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  /// Último código escaneado por cámara. Cuando llega la respuesta del
  /// backend, si hay coincidencia exacta de 1 producto, se auto-agrega
  /// al carrito y se limpia el search. Patrón típico POS con scanner.
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Dispara `loadMore()` al alcanzar el 85% del scroll, evitando que el
  /// cajero "pegue" en el final esperando más resultados.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent * 0.85) return;
    final cubit = context.read<ProductoListCubit>();
    final s = cubit.state;
    if (s is ProductoListLoaded && s.hasMore && !s.isFiltering) {
      cubit.loadMore();
    }
  }

  /// Abre el scanner de cámara, captura un código de barras y lo busca.
  /// Si el backend devuelve exactamente 1 producto cuyo `codigoBarras`
  /// coincide con lo escaneado, lo auto-agrega al carrito y limpia el
  /// search. Si la búsqueda es ambigua, deja el código en el search
  /// para que el cajero elija manualmente.
  Future<void> _escanearCodigo() async {
    final code = await showBarcodeScannerSheet(context);
    if (code == null || code.isEmpty || !mounted) return;
    _lastScannedCode = code.trim();
    _searchCtrl.text = _lastScannedCode!;
    if (!mounted) return;
    context.read<ProductoListCubit>().applyFiltros(
          ProductoFiltros(search: _lastScannedCode, isActive: true),
        );
  }

  /// Si el último request vino de un scan y trajo exactamente 1 producto
  /// con `codigoBarras` matching, auto-agregar al carrito y limpiar.
  void _autoAgregarSiMatchExacto(ProductoListLoaded state) {
    final code = _lastScannedCode;
    if (code == null) return;
    if (state.isFiltering) return; // esperar respuesta final
    if (state.filtros.search != code) return; // respuesta de otro filtro
    final ordenados = _ordenarPorStock(state.productos);
    if (ordenados.length != 1) {
      // 0 ó >1 → dejar al cajero elegir manualmente. El backend ya hizo
      // el match exacto contra codigoBarras/sku/codigoEmpresa, así que
      // si hay >1 son productos distintos con el mismo código (caso raro).
      _lastScannedCode = null;
      return;
    }
    final p = ordenados.first;
    final stock = p.stockEnSede(widget.sedeId) ?? 0;
    if (stock <= 0) {
      _lastScannedCode = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sin stock: ${p.nombre}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    context.read<VentaRapidaCubit>().agregarProducto(p);
    _lastScannedCode = null;
    _searchCtrl.clear();
    // Reset al estado base de Venta Rápida: solo productos activos.
    context.read<ProductoListCubit>().applyFiltros(
          const ProductoFiltros(isActive: true),
          sedeId: widget.sedeId,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${p.nombre} agregado'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Productos ordenados: con stock disponible primero, agotados al final.
  /// Se hace en cliente para no afectar la query/paginación del backend.
  List<ProductoListItem> _ordenarPorStock(List<ProductoListItem> items) {
    final sedeId = widget.sedeId;
    final conStock = <ProductoListItem>[];
    final sinStock = <ProductoListItem>[];
    for (final p in items) {
      final s = p.stockEnSede(sedeId) ?? 0;
      if (s > 0) {
        conStock.add(p);
      } else {
        sinStock.add(p);
      }
    }
    return [...conStock, ...sinStock];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: BlocBuilder<VentaRapidaCubit, VentaRapidaState>(
          builder: (context, state) {
            return Row(
              children: [
                const Text('Productos', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(
                  'S/ ${state.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<VentaRapidaCubit, VentaRapidaState>(
            builder: (context, state) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_checkout),
                    onPressed: state.items.isEmpty
                        ? null
                        : () => context.push('/empresa/venta-rapida/carrito'),
                  ),
                  if (state.cantidadUnidades > 0)
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
                          '${state.cantidadUnidades}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<VentaRapidaCubit, VentaRapidaState>(
        listenWhen: (prev, curr) =>
            prev.comboPendienteOferta != curr.comboPendienteOferta &&
            curr.comboPendienteOferta != null,
        listener: (context, state) {
          _mostrarConfirmacionComboOferta(context, state.comboPendienteOferta!);
        },
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: CustomSearchField(
              controller: _searchCtrl,
              hintText: 'Buscar producto o escanear...',
              borderColor: AppColors.blue1,
              debounceDelay: const Duration(milliseconds: 400),
              height: 40,
              onChanged: (value) {
                // Si el cajero edita manualmente, ya no es un código
                // escaneado — desactivamos el auto-add.
                _lastScannedCode = null;
                context.read<ProductoListCubit>().applyFiltros(
                      ProductoFiltros(search: value, isActive: true),
                    );
              },
              onClear: () {
                _lastScannedCode = null;
                // Volver al listado base de Venta Rápida: solo activos.
                context.read<ProductoListCubit>().applyFiltros(
                      const ProductoFiltros(isActive: true),
                      sedeId: widget.sedeId,
                    );
              },
              actionButtons: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  color: AppColors.blue1,
                  onPressed: _escanearCodigo,
                  tooltip: 'Escanear código de barras',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 32),
                ),
              ],
            ),
          ),
          // Barra fina de progreso mientras se filtra (no parpadea el grid).
          BlocBuilder<ProductoListCubit, ProductoListState>(
            buildWhen: (a, b) {
              final aF = a is ProductoListLoaded && a.isFiltering;
              final bF = b is ProductoListLoaded && b.isFiltering;
              return aF != bF;
            },
            builder: (_, state) {
              final filtrando = state is ProductoListLoaded && state.isFiltering;
              return SizedBox(
                height: 2,
                child: filtrando
                    ? const LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                      )
                    : null,
              );
            },
          ),
          Expanded(
            child: BlocConsumer<ProductoListCubit, ProductoListState>(
              listenWhen: (prev, curr) =>
                  curr is ProductoListLoaded && !curr.isFiltering,
              listener: (context, state) {
                // Auto-agregar al carrito cuando el último request fue
                // un escaneo y trajo exactamente 1 producto.
                if (state is ProductoListLoaded) {
                  _autoAgregarSiMatchExacto(state);
                }
              },
              builder: (context, state) {
                if (state is ProductoListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductoListError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context
                                .read<ProductoListCubit>()
                                .reload(sedeId: widget.sedeId),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Productos a mostrar: si Loaded → state.productos.
                // Si LoadingMore → currentProducts (mantiene grid visible).
                List<ProductoListItem>? items;
                bool cargandoMas = false;
                bool hasMore = false;
                if (state is ProductoListLoaded) {
                  items = state.productos;
                  hasMore = state.hasMore;
                } else if (state is ProductoListLoadingMore) {
                  items = state.currentProducts;
                  cargandoMas = true;
                  hasMore = true;
                }
                if (items == null) return const SizedBox.shrink();

                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => context
                        .read<ProductoListCubit>()
                        .reload(sedeId: widget.sedeId),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No se encontraron productos',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final ordenados = _ordenarPorStock(items);
                return RefreshIndicator(
                  onRefresh: () => context
                      .read<ProductoListCubit>()
                      .reload(sedeId: widget.sedeId),
                  child: GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: ordenados.length + (cargandoMas || hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= ordenados.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: cargandoMas
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final p = ordenados[i];
                      return _ProductoCard(
                        producto: p,
                        sedeId: widget.sedeId,
                        onTap: () {
                          context.read<VentaRapidaCubit>().agregarProducto(p);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Dialog que advierte al cajero cuando un combo tiene componentes en
  /// oferta activa (el combo ignora ofertas individuales — el cliente
  /// podría preferir comprar suelto). Si confirma, expande el combo;
  /// si cancela, descarta.
  Future<void> _mostrarConfirmacionComboOferta(
    BuildContext context,
    Combo combo,
  ) async {
    final cubit = context.read<VentaRapidaCubit>();
    final componentesEnOferta = combo.componentes
        .where((c) => c.componenteInfo?.ofertaActiva ?? false)
        .toList();

    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Componentes en oferta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El combo "${combo.nombre}" incluye productos con oferta '
              'activa. El precio del combo ignora la oferta individual — '
              'al cliente le podría convenir comprar estos productos sueltos:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...componentesEnOferta.map((c) {
              final info = c.componenteInfo!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.local_offer,
                        size: 14, color: Colors.orange.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.nombre,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'S/ ${info.precio.toStringAsFixed(2)} → '
                      'S/ ${info.precioOferta!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              '¿Vender el combo de todas formas?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vender combo'),
          ),
        ],
      ),
    );

    if (confirma == true) {
      cubit.confirmarComboPendiente();
    } else {
      cubit.cancelarComboPendiente();
    }
  }
}

class _ProductoCard extends StatelessWidget {
  final ProductoListItem producto;
  final String sedeId;
  final VoidCallback onTap;

  const _ProductoCard({
    required this.producto,
    required this.sedeId,
    required this.onTap,
  });

  double _qtyEnCarrito(VentaRapidaState state) {
    for (final i in state.items) {
      if (i.productoId == producto.id) return i.cantidad;
    }
    return 0;
  }

  void _abrirZoom(BuildContext context) {
    final imagen = producto.imagenPrincipal;
    if (imagen == null || imagen.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ImagenZoomDialog(
        imagenes: [imagen],
        nombreProducto: producto.nombre,
      ),
    );
  }

  void _abrirPreciosMayor(BuildContext context) {
    final cubit = context.read<VentaRapidaCubit>();
    showPreciosMayorSheet(
      context: context,
      producto: producto,
      sedeId: sedeId,
      cargarNiveles: cubit.getNivelesProducto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final precio = producto.precioEfectivoEnSede(sedeId) ??
        producto.precioEnSede(sedeId) ??
        0.0;
    final stockTotal = producto.stockEnSede(sedeId) ?? 0;
    final imagen = producto.imagenPrincipal;

    return BlocBuilder<VentaRapidaCubit, VentaRapidaState>(
      buildWhen: (prev, curr) {
        final prevQty = _qtyEnCarrito(prev);
        final currQty = _qtyEnCarrito(curr);
        return prevQty != currQty;
      },
      builder: (context, state) {
        final cantidadEnCarrito = _qtyEnCarrito(state);
        final estaEnCarrito = cantidadEnCarrito > 0;
        // Stock disponible real (descontando lo que ya está en el carrito).
        // Esto evita que el cajero vea "Stock: 5" cuando ya agregó las 5.
        final stockDisponible =
            (stockTotal - cantidadEnCarrito).clamp(0, double.infinity).toInt();
        final agotado = stockDisponible <= 0;

        return Opacity(
          opacity: agotado && !estaEnCarrito ? 0.55 : 1.0,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: agotado
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sin stock: ${producto.nombre}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  : onTap,
              onLongPress: () => _abrirZoom(context),
              child: Stack(
                children: [
                  // Maquetación tipo "ficha":
                  //   ┌─────────────────────────────┐
                  //   │  NOMBRE DEL PRODUCTO        │  ← header (full width)
                  //   ├──────────┬──────────────────┤
                  //   │          │ stock: 39        │
                  //   │  IMAGEN  │ PROD-000001      │
                  //   │          ├──────────────────┤
                  //   │          │ UND      S/ 500  │
                  //   └──────────┴──────────────────┘
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.blue1.withValues(alpha: 0.05),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header: nombre del producto ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.blue1.withValues(alpha: 0.05),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Text(
                            producto.nombre.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue1,
                              // letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ── Body: imagen | info ──
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Imagen (mitad izquierda)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: imagen != null && imagen.isNotEmpty
                                        ? Image.network(
                                            imagen,
                                            fit: BoxFit.cover,
                                            cacheWidth: 200,
                                            errorBuilder: (_, __, ___) =>
                                                _placeholder(),
                                          )
                                        : _placeholder(),
                                  ),
                                ),
                              ),
                              // Divisor vertical
                              Container(
                                width: 0.8,
                                color: AppColors.blue1.withValues(alpha: 0.05),
                              ),
                              // Info (mitad derecha)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Bloque superior: stock + código
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              agotado
                                                  ? 'Sin stock'
                                                  : 'Stock: $stockDisponible',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: agotado
                                                    ? Colors.red
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              producto.codigoEmpresa,
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Divisor horizontal
                                    Container(
                                      height: 0.8,
                                      color: AppColors.blue1.withValues(alpha: 0.05),
                                    ),
                                    // Bloque inferior: UND + precio
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'UND',
                                            style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'S/ ${precio.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Botón discreto para abrir bottom sheet de precios por mayor.
                // En esquina inferior izquierda — la derecha la ocupan el
                // badge "agregado" y el stepper cuando el producto está en
                // el carrito.
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _abrirPreciosMayor(context),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.auto_graph,
                          size: 14,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                  ),
                ),
                // Check + stepper cuando el producto está en el carrito
                if (estaEnCarrito) ...[
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
                  Positioned(
                    top: 28,
                    right: 6,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      elevation: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // InkWell(
                          //   borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          //   onTap: () => context
                          //       .read<VentaRapidaCubit>()
                          //       .agregarProducto(producto),
                          //   child: Padding(
                          //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          //     child: Icon(Icons.add, size: 16, color: Colors.green.shade700),
                          //   ),
                          // ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                            child: Text(
                              cantidadEnCarrito.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                            onTap: () => context
                                .read<VentaRapidaCubit>()
                                .decrementarProducto(producto.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                              child: Icon(Icons.remove, size: 16, color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined,
            color: Colors.grey.shade400, size: 32),
      );
}

/// Dialog full-screen para ver imágenes del producto con zoom y swipe.
/// Si hay varias imágenes, navega entre ellas con PageView.
class _ImagenZoomDialog extends StatefulWidget {
  final List<String> imagenes;
  final String nombreProducto;

  const _ImagenZoomDialog({
    required this.imagenes,
    required this.nombreProducto,
  });

  @override
  State<_ImagenZoomDialog> createState() => _ImagenZoomDialogState();
}

class _ImagenZoomDialogState extends State<_ImagenZoomDialog> {
  late final PageController _pageCtrl;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tieneVarias = widget.imagenes.length > 1;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // PageView con InteractiveViewer (zoom + pan)
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    widget.imagenes[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    },
                  ),
                ),
              );
            },
          ),

          // Header con título + cerrar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.black.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.nombreProducto.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tieneVarias)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${_index + 1}/${widget.imagenes.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Indicadores de páginas (dots) si hay varias
          if (tieneVarias)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imagenes.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
