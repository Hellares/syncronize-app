import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/barcode_item.dart';
import '../bloc/barcode_generator_cubit.dart';
import '../bloc/barcode_generator_state.dart';
import '../services/barcode_pdf_service.dart';

class BarcodeGeneratorPage extends StatelessWidget {
  const BarcodeGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<BarcodeGeneratorCubit>()..loadProductosSinBarcode(),
      child: const _BarcodeGeneratorView(),
    );
  }
}

class _BarcodeGeneratorView extends StatefulWidget {
  const _BarcodeGeneratorView();

  @override
  State<_BarcodeGeneratorView> createState() => _BarcodeGeneratorViewState();
}

class _BarcodeGeneratorViewState extends State<_BarcodeGeneratorView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Generador de Códigos',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Generar Códigos', icon: Icon(Icons.qr_code, size: 18)),
            Tab(text: 'Imprimir Etiquetas', icon: Icon(Icons.print, size: 18)),
          ],
        ),
      ),
      body: GradientBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _GenerarCodigosTab(),
            _ImprimirEtiquetasTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1: GENERAR CÓDIGOS
// ══════════════════════════════════════════════════════════════════════════════

class _GenerarCodigosTab extends StatefulWidget {
  const _GenerarCodigosTab();

  @override
  State<_GenerarCodigosTab> createState() => _GenerarCodigosTabState();
}

