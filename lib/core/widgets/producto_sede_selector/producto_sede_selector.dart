import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  String? _barcodeSearchPending;

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
      _barcodeSearchPending = null;
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
    _barcodeSearchPending = null;
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

  /// Abre el escáner de código de barras y busca el producto
  Future<void> _escanearCodigoBarras() async {
    if (_sedeSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una sede primero')),
      );
      return;
    }

    final codigo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => _BarcodeScannerSheet(),
    );

    if (codigo == null || codigo.isEmpty || !mounted) return;

    // Marcar que estamos esperando resultado de barcode
    setState(() => _barcodeSearchPending = codigo);

    _cubit.searchProductos(
      empresaId: widget.empresaId,
      sedeId: _sedeSeleccionadaId,
      query: codigo,
      limit: widget.limite,
      soloProductos: widget.soloProductos,
    );
  }

  /// Llamado desde el BlocListener cuando llega un resultado de búsqueda por barcode
  void _handleBarcodeResult(ProductoSedeSearchState state) {
    if (_barcodeSearchPending == null) return;

    if (state is ProductoSedeSearchLoaded) {
      final codigo = _barcodeSearchPending!;
      _barcodeSearchPending = null;

      if (state.productos.length == 1) {
        _onProductoSeleccionado(state.productos.first);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto encontrado: ${state.productos.first.nombre}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (state.productos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontro producto con codigo: $codigo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Si hay varios, el dropdown los muestra
    } else if (state is ProductoSedeSearchError) {
      _barcodeSearchPending = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ProductoSedeSearchCubit, ProductoSedeSearchState>(
        listener: (context, state) => _handleBarcodeResult(state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.mostrarSelectorSede) ...[
              _buildSedeSelector(),
              const SizedBox(height: 5),
            ],
            _buildProductosListWithScanner(),
            if (_productoSeleccionado != null &&
                _productoSeleccionado!.tieneVariantes &&
                _productoSeleccionado!.variantes != null &&
                _productoSeleccionado!.variantes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildVarianteDropdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductosListWithScanner() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildProductosList()),
        // const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: IconButton(
            onPressed: _escanearCodigoBarras,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            color: AppColors.blue1,
            tooltip: 'Escanear codigo de barras',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
             ),
          ),
        ),
      ],
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
        AppSubtitle('Sede:', fontSize: 12),
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
          return const SizedBox.shrink();
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
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red[400]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.message,
                    style: TextStyle(fontSize: 12, color: Colors.red[400]),
                  ),
                ),
                InkWell(
                  onTap: _buscarProductos,
                  child: Text(
                    'Reintentar',
                    style: TextStyle(fontSize: 12, color: AppColors.blue1, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        // Obtener productos (del estado actual o anteriores durante loading/debouncing)
        final productos = state.productosActuales;
        final isLoading = state is ProductoSedeSearchLoading ||
            state is ProductoSedeSearchDebouncing;

        // Loading sin productos previos: no mostrar nada (evita salto visual)
        if (isLoading && productos.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sin productos — texto compacto debajo del dropdown
        if (productos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.emptyMessage ?? 'No se encontraron productos',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

/// Bottom sheet para escanear código de barras con protección contra
/// múltiples detecciones y manejo correcto del lifecycle del controller.
class _BarcodeScannerSheet extends StatefulWidget {
  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasDetected) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _hasDetected = true;
                _controller.stop();
                Navigator.of(context).pop(barcodes.first.rawValue);
              }
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al codigo de barras',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
