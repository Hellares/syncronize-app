import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../features/producto/domain/entities/producto_list_item.dart';
import '../../../features/producto/domain/entities/producto_variante.dart';
import '../../di/injection_container.dart';
import '../../fonts/app_text_widgets.dart';
import '../../theme/app_colors.dart';
import '../custom_sede_selector.dart';
import '../custom_dropdown.dart';
import 'producto_sede_search_cubit.dart';
import 'producto_sede_search_state.dart';

/// Callback cuando se selecciona un producto (y opcionalmente una variante)
typedef OnProductoSeleccionado = void Function({
  required ProductoListItem producto,
  required String sedeId,
  ProductoVariante? variante,
});

/// Formatea el label de un producto para el dropdown.
/// Sobreescribir para personalizar la visualización global.
typedef ProductoLabelBuilder = String Function(ProductoListItem producto);

/// Widget reutilizable para seleccionar productos con filtro por sede
///
/// Características:
/// - Selector de sede (opcional)
/// - Búsqueda de productos con debouncing
/// - Preserva la lista visible durante loading (no parpadeo)
/// - Cache con límite (50 entradas)
/// - Configurable: label, formato, filtros
class ProductoSedeSelector extends StatefulWidget {
  final String empresaId;
  final String? sedeIdInicial;
  final bool mostrarSelectorSede;
  final OnProductoSeleccionado? onProductoSeleccionado;
  final int limite;
  final String label;
  final String hintText;
  final bool soloProductos;
  final ProductoLabelBuilder? labelBuilder;
  final String? emptyMessage;

  const ProductoSedeSelector({
    super.key,
    required this.empresaId,
    this.sedeIdInicial,
    this.mostrarSelectorSede = true,
    this.onProductoSeleccionado,
    this.limite = 100,
    this.label = 'Selecciona un producto *',
    this.hintText = 'Buscar producto...',
    this.soloProductos = true,
    this.labelBuilder,
    this.emptyMessage,
  });

  @override
  State<ProductoSedeSelector> createState() => _ProductoSedeSelectorState();
}

class _ProductoSedeSelectorState extends State<ProductoSedeSelector> {
  late String? _sedeSeleccionadaId;
  ProductoListItem? _productoSeleccionado;
  ProductoVariante? _varianteSeleccionada;
  late final ProductoSedeSearchCubit _cubit;