class _GenerarCodigosTabState extends State<_GenerarCodigosTab> {
  final Set<String> _selectedIds = {};
  String _formato = 'INTERNO';

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<BarcodeItem> items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(items.map((e) => e.productoId));
      }
    });
  }

  Future<void> _generarCodigos() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto')),
      );
      return;
    }
    await context.read<BarcodeGeneratorCubit>().generarCodigos(
          _selectedIds.toList(),
          _formato,
        );
    if (mounted) {
      setState(() => _selectedIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodeGeneratorCubit, BarcodeGeneratorState>(
      builder: (context, state) {
        if (state is BarcodeGeneratorLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BarcodeGeneratorError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.read<BarcodeGeneratorCubit>().reload(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is BarcodeGeneratorGenerating) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando códigos...', style: TextStyle(fontSize: 14)),
              ],
            ),
          );
        }
        if (state is BarcodeGeneratorGenerated) {
          return _buildGeneratedResult(state);
        }
        if (state is BarcodeGeneratorLoaded) {
          return _buildProductList(state.productosSinBarcode);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductList(List<BarcodeItem> productos) {
    return RefreshIndicator(
      onRefresh: () => context.read<BarcodeGeneratorCubit>().reload(),
      color: AppColors.blue1,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: _selectedIds.isNotEmpty ? 80 : 12,
            ),
            children: [
              // Resumen card
              GradientContainer(
                borderColor: AppColors.blueborder,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2, size: 32, color: Colors.indigo),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSubtitle(
                              '${productos.length} productos sin código',
                              fontSize: 15,
                              color: AppColors.blue1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selecciona productos para generar códigos de barras',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Formato selector
              GradientContainer(
                borderColor: AppColors.blueborder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, size: 18, color: AppColors.blue1),
                      const SizedBox(width: 10),
                      const Text('Formato:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _formato,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              items: const [
                                DropdownMenuItem(value: 'INTERNO', child: Text('Interno (Code128)')),
                                DropdownMenuItem(value: 'EAN-13', child: Text('EAN-13')),
                              ],
                              onChanged: (v) => setState(() => _formato = v ?? 'INTERNO'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Select all header
              if (productos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedIds.length == productos.length && productos.isNotEmpty,
                        tristate: true,
                        onChanged: (_) => _selectAll(productos),
                        activeColor: AppColors.blue1,
                      ),
                      Text(
                        'Seleccionar todos (${productos.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              // Product list
              if (productos.isEmpty)
                GradientContainer(
                  borderColor: Colors.green.shade200,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Todos los productos tienen código de barras',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                GradientContainer(
                  borderColor: AppColors.blueborder,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: productos.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = productos[index];
                      final isSelected = _selectedIds.contains(item.productoId);
                      return InkWell(
                        onTap: () => _toggleSelection(item.productoId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(item.productoId),
                                activeColor: AppColors.blue1,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nombre,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (item.codigoEmpresa != null && item.codigoEmpresa!.isNotEmpty) ...[
                                          Text(
                                            item.codigoEmpresa!,
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (item.sedeNombre != null) ...[
                                          Icon(Icons.store, size: 10, color: Colors.grey.shade500),
                                          const SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              item.sedeNombre!,
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Stock: ${item.stockActual}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: item.stockActual > 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  if (item.precio != null)
                                    Text(
                                      'S/ ${item.precio!.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),

          // Bottom action bar
          if (_selectedIds.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedIds.length} seleccionados',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _generarCodigos,
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('Generar códigos', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneratedResult(BarcodeGeneratorGenerated state) {
    final result = state.result;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Success header
        GradientContainer(
          borderColor: Colors.green.shade300,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, size: 32, color: Colors.green),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        '${result.generados} códigos generados',
                        fontSize: 15,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Los códigos se asignaron exitosamente',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Generated codes list
        const AppSubtitle('Códigos generados', fontSize: 14, color: AppColors.blue1),
        const SizedBox(height: 8),
        GradientContainer(
          borderColor: AppColors.blueborder,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: result.resultados.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final codigo = result.resultados[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_2, size: 20, color: Colors.indigo),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            codigo.nombre,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  codigo.tipo,
                                  style: const TextStyle(fontSize: 9, color: Colors.indigo),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  codigo.codigo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Back button
        Center(
          child: FilledButton.icon(
            onPressed: () => context.read<BarcodeGeneratorCubit>().reload(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver a lista', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue1,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2: IMPRIMIR ETIQUETAS
// ══════════════════════════════════════════════════════════════════════════════

class _ImprimirEtiquetasTab extends StatefulWidget {
  const _ImprimirEtiquetasTab();

  @override
  State<_ImprimirEtiquetasTab> createState() => _ImprimirEtiquetasTabState();
}

class _ImprimirEtiquetasTabState extends State<_ImprimirEtiquetasTab> {
  final List<BarcodeItem> _selectedProducts = [];

  // Config
  String _tamano = '50x25';
  bool _mostrarNombre = true;
  bool _mostrarPrecio = true;
  bool _mostrarSku = false;
  bool _generatingPdf = false;

  String? _empresaId;
  String? _sedeId;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _sedeId = empresaState.context.sedePrincipal?.id;
    }
  }

  void _addProduct(String productoId, String nombre, String? codigoBarras, double? precio) {
    if (codigoBarras == null || codigoBarras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este producto no tiene código de barras. Genéralo primero.')),
      );
      return;
    }
    final exists = _selectedProducts.any((p) => p.productoId == productoId);
    if (!exists) {
      setState(() {
        _selectedProducts.add(BarcodeItem(
          id: productoId,
          productoId: productoId,
          nombre: nombre,
          codigoBarras: codigoBarras,
          precio: precio,
        ));
      });
    }
  }

  void _removeProduct(int index) {
    setState(() => _selectedProducts.removeAt(index));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = _selectedProducts[index];
      final newQty = (current.cantidadEtiquetas + delta).clamp(1, 999);
      _selectedProducts[index] = current.copyWith(cantidadEtiquetas: newQty);
    });
  }

  Future<void> _generarPdf() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    setState(() => _generatingPdf = true);

    try {
      final parts = _tamano.split('x');
      final anchoMm = double.tryParse(parts[0]) ?? 50;
      final altoMm = double.tryParse(parts[1]) ?? 25;

      final config = ConfiguracionEtiqueta(
        anchoMm: anchoMm,
        altoMm: altoMm,
        tipoBarcode: 'Auto',
        mostrarNombre: _mostrarNombre,
        mostrarPrecio: _mostrarPrecio,
        mostrarSku: _mostrarSku,
      );

      final etiquetas = _selectedProducts
          .map((p) => EtiquetaData(
                nombre: p.nombre,
                codigoBarras: p.codigoBarras!,
                precio: p.precio,
                sku: p.sku,
                cantidad: p.cantidadEtiquetas,
              ))
          .toList();

      final pdfBytes = await BarcodePdfService.generarEtiquetas(
        items: etiquetas,
        config: config,
      );

      if (mounted) {
        await BarcodePdfService.preview(context, pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Product selector
        if (_empresaId != null)
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle('Seleccionar producto', fontSize: 14, color: AppColors.blue1),
                  const SizedBox(height: 8),
                  ProductoSedeSelector(
                    empresaId: _empresaId!,
                    sedeIdInicial: _sedeId,
                    mostrarSelectorSede: false,
                    label: 'Buscar producto para etiquetar',
                    hintText: 'Nombre, código o escanear...',
                    onProductoSeleccionado: ({required producto, required sedeId, variante}) {
                      final stocks = producto.stocksPorSede;
                      final precio = (stocks != null && stocks.isNotEmpty)
                          ? stocks.first.precio
                          : null;
                      final barcode = variante?.codigoBarras ?? producto.codigoEmpresa;
                      _addProduct(
                        producto.id,
                        variante != null ? '${producto.nombre} - ${variante.nombre}' : producto.nombre,
                        barcode,
                        precio,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Selected products
        const AppSubtitle('Productos seleccionados', fontSize: 14, color: AppColors.blue1),
        const SizedBox(height: 8),
        if (_selectedProducts.isEmpty)
          GradientContainer(
            borderColor: Colors.grey.shade300,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.print, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Busca y agrega productos para imprimir etiquetas',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: _selectedProducts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = _selectedProducts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // Remove button
                      InkWell(
                        onTap: () => _removeProduct(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.remove_circle, size: 20, color: Colors.red.shade400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombre,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.codigoBarras ?? '',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _updateQuantity(index, -1),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              color: Colors.grey.shade50,
                              child: Text(
                                '${item.cantidadEtiquetas}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            InkWell(
                              onTap: () => _updateQuantity(index, 1),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),

        // Configuration section
        const AppSubtitle('Configuración de etiqueta', fontSize: 14, color: AppColors.blue1),
        const SizedBox(height: 8),
        GradientContainer(
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Size
                _buildConfigRow(
                  icon: Icons.aspect_ratio,
                  label: 'Tamaño',
                  child: _buildConfigDropdown<String>(
                    value: _tamano,
                    items: const [
                      DropdownMenuItem(value: '50x25', child: Text('50 x 25 mm')),
                      DropdownMenuItem(value: '40x20', child: Text('40 x 20 mm')),
                      DropdownMenuItem(value: '70x30', child: Text('70 x 30 mm')),
                    ],
                    onChanged: (v) => setState(() => _tamano = v ?? '50x25'),
                  ),
                ),
                Divider(height: 16, color: Colors.grey.shade200),

                // Toggles
                _buildToggleRow(
                  icon: Icons.text_fields,
                  label: 'Mostrar nombre',
                  value: _mostrarNombre,
                  onChanged: (v) => setState(() => _mostrarNombre = v),
                ),
                _buildToggleRow(
                  icon: Icons.attach_money,
                  label: 'Mostrar precio',
                  value: _mostrarPrecio,
                  onChanged: (v) => setState(() => _mostrarPrecio = v),
                ),
                _buildToggleRow(
                  icon: Icons.tag,
                  label: 'Mostrar SKU',
                  value: _mostrarSku,
                  onChanged: (v) => setState(() => _mostrarSku = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Preview button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _generatingPdf ? null : _generarPdf,
            icon: _generatingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf, size: 18),
            label: Text(
              _generatingPdf ? 'Generando PDF...' : 'Vista previa PDF',
              style: const TextStyle(fontSize: 14),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConfigRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.blue1),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        SizedBox(width: 140, child: child),
      ],
    );
  }

  Widget _buildConfigDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue1),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.blue1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
