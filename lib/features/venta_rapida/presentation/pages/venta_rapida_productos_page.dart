import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/realtime_sync_service.dart';
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
import '../widgets/producto_imagenes_sheet.dart';

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
              filtros: const ProductoFiltros(isActive: true, esInsumo: false),
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

  /// Búsqueda local (Fase 0): tipeo del cajero se filtra sobre los
  /// productos YA cargados en el state, sin pegar al server. Evita ~500ms
  /// de latencia por cada tipeo. Si no hay match local y `hasMore=true`,
  /// se dispara automáticamente la query remota con debounce — sin
  /// requerir que el cajero toque ningún botón.
  String _localQuery = '';

  /// Debounce para el fallback automático al server cuando el filtro
  /// local no devuelve nada. Evita gatillar request por cada letra.
  Timer? _serverFallbackDebounce;

  /// Listener al stream de [RealtimeSyncService]. Cuando llega un FCM
  /// data-only (precio/stock/niveles cambiados) hacemos reload del
  /// catálogo con debounce de 500ms para no spamear si caen N eventos
  /// en ráfaga (ej. admin haciendo varios cambios consecutivos).
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  Timer? _realtimeReloadDebounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _suscribirRealtime();
  }

  void _suscribirRealtime() {
    final realtime = locator<RealtimeSyncService>();
    _realtimeSubscription = realtime.events.listen((event) {
      // Cualquier evento (PRECIO/STOCK/NIVELES) implica que el catálogo
      // local puede estar desactualizado. Reload con debounce.
      _realtimeReloadDebounce?.cancel();
      _realtimeReloadDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        try {
          context.read<ProductoListCubit>().reload();
        } catch (_) {/* cubit no disponible en este momento */}
      });
    });
  }

  @override
  void dispose() {
    _realtimeReloadDebounce?.cancel();
    _realtimeSubscription?.cancel();
    _serverFallbackDebounce?.cancel();
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
    final codeTrim = code.trim();
    // OJO: setear el text dispara `onChanged` que pone _lastScannedCode
    // = null. Por eso lo re-asignamos DESPUÉS del set del text, no antes.
    _searchCtrl.text = codeTrim;
    _lastScannedCode = codeTrim;
    // Cancelamos el debounce de fallback server que el onChanged acaba
    // de programar — vamos a disparar applyFiltros directo, instantáneo
    // (es lo esperado tras un escaneo, no podemos esperar 500ms).
    _serverFallbackDebounce?.cancel();
    if (!mounted) return;
    context.read<ProductoListCubit>().applyFiltros(
          ProductoFiltros(
            search: codeTrim,
            isActive: true,
            esInsumo: false,
          ),
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
          const ProductoFiltros(isActive: true, esInsumo: false),
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

  /// Limpia toda la búsqueda activa: cancela el debounce pendiente,
  /// borra el filtro local, y si el cubit traía una búsqueda server
  /// activa (ej. tras auto-fallback o escaneo), resetea al listado
  /// base para que vuelva a mostrarse el catálogo completo.
  void _limpiarBusqueda() {
    _lastScannedCode = null;
    _serverFallbackDebounce?.cancel();
    setState(() => _localQuery = '');

    final listState = context.read<ProductoListCubit>().state;
    if (listState is ProductoListLoaded &&
        listState.filtros.search != null &&
        listState.filtros.search!.isNotEmpty) {
      context.read<ProductoListCubit>().applyFiltros(
            const ProductoFiltros(isActive: true, esInsumo: false),
            sedeId: widget.sedeId,
          );
    }
  }

  /// Programa una búsqueda en el servidor con debounce 500ms si el
  /// filtro local no encuentra nada. Solo se dispara cuando:
  ///  - la query tiene >= 2 caracteres (evita spam con 1 letra)
  ///  - el state actual permite paginación (`hasMore=true`) o ya viene
  ///    de una búsqueda remota (para resetear/refinar)
  ///  - ningún producto cargado matchea localmente.
  /// Si la query cambia antes de que termine el timer, se cancela.
  void _agendarFallbackServer(String value) {
    _serverFallbackDebounce?.cancel();
    if (value.length < 2) return;

    final cubit = context.read<ProductoListCubit>();
    final listState = cubit.state;
    if (listState is! ProductoListLoaded) return;

    final serverActual = listState.filtros.search ?? '';

    // Casos donde NO hace falta server:
    //  1) Server ya filtró por la misma query — el state ya es exacto.
    //  2) Catálogo entero está en cliente (sin paginación pendiente) y
    //     no hay search server activa → el filtro local es exhaustivo.
    //
    // En todos los otros casos vamos al server porque NO podemos saber
    // a priori si el cliente tiene TODOS los productos que matchean
    // (ej. cajero busca "oso", local tiene 1 oso pero server tiene 5).
    if (serverActual == value) return;
    if (!listState.hasMore && serverActual.isEmpty) return;

    _serverFallbackDebounce = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;
        if (_localQuery != value) return; // tipearon otra cosa
        context.read<ProductoListCubit>().applyFiltros(
              ProductoFiltros(
                search: value,
                isActive: true,
                esInsumo: false,
              ),
              sedeId: widget.sedeId,
            );
      },
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
              // Sin debounce: el filtro local es instantáneo. El server
              // solo se consulta si el cajero presiona el botón
              // "Buscar en servidor" cuando no hay match local.
              debounceDelay: Duration.zero,
              height: 40,
              onChanged: (value) {
                // Si el cajero edita manualmente, ya no es un código
                // escaneado — desactivamos el auto-add.
                _lastScannedCode = null;

                // Si la query queda vacía (borró todo letra a letra o
                // con backspace), tratamos igual que `onClear`: limpiar
                // estado local + resetear filtro server si lo había.
                if (value.isEmpty) {
                  _limpiarBusqueda();
                  return;
                }

                // Búsqueda LOCAL: filtra los productos ya cargados en
                // memoria sin pegar al server. Render <50ms.
                setState(() => _localQuery = value);
                // Auto-fallback al server: si el filtro local no
                // encuentra nada y el catálogo tiene más páginas,
                // disparamos `applyFiltros` con debounce 500ms para no
                // spamear requests por cada letra tipeada.
                _agendarFallbackServer(value);
              },
              onClear: () => _limpiarBusqueda(),
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
                // Atajo a "Nueva Cotización" (cotización rápida). El
                // catálogo de cotización maneja sus propios productos
                // y precios, por eso navegamos a su page completa, no
                // reusamos el cubit de VR.
                IconButton(
                  icon: const Icon(Icons.request_quote_outlined, size: 22),
                  color: AppColors.blue1,
                  onPressed: () =>
                      context.push('/empresa/cotizaciones/nueva'),
                  tooltip: 'Nueva cotización',
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

                // Fase 0: filtro local sobre los productos cargados.
                // Combina state actual + biblioteca de vistos (Fase 1.5)
                // para que una segunda búsqueda del mismo término sea
                // instantánea aunque el producto ya no esté en
                // state.productos.
                //
                // Si el server YA filtró por algo (codigoBarras u otra
                // query): el local solo "refina" — pero si el local
                // queda en 0 con server activo, mostramos lo del server
                // (caso típico: scanner devuelve match por codigoBarras
                // que el ProductoListItem no expone, entonces el filtro
                // local no encontraría nada aunque el server sí).
                final filtrosState = state is ProductoListLoaded
                    ? state.filtros
                    : null;
                final serverYaFiltro = filtrosState?.search != null &&
                    filtrosState!.search!.isNotEmpty;
                if (_localQuery.isNotEmpty) {
                  final q = _localQuery.toLowerCase();
                  final cubit = context.read<ProductoListCubit>();
                  final combinados = <String, ProductoListItem>{
                    for (final p in items) p.id: p,
                    ...cubit.vistosCache,
                  };
                  final localFiltrado = combinados.values.where((p) {
                    return p.nombre.toLowerCase().contains(q) ||
                        p.codigoEmpresa.toLowerCase().contains(q);
                  }).toList();
                  // Si encontramos algo local → usamos local. Si no Y
                  // el server ya filtró → confiamos en el server. Si no
                  // hay ni local ni server filtró → lista vacía.
                  if (localFiltrado.isNotEmpty || !serverYaFiltro) {
                    items = localFiltrado;
                  }
                  // else: dejamos `items` tal como vino del state (server).
                }

                if (items.isEmpty) {
                  final hayBusquedaLocal = _localQuery.isNotEmpty;
                  // Mientras el debounce dispara la búsqueda remota o el
                  // server está respondiendo, mostramos "Buscando…" con
                  // spinner — la búsqueda continúa automáticamente sin
                  // que el cajero toque nada.
                  final buscandoEnServidor = hayBusquedaLocal &&
                      (state is ProductoListLoaded && state.isFiltering ||
                          _serverFallbackDebounce?.isActive == true);
                  return RefreshIndicator(
                    onRefresh: () => context
                        .read<ProductoListCubit>()
                        .reload(sedeId: widget.sedeId),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: buscandoEnServidor
                                ? Column(
                                    children: [
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.blue1,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Buscando "$_localQuery" en el servidor…',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
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

  /// Devuelve los datos del item en carrito (precio con nivel aplicado y
  /// nombre del nivel) para que la card refleje el precio efectivo en vez
  /// del precio base. Si el producto no está en el carrito, devuelve null.
  ({double precioUnitario, String? nivelAplicado})? _itemInfoEnCarrito(
      VentaRapidaState state) {
    for (final i in state.items) {
      if (i.productoId == producto.id) {
        return (
          precioUnitario: i.precioUnitario,
          nivelAplicado: i.nivelAplicado,
        );
      }
    }
    return null;
  }

  /// Long-press de la card: abre el manager de imágenes del producto
  /// para que cualquier vendedor/cajero con acceso a VR pueda subir o
  /// eliminar fotos. Reemplaza al viejo `_ImagenZoomDialog` (que solo
  /// mostraba la imagen) — el manager ya incluye visualización ampliada
  /// al tocar cada imagen, así que cubre ambos casos.
  Future<void> _abrirImagenesManager(BuildContext context) async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;
    final empresaId = empresaState.context.empresa.id;
    final productoListCubit = context.read<ProductoListCubit>();

    final cambioGuardado = await showProductoImagenesSheet(
      context,
      productoId: producto.id,
      productoNombre: producto.nombre,
      empresaId: empresaId,
    );

    // Si se guardaron cambios (incluso si la imagen principal no
    // cambió), refrescamos el catálogo para que aparezca la nueva
    // imagen. Cero esfuerzo, el cubit ya recuerda los filtros.
    if (cambioGuardado == true) {
      productoListCubit.reload();
    }
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
        if (prevQty != currQty) return true;
        // También rebuild si cambió el nivel aplicado o el precio del item
        // (ej. niveles llegaron del backend tras la primera adición).
        final prevInfo = _itemInfoEnCarrito(prev);
        final currInfo = _itemInfoEnCarrito(curr);
        return prevInfo?.precioUnitario != currInfo?.precioUnitario ||
            prevInfo?.nivelAplicado != currInfo?.nivelAplicado;
      },
      builder: (context, state) {
        final cantidadEnCarrito = _qtyEnCarrito(state);
        final estaEnCarrito = cantidadEnCarrito > 0;
        // Precio mostrado: si el producto está en carrito y un nivel aplica,
        // usamos `precioUnitario` del item (ya recalculado por el cubit).
        // Si no, mostramos el precio base/efectivo del catálogo.
        final infoCarrito = _itemInfoEnCarrito(state);
        final precioMostrado = infoCarrito?.precioUnitario ?? precio;
        final nivelAplicado = infoCarrito?.nivelAplicado;
        final precioConNivelAplicado = nivelAplicado != null;
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
              onLongPress: () => _abrirImagenesManager(context),
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
                                    // Bloque inferior: UND/nivel + precio
                                    // Si hay nivel aplicado por cantidad, en
                                    // vez de "UND" mostramos el nombre del
                                    // nivel (ej "Por Mayor") y el precio
                                    // pasa a azul para destacar el cambio.
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              precioConNivelAplicado
                                                  ? nivelAplicado.toUpperCase()
                                                  : 'UND',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 7,
                                                color: precioConNivelAplicado
                                                    ? AppColors.blue1
                                                    : Colors.grey.shade600,
                                                fontWeight:
                                                    FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'S/ ${precioMostrado.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: precioConNivelAplicado
                                                  ? AppColors.blue1
                                                  : Colors.grey.shade800,
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
                // Badge LIQUIDACIÓN (top-left) cuando el producto está en
                // liquidación activa en la sede. Naranja oscuro para
                // diferenciarlo de la oferta normal y dejar claro al cajero
                // que el precio puede estar bajo costo. Considera tanto
                // producto base como variantes liquidadas.
                if (producto.tieneLiquidacionActivaEnSede(sedeId))
                  Positioned(
                    top: 33,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade700,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 9, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'LIQ.',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
                  child: CachedNetworkImage(
                    imageUrl: widget.imagenes[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    ),
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