  @override
  void initState() {
    super.initState();
    _sedeSeleccionadaId = widget.sedeIdInicial;
    _cubit = locator<ProductoSedeSearchCubit>();

    if (_sedeSeleccionadaId != null) {
      _cubit.searchProductos(
        empresaId: widget.empresaId,
        sedeId: _sedeSeleccionadaId,
        limit: widget.limite,
        soloProductos: widget.soloProductos,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProductoSedeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia la empresa, resetear todo
    if (oldWidget.empresaId != widget.empresaId) {
      _cubit.reset();
      setState(() {
        _sedeSeleccionadaId = widget.sedeIdInicial;
        _productoSeleccionado = null;
        _varianteSeleccionada = null;
      });
      if (_sedeSeleccionadaId != null) {
        _buscarProductos();
      }
      return;
    }

    // Si cambia la sede inicial desde el padre
    if (oldWidget.sedeIdInicial != widget.sedeIdInicial &&
        widget.sedeIdInicial != _sedeSeleccionadaId) {
      _onSedeChanged(widget.sedeIdInicial!);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _defaultLabelBuilder(ProductoListItem producto) {
    final precio = _sedeSeleccionadaId != null
        ? (producto.precioEnSede(_sedeSeleccionadaId!) ?? 0.0)
        : 0.0;
    return '${producto.nombre} | S/ ${precio.toStringAsFixed(2)} | Stock: ${producto.stockTotal}';
  }

  void _buscarProductos({String? query}) {
    if (_sedeSeleccionadaId == null) return;

    _cubit.searchProductos(
      empresaId: widget.empresaId,
      sedeId: _sedeSeleccionadaId,
      query: query,
      limit: widget.limite,
      soloProductos: widget.soloProductos,
    );
  }

  void _onSedeChanged(String sedeId) {
    setState(() {
      _sedeSeleccionadaId = sedeId;
      _productoSeleccionado = null;
      _varianteSeleccionada = null;
    });
    _cubit.clearCache();
    _buscarProductos();
  }

  void _onProductoSeleccionado(ProductoListItem producto) {
    setState(() {
      _productoSeleccionado = producto;
      _varianteSeleccionada = null;
    });

    // Si el producto no tiene variantes, disparar callback inmediatamente
    if (!producto.tieneVariantes ||
        producto.variantes == null ||
        producto.variantes!.isEmpty) {
      widget.onProductoSeleccionado?.call(
        producto: producto,
        sedeId: _sedeSeleccionadaId!,
        variante: null,
      );
    }
    // Si tiene variantes, esperar a que el usuario seleccione una
  }

  void _onVarianteSeleccionada(ProductoVariante variante) {
    setState(() {
      _varianteSeleccionada = variante;
    });

    widget.onProductoSeleccionado?.call(
      producto: _productoSeleccionado!,
      sedeId: _sedeSeleccionadaId!,
      variante: variante,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.mostrarSelectorSede) ...[
            _buildSedeSelector(),
            const SizedBox(height: 16),
          ],
          _buildProductosList(),
          if (_productoSeleccionado != null &&
              _productoSeleccionado!.tieneVariantes &&
              _productoSeleccionado!.variantes != null &&
              _productoSeleccionado!.variantes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildVarianteDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildSedeSelector() {
    final empresaState = context.watch<EmpresaContextCubit>().state;

    if (empresaState is! EmpresaContextLoaded ||
        empresaState.context.sedes.isEmpty) {
      return const SizedBox.shrink();
    }

    final sedes = empresaState.context.sedes;
    final sedeActual = sedes.firstWhereOrNull(
      (s) => s.id == _sedeSeleccionadaId,
    ) ?? sedes.first;

    return Row(
      children: [
        Icon(Icons.store, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        AppSubtitle('Sede:', fontSize: 13),
        const SizedBox(width: 8),
        CustomSedeSelector(
          sedes: sedes,
          currentSede: sedeActual,
          onSelected: _onSedeChanged,
        ),
      ],
    );
  }

  Widget _buildProductosList() {
    final labelBuilder = widget.labelBuilder ?? _defaultLabelBuilder;

    return BlocBuilder<ProductoSedeSearchCubit, ProductoSedeSearchState>(
      builder: (context, state) {
        // Estado inicial sin sede seleccionada
        if (state is ProductoSedeSearchInitial) {
          if (_sedeSeleccionadaId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Selecciona una sede para ver productos',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error: mostrar mensaje con productos previos si existen
        if (state is ProductoSedeSearchError) {
          if (state.productosActuales.isNotEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown(state.productosActuales, labelBuilder),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          state.message,
                          style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                        ),
                      ),
                      InkWell(
                        onTap: _buscarProductos,
                        child: Text(
                          'Reintentar',
                          style: TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text(
                  'Error: ${state.message}',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _buscarProductos,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Obtener productos (del estado actual o anteriores durante loading/debouncing)
        final productos = state.productosActuales;
        final isLoading = state is ProductoSedeSearchLoading ||
            state is ProductoSedeSearchDebouncing;

        // Loading sin productos previos: spinner
        if (isLoading && productos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Sin productos
        if (productos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    widget.emptyMessage ?? 'No hay productos disponibles en esta sede',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Dropdown con productos (opacidad reducida si está cargando)
        return Stack(
          children: [
            Opacity(
              opacity: isLoading ? 0.6 : 1.0,
              child: _buildDropdown(productos, labelBuilder),
            ),
            if (isLoading)
              const Positioned(
                right: 8,
                top: 8,
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }

  String _varianteLabelBuilder(ProductoVariante variante) {
    final sedeId = _sedeSeleccionadaId;
    final precio = sedeId != null
        ? (variante.precioEnSede(sedeId) ?? 0.0)
        : 0.0;
    final stock = sedeId != null
        ? (variante.stockEnSede(sedeId) ?? variante.stockTotal)
        : variante.stockTotal;
    return '${variante.nombre} | S/ ${precio.toStringAsFixed(2)} | Stock: $stock';
  }

  Widget _buildVarianteDropdown() {
    final variantesActivas = _productoSeleccionado!.variantes!
        .where((v) => v.isActive)
        .toList();

    if (variantesActivas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No hay variantes activas para este producto',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      );
    }

    return CustomDropdown<ProductoVariante>(
      label: 'Selecciona una variante *',
      hintText: 'Buscar variante...',
      value: _varianteSeleccionada,
      items: variantesActivas.map((variante) {
        return DropdownItem<ProductoVariante>(
          value: variante,
          label: _varianteLabelBuilder(variante),
        );
      }).toList(),
      onChanged: (variante) {
        if (variante != null) {
          _onVarianteSeleccionada(variante);
        }
      },
      dropdownStyle: DropdownStyle.searchable,
      showSearchBox: variantesActivas.length > 5,
      borderColor: AppColors.blue1,
    );
  }

  Widget _buildDropdown(
    List<ProductoListItem> productos,
    ProductoLabelBuilder labelBuilder,
  ) {
    return CustomDropdown<ProductoListItem>(
      label: widget.label,
      hintText: widget.hintText,
      value: _productoSeleccionado,
      items: productos.map((producto) {
        return DropdownItem<ProductoListItem>(
          value: producto,
          label: labelBuilder(producto),
        );
      }).toList(),
      onChanged: (producto) {
        if (producto != null) {
          _onProductoSeleccionado(producto);
        }
      },
      dropdownStyle: DropdownStyle.searchable,
      showSearchBox: true,
      borderColor: AppColors.blue1,
    );
  }
}
