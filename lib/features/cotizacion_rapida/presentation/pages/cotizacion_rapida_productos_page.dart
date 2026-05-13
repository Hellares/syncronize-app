import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';
import '../../../venta_rapida/presentation/widgets/precios_mayor_sheet.dart';
import '../bloc/cotizacion_rapida_cubit.dart';
import '../widgets/item_manual_dialog.dart';

/// Pantalla de selección de productos para cotización rápida.
/// Patrón idéntico a `VentaRapidaProductosPage` con dos diferencias:
/// - Toggle "Simple / Para Venta" en el header.
/// - Botón "+ Item Manual" cuando es Simple.
///
/// Se usa también en modo edición de cotización (la wrapper provee el cubit
/// con `cargarParaEdicion()` y modoEdicion=true). El header y el botón del
/// carrito reaccionan a `state.modoEdicion`.
class CotizacionRapidaProductosPage extends StatelessWidget {
  /// Cuando es true, asume que el `CotizacionRapidaCubit` y el
  /// `ProductoListCubit` ya están provistos arriba en el árbol (caso
  /// editar); el widget no los reinicializa.
  final bool embebida;

  const CotizacionRapidaProductosPage({super.key}) : embebida = false;
  const CotizacionRapidaProductosPage.embebida({super.key}) : embebida = true;

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

