import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/custom_sede_selector.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/bulk_editar_stock_precios.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/edicion_masiva_stock/edicion_masiva_stock_cubit.dart';
import '../bloc/edicion_masiva_stock/edicion_masiva_stock_state.dart';

/// Grilla tipo excel para editar stock y precios de todas las variantes
/// de un producto en una sede, en bloque. Cada ajuste de stock genera
/// movimiento de kardex y cada cambio de precio queda en el historial.
class EdicionMasivaStockPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const EdicionMasivaStockPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<EdicionMasivaStockCubit>(),
      child: _EdicionMasivaView(
        productoId: productoId,
        productoNombre: productoNombre,
        sedeIdInicial: sedeIdInicial,
      ),
    );
  }
}

class _EdicionMasivaView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const _EdicionMasivaView({
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  State<_EdicionMasivaView> createState() => _EdicionMasivaViewState();
}

/// Controllers de una fila de la grilla (una variante).
class _FilaEdicion {
  final stock = TextEditingController();
  final precio = TextEditingController();
  final costo = TextEditingController();

  bool get tieneCambios =>
      stock.text.trim().isNotEmpty ||
      precio.text.trim().isNotEmpty ||
      costo.text.trim().isNotEmpty;

  void limpiar() {
    stock.clear();
    precio.clear();
    costo.clear();
  }

  void dispose() {
    stock.dispose();
    precio.dispose();
    costo.dispose();
  }
}

class _EdicionMasivaViewState extends State<_EdicionMasivaView> {
  String? _empresaId;
  String? _sedeId;
  List<dynamic> _sedes = [];
  final Map<String, _FilaEdicion> _filas = {};
  final _searchController = TextEditingController();

  static const _wStockActual = 52.0;
  static const _wAgregarStock = 68.0;
  static const _wPrecio = 78.0;
  static const _wCosto = 78.0;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      // Copia tipada como List<dynamic>: la lista original es List<SedeModel>
      // y un orElse que devuelve dynamic rompería firstWhere en runtime.
      _sedes =
          List<dynamic>.from(empresaState.context.sedes.where((s) => s.isActive));
      if (widget.sedeIdInicial != null &&
          _sedes.any((s) => s.id == widget.sedeIdInicial)) {
        _sedeId = widget.sedeIdInicial;
      } else if (_sedes.isNotEmpty) {
        _sedeId = _sedes
            .firstWhere((s) => s.esPrincipal, orElse: () => _sedes.first)
            .id;
      }
    }

    if (_empresaId != null) {
      context.read<EdicionMasivaStockCubit>().loadVariantes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
    }
  }

  @override
  void dispose() {
    for (final fila in _filas.values) {
      fila.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  _FilaEdicion _filaDe(String varianteId) =>
      _filas.putIfAbsent(varianteId, () => _FilaEdicion());

  int get _totalCambios => _filas.values.where((f) => f.tieneCambios).length;

  List<ProductoVariante> _filtrar(List<ProductoVariante> variantes) {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isEmpty) return variantes;
    return variantes
        .where((v) =>
            v.nombre.toLowerCase().contains(term) ||
            v.sku.toLowerCase().contains(term))
        .toList();
  }

  void _limpiarEdiciones() {
    for (final fila in _filas.values) {
      fila.limpiar();
    }
    setState(() {});
  }

  Future<void> _cambiarSede(String? nuevaSedeId) async {
    if (nuevaSedeId == null || nuevaSedeId == _sedeId) return;

    if (_totalCambios > 0) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cambiar de sede'),
          content: const Text(
              'Tienes cambios sin guardar. Al cambiar de sede se descartarán. ¿Continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar y cambiar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      _limpiarEdiciones();
    }

    setState(() => _sedeId = nuevaSedeId);
  }

  Future<void> _aplicarATodas(List<ProductoVariante> visibles) async {
    final stockCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final costoCtrl = TextEditingController();

    final aplicar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aplicar a ${visibles.length} variante(s)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Los campos vacíos no se aplican. Afecta solo a las variantes visibles (según el filtro).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [_soloEnteroConSigno],
              decoration: const InputDecoration(
                labelText: 'Agregar stock (+/-)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: precioCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_soloDecimal],
              decoration: const InputDecoration(
                labelText: 'Precio (S/)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_soloDecimal],
              decoration: const InputDecoration(
                labelText: 'Costo (S/)',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (aplicar == true) {
      for (final v in visibles) {
        final fila = _filaDe(v.id);
        if (stockCtrl.text.trim().isNotEmpty) fila.stock.text = stockCtrl.text.trim();
        if (precioCtrl.text.trim().isNotEmpty) fila.precio.text = precioCtrl.text.trim();
        if (costoCtrl.text.trim().isNotEmpty) fila.costo.text = costoCtrl.text.trim();
      }
      setState(() {});
    }

    stockCtrl.dispose();
    precioCtrl.dispose();
    costoCtrl.dispose();
  }

  Future<void> _guardar(List<ProductoVariante> variantes) async {
    if (_sedeId == null || _empresaId == null) return;

    final items = <BulkEditarItem>[];
    for (final v in variantes) {
      final fila = _filas[v.id];
      if (fila == null || !fila.tieneCambios) continue;

      final agregar = int.tryParse(fila.stock.text.trim());
      final precio = double.tryParse(fila.precio.text.trim());
      final costo = double.tryParse(fila.costo.text.trim());

      final item = BulkEditarItem(
        varianteId: v.id,
        agregarStock: agregar,
        precio: precio,
        precioCosto: costo,
      );
      if (item.tieneCambios) items.add(item);
    }

    if (items.isEmpty) return;

    final sedeNombre =
        _sedes.firstWhere((s) => s.id == _sedeId, orElse: () => null)?.nombre ??
            '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambios'),
        content: Text(
            'Se aplicarán cambios a ${items.length} variante(s) en la sede "$sedeNombre".\n\n'
            'Los ajustes de stock quedarán registrados en el kardex y los '
            'cambios de precio en el historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    context.read<EdicionMasivaStockCubit>().guardarCambios(
          sedeId: _sedeId!,
          empresaId: _empresaId!,
          productoId: widget.productoId,
          items: items,
          motivo: 'Edición masiva de inventario',
        );
  }

  static final _soloEnteroConSigno =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'));
  static final _soloDecimal =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Edición masiva',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white)),
            Text(
              widget.productoNombre,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white),
            ),
          ],
        ),
      ),
      body: BlocConsumer<EdicionMasivaStockCubit, EdicionMasivaStockState>(
        listener: (context, state) {
          if (state is EdicionMasivaStockSuccess) {
            _limpiarEdiciones();
            final r = state.resumen;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Guardado: ${r.stockAjustado} ajuste(s) de stock, '
                    '${r.preciosActualizados} precio(s) actualizados'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is EdicionMasivaStockError &&
              state.variantes.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EdicionMasivaStockLoading ||
              state is EdicionMasivaStockInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EdicionMasivaStockError && state.variantes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<EdicionMasivaStockCubit>()
                        .loadVariantes(
                          productoId: widget.productoId,
                          empresaId: _empresaId!,
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final variantes = switch (state) {
            EdicionMasivaStockLoaded s => s.variantes,
            EdicionMasivaStockSaving s => s.variantes,
            EdicionMasivaStockSuccess s => s.variantes,
            EdicionMasivaStockError s => s.variantes,
            _ => <ProductoVariante>[],
          };
          final visibles = _filtrar(variantes);
          final guardando = state is EdicionMasivaStockSaving;

          return Column(
            children: [
              _buildBarraSuperior(visibles),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final anchoMinimo = _wStockActual +
                        _wAgregarStock +
                        _wPrecio +
                        _wCosto +
                        160 + // columna variante
                        24; // padding
                    final ancho = constraints.maxWidth < anchoMinimo
                        ? anchoMinimo
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: ancho,
                        child: Column(
                          children: [
                            _buildHeaderGrilla(),
                            Expanded(
                              child: visibles.isEmpty
                                  ? const Center(
                                      child: Text('Sin variantes que mostrar'))
                                  : ListView.builder(
                                      itemCount: visibles.length,
                                      itemBuilder: (context, i) =>
                                          _buildFila(visibles[i], i),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBarraGuardar(variantes, guardando),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarraSuperior(List<ProductoVariante> visibles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.store, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              const Text('Sede:',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              if (_sedes.isNotEmpty)
                CustomSedeSelector(
                  sedes: _sedes,
                  currentSede: _sedes.firstWhere(
                    (s) => s.id == _sedeId,
                    orElse: () => _sedes.first,
                  ),
                  onSelected: _cambiarSede,
                ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Aplicar valor a todas las visibles',
                icon: const Icon(Icons.copy_all, size: 20),
                onPressed:
                    visibles.isEmpty ? null : () => _aplicarATodas(visibles),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar por nombre o SKU...',
            debounceDelay: const Duration(milliseconds: 200),
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGrilla() {
    const estilo = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    return Container(
      color: AppColors.blue1.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          Expanded(child: Text('Variante', style: estilo)),
          SizedBox(
              width: _wStockActual,
              child: Text('Stock', style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wAgregarStock,
              child:
                  Text('+ Stock', style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wPrecio,
              child: Text('Precio S/',
                  style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wCosto,
              child:
                  Text('Costo S/', style: estilo, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildFila(ProductoVariante variante, int index) {
    final fila = _filaDe(variante.id);
    final stockInfo = _sedeId != null ? variante.stockSedeInfo(_sedeId!) : null;
    final stockActual = stockInfo?.cantidad;
    final precioActual = stockInfo?.precio;
    final costoActual = stockInfo?.precioCosto;
    final editada = fila.tieneCambios;

    return Container(
      color: editada
          ? Colors.amber.withValues(alpha: 0.12)
          : index.isEven
              ? Colors.transparent
              : Colors.grey.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variante.nombre,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(variante.sku,
                    style: TextStyle(fontSize: 9, color: Colors.grey[600])),
              ],
            ),
          ),
          SizedBox(
            width: _wStockActual,
            child: Text(
              stockActual?.toString() ?? '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: (stockActual ?? 0) == 0 ? Colors.red : Colors.black87,
              ),
            ),
          ),
          SizedBox(
            width: _wAgregarStock,
            child: _celdaEditable(
              controller: fila.stock,
              hint: '0',
              formatter: _soloEnteroConSigno,
              signed: true,
            ),
          ),
          SizedBox(
            width: _wPrecio,
            child: _celdaEditable(
              controller: fila.precio,
              hint: precioActual?.toStringAsFixed(2) ?? '—',
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wCosto,
            child: _celdaEditable(
              controller: fila.costo,
              hint: costoActual?.toStringAsFixed(2) ?? '—',
              formatter: _soloDecimal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _celdaEditable({
    required TextEditingController controller,
    required String hint,
    required TextInputFormatter formatter,
    bool signed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        keyboardType: TextInputType.numberWithOptions(
            signed: signed, decimal: !signed),
        inputFormatters: [formatter],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 10, color: Colors.grey[400]),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildBarraGuardar(List<ProductoVariante> variantes, bool guardando) {
    final cambios = _totalCambios;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (cambios > 0)
              TextButton.icon(
                onPressed: guardando ? null : _limpiarEdiciones,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Descartar', style: TextStyle(fontSize: 12)),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed:
                  cambios == 0 || guardando ? null : () => _guardar(variantes),
              icon: guardando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(
                guardando ? 'Guardando...' : 'Guardar ($cambios)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