    // Modo embebida: el wrapper (editar page) ya inyectó los cubits y llamó
    // `cargarParaEdicion`. Solo renderizamos la vista.
    if (embebida) {
      return _ProductosView(sedeId: sedeId);
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: () {
            final cubit = locator<CotizacionRapidaCubit>();
            cubit.setContexto(
              empresaId: empresaId!,
              sedeId: sedeId!,
              vendedorId: vendedorId!,
            );
            return cubit;
          }(),
        ),
        BlocProvider(
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

  void _autoAgregarSiMatchExacto(ProductoListLoaded state) {
    final code = _lastScannedCode;
    if (code == null) return;
    if (state.isFiltering) return;
    if (state.filtros.search != code) return;
    final ordenados = _ordenarPorStock(state.productos);
    if (ordenados.length != 1) {
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
    context.read<CotizacionRapidaCubit>().agregarProducto(p);
    _lastScannedCode = null;
    _searchCtrl.clear();
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

  Future<void> _agregarItemManual() async {
    final results = await showItemManualDialog(context);
    if (results == null || results.isEmpty || !mounted) return;
    context.read<CotizacionRapidaCubit>().agregarItemsManuales(
          results
              .map((r) => (
                    descripcion: r.descripcion,
                    cantidad: r.cantidad,
                    precioUnitario: r.precioUnitario,
                  ))
              .toList(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          results.length == 1
              ? '✓ Item manual agregado'
              : '✓ ${results.length} items manuales agregados',
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
          builder: (context, state) {
            return Row(
              children: [
                Text(
                  state.modoEdicion ? 'Editar items' : 'Cotización',
                  style: const TextStyle(fontSize: 18),
                ),
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
          BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
            builder: (context, state) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_checkout),
                    onPressed: state.items.isEmpty
                        ? null
                        : () => context
                            .push('/empresa/cotizaciones/nueva/carrito'),
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
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
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
      body: BlocListener<CotizacionRapidaCubit, CotizacionRapidaState>(
        listenWhen: (prev, curr) =>
            prev.comboPendienteOferta != curr.comboPendienteOferta &&
            curr.comboPendienteOferta != null,
        listener: (context, state) {
          _mostrarConfirmacionComboOferta(
              context, state.comboPendienteOferta!);
        },
        child: Column(
          children: [
            // Toggle tipo cotización + botón item manual
            BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
              buildWhen: (a, b) => a.tipoCotizacion != b.tipoCotizacion,
              builder: (context, state) {
                final esSimple =
                    state.tipoCotizacion == TipoCotizacionRapida.simple;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: TipoCotizacionRapida.simple,
                              label: Text('Simple', style: TextStyle(fontSize: 11)),
                              icon: Icon(Icons.description_outlined, size: 14),
                            ),
                            ButtonSegment(
                              value: TipoCotizacionRapida.paraVenta,
                              label: Text('Para Venta', style: TextStyle(fontSize: 11)),
                              icon: Icon(Icons.shopping_cart_outlined, size: 14),
                            ),
                          ],
                          selected: {state.tipoCotizacion},
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onSelectionChanged: (s) {
                            context
                                .read<CotizacionRapidaCubit>()
                                .setTipoCotizacion(s.first);
                          },
                        ),
                      ),
                      if (esSimple) ...[
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: _agregarItemManual,
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('Manual',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: CustomSearchField(
                controller: _searchCtrl,
                hintText: 'Buscar producto o escanear...',
                borderColor: AppColors.blue1,
                debounceDelay: const Duration(milliseconds: 400),
                height: 40,
                onChanged: (value) {
                  _lastScannedCode = null;
                  context.read<ProductoListCubit>().applyFiltros(
                        ProductoFiltros(search: value, isActive: true),
                      );
                },
                onClear: () {
                  _lastScannedCode = null;
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
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 32),
                  ),
                ],
              ),
            ),
            BlocBuilder<ProductoListCubit, ProductoListState>(
              buildWhen: (a, b) {
                final aF = a is ProductoListLoaded && a.isFiltering;
                final bF = b is ProductoListLoaded && b.isFiltering;
                return aF != bF;
              },
              builder: (_, state) {
                final filtrando =
                    state is ProductoListLoaded && state.isFiltering;
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
                      itemCount:
                          ordenados.length + (cargandoMas || hasMore ? 1 : 0),
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
                            context
                                .read<CotizacionRapidaCubit>()
                                .agregarProducto(p);
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

  Future<void> _mostrarConfirmacionComboOferta(
    BuildContext context,
    Combo combo,
  ) async {
    final cubit = context.read<CotizacionRapidaCubit>();
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
              'activa. ¿Cotizarlo de todas formas?',
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
            child: const Text('Cotizar combo'),
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

  double _qtyEnCarrito(CotizacionRapidaState state) {
    for (final i in state.items) {
      if (i.productoId == producto.id) return i.cantidad;
    }
    return 0;
  }

  void _abrirPreciosMayor(BuildContext context) {
    final cubit = context.read<CotizacionRapidaCubit>();
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

    return BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
      buildWhen: (prev, curr) {
        final prevQty = _qtyEnCarrito(prev);
        final currQty = _qtyEnCarrito(curr);
        return prevQty != currQty;
      },
      builder: (context, state) {
        final cantidadEnCarrito = _qtyEnCarrito(state);
        final estaEnCarrito = cantidadEnCarrito > 0;
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
              child: Stack(
                children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    AppColors.blue1.withValues(alpha: 0.05),
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
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child:
                                        imagen != null && imagen.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imagen,
                                                fit: BoxFit.cover,
                                                memCacheWidth: 200,
                                                placeholder: (_, __) =>
                                                    _placeholder(),
                                                errorWidget: (_, __, ___) =>
                                                    _placeholder(),
                                              )
                                            : _placeholder(),
                                  ),
                                ),
                              ),
                              Container(
                                width: 0.8,
                                color:
                                    AppColors.blue1.withValues(alpha: 0.05),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
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
                                    Container(
                                      height: 0.8,
                                      color: AppColors.blue1
                                          .withValues(alpha: 0.05),
                                    ),
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
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 10),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 2),
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
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(14)),
                              onTap: () => context
                                  .read<CotizacionRapidaCubit>()
                                  .decrementarProducto(producto.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 6),
                                child: Icon(Icons.remove,
                                    size: 16, color: Colors.green.shade700),
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
