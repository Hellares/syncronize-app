import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Pantalla completa para gestionar la receta (BOM) de un producto
/// compuesto. Permite agregar/quitar/editar componentes y ver el costo
/// calculado. El botón "Aplicar al producto" actualiza el `precioCosto`
/// del producto en la sede seleccionada vía `/producto-stock/:id/precios`.
class ComponentesProductoPage extends StatefulWidget {
  /// ID del producto final (peluche, PC armada, etc.).
  final String productoId;
  final String productoNombre;

  /// Sede inicial. Si null, se elige la primera disponible. La elección
  /// determina de qué sede se toma el `precioCosto` de cada componente y
  /// a qué `productoStock` se aplicará el costo al pulsar "Aplicar".
  final String? sedeIdInicial;

  /// Si el producto está marcado como insumo, no se permite "Fabricar"
  /// (el backend lo rechaza igual, pero ocultamos el botón).
  final bool esInsumo;

  const ComponentesProductoPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
    this.esInsumo = false,
  });

  @override
  State<ComponentesProductoPage> createState() =>
      _ComponentesProductoPageState();
}

class _ComponentesProductoPageState extends State<ComponentesProductoPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = const [];
  String? _sedeId;
  String? _sedeNombre;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  bool _aplicando = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
      _sedeId = widget.sedeIdInicial ??
          (_sedes.isNotEmpty ? _sedes.first.id : null);
      if (_sedeId != null) {
        final match = _sedes.where((s) => s.id == _sedeId);
        _sedeNombre = match.isNotEmpty ? match.first.nombre : null;
      }
    }
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/componentes',
        queryParameters: _sedeId != null ? {'sedeId': _sedeId} : null,
      );
      if (!mounted) return;
      setState(() {
        _items = (resp.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
            : e.toString();
        _loading = false;
      });
    }
  }

  double get _costoTotal {
    double t = 0;
    for (final item in _items) {
      final subtotal = (item['subtotal'] as num?)?.toDouble();
      if (subtotal != null) t += subtotal;
    }
    return t;
  }

  bool get _algunoSinCosto => _items.any((i) => i['subtotal'] == null);

  Future<void> _agregar() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AgregarComponenteDialog(
        productoId: widget.productoId,
        sedeId: _sedeId,
        idsYaUsados: _items.map((i) => i['componenteId'] as String).toSet(),
      ),
    );
    if (result == true) _cargar();
  }

  Future<void> _editarCantidad(Map<String, dynamic> item) async {
    final controller = TextEditingController(
      text: (item['cantidad'] as num).toString(),
    );
    final um = item['componente']['unidadMedida'] as String?;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['componente']['nombre'] as String),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Cantidad (${um ?? '—'})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final nueva = double.tryParse(controller.text.replaceAll(',', '.'));
    if (nueva == null || nueva <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }
    try {
      await _dio.patch(
        '/productos/${widget.productoId}/componentes/${item['id']}',
        data: {'cantidad': nueva},
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar componente'),
        content: Text(
            '¿Quitar "${item['componente']['nombre']}" de la receta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _dio.delete(
        '/productos/${widget.productoId}/componentes/${item['id']}',
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Aplica el costo total calculado al `precioCosto` del producto en la
  /// sede actual. Resuelve primero el `productoStockId` correspondiente
  /// y llama a PATCH /producto-stock/:id/precios con tipoCambio=COSTO.
  Future<void> _aplicarAlProducto() async {
    if (_sedeId == null || _items.isEmpty || _costoTotal <= 0) return;
    setState(() => _aplicando = true);
    try {
      // 1. Resolver stock id para esta sede
      final stockResp = await _dio.get(
        '/producto-stock/producto/${widget.productoId}/sede/$_sedeId',
      );
      final stockId = (stockResp.data as Map?)?['id'] as String?;
      if (stockId == null) {
        throw 'No se encontró stock del producto en esta sede';
      }
      // 2. Actualizar solo el precioCosto + auditar como cálculo BOM
      await _dio.patch(
        '/producto-stock/$stockId/precios',
        data: {
          'precioCosto': double.parse(_costoTotal.toStringAsFixed(2)),
          'tipoCambio': 'COSTO',
          'razon':
              'Recalculo desde ${_items.length} componente(s) (BOM) - $_sedeNombre',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Precio Costo actualizado: S/ ${_costoTotal.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error al aplicar: ${e is DioException ? (e.response?.data?['message'] ?? e.message) : e}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _aplicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Componentes',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          showLogo: false,
          actions: !widget.esInsumo
              ? [
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Historial de fabricaciones',
                    onPressed: _verHistorial,
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  void _verHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorialFabricacionesSheet(
        productoId: widget.productoId,
        productoNombre: widget.productoNombre,
        sedeId: _sedeId,
        sedeNombre: _sedeNombre,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productoNombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (_sedes.length > 1)
            DropdownButtonFormField<String>(
              initialValue: _sedeId,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Sede (toma costos desde aquí)',
                labelStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
              ),
              items: _sedes
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nombre,
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _sedeId = v;
                  _sedeNombre = _sedes.firstWhere((s) => s.id == v).nombre;
                });
                _cargar();
              },
            )
          else if (_sedeNombre != null)
            Row(
              children: [
                Icon(Icons.store, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _sedeNombre!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 60, color: Colors.indigo.shade300),
              const SizedBox(height: 12),
              const Text(
                'Sin componentes definidos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Agregá los insumos que componen este producto.\nEl costo se calculará sumando cantidad × precio costo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100, width: 0.6),
      ),
      child: Column(
        children: [
          // Header tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 5, child: _Hcell('Componente')),
                Expanded(flex: 3, child: _Hcell('Cantidad', right: true)),
                Expanded(flex: 3, child: _Hcell('Costo', right: true)),
                Expanded(flex: 3, child: _Hcell('Subtotal', right: true)),
                SizedBox(width: 64),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (_, i) => _buildFila(_items[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 11,
                      child: Text(
                        'TOTAL',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'S/ ${_costoTotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
                if (_algunoSinCosto)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Algunos componentes no tienen precio costo en esta sede — el total es parcial.',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(Map<String, dynamic> item) {
    final cantidad = (item['cantidad'] as num).toDouble();
    final costoUnit = (item['precioCostoUnitario'] as num?)?.toDouble();
    final subtotal = (item['subtotal'] as num?)?.toDouble();
    final um = item['componente']['unidadMedida'] as String?;
    return InkWell(
      onTap: () => _editarCantidad(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['componente']['nombre'] as String,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (item['componente']['codigoEmpresa'] as String?) ?? '',
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${cantidad.toStringAsFixed(cantidad == cantidad.truncateToDouble() ? 0 : 3)} ${um ?? ''}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                costoUnit != null
                    ? 'S/ ${costoUnit.toStringAsFixed(2)}'
                    : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: costoUnit == null ? Colors.orange.shade700 : null,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                subtotal != null
                    ? 'S/ ${subtotal.toStringAsFixed(2)}'
                    : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtotal == null ? Colors.orange.shade700 : null,
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => _editarCantidad(item),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.edit,
                          size: 16, color: Colors.indigo.shade600),
                    ),
                  ),
                  InkWell(
                    onTap: () => _eliminar(item),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final puedeFabricar = !widget.esInsumo &&
        _items.isNotEmpty &&
        _sedeId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Agregar',
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    backgroundColor: Colors.indigo.shade600,
                    textColor: Colors.white,
                    enableShadows: false,
                    onPressed: _agregar,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'Aplicar a Costo',
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    backgroundColor: AppColors.blue1,
                    textColor: Colors.white,
                    enableShadows: false,
                    isLoading: _aplicando,
                    onPressed: (_items.isNotEmpty && _costoTotal > 0)
                        ? _aplicarAlProducto
                        : null,
                  ),
                ),
              ],
            ),
            if (puedeFabricar) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Fabricar',
                  icon: const Icon(Icons.precision_manufacturing_outlined,
                      size: 16, color: Colors.white),
                  backgroundColor: Colors.deepPurple.shade600,
                  textColor: Colors.white,
                  enableShadows: false,
                  onPressed: _fabricar,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Abre el dialog de Fabricar. Al confirmar, los stocks de los
  /// componentes se descuentan y se suma `cantidad` al producto final.
  /// Tras éxito refresca la lista (los costos no cambian pero los stocks
  /// de los insumos sí, importante para la próxima fabricación).
  Future<void> _fabricar() async {
    if (_sedeId == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FabricarDialog(
        productoId: widget.productoId,
        productoNombre: widget.productoNombre,
        sedeId: _sedeId!,
        sedeNombre: _sedeNombre,
        componentes: _items,
      ),
    );
    if (result == true && mounted) _cargar();
  }
}

// ─────────────────────────────────────────────────────────────────────────
//   Helpers de UI privados
// ─────────────────────────────────────────────────────────────────────────

class _Hcell extends StatelessWidget {
  final String text;
  final bool right;
  const _Hcell(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade800,
      ),
    );
  }
}

// =========================================================================
// Dialog para agregar componente: search de productos + cantidad.
// =========================================================================

class _AgregarComponenteDialog extends StatefulWidget {
  final String productoId;
  final String? sedeId;
  final Set<String> idsYaUsados;

  const _AgregarComponenteDialog({
    required this.productoId,
    required this.sedeId,
    required this.idsYaUsados,
  });

  @override
  State<_AgregarComponenteDialog> createState() =>
      _AgregarComponenteDialogState();
}

class _AgregarComponenteDialogState extends State<_AgregarComponenteDialog> {
  final DioClient _dio = locator<DioClient>();
  final _searchCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  Timer? _debounce;

  bool _searching = false;
  List<Map<String, dynamic>> _results = const [];
  Map<String, dynamic>? _selected;
  bool _saving = false;

  // Datos del componente seleccionado en la sede actual (costo + stockId)
  String? _selectedStockId;
  double? _selectedCosto;
  int? _selectedStockActual;
  bool _loadingStockInfo = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _buscar(q));
  }

  Future<void> _buscar(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final resp = await _dio.get(
        '/productos',
        queryParameters: {
          'search': q.trim(),
          'limit': 12,
          'isActive': 'true',
        },
      );
      final data = resp.data;
      final list = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['items'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _results = (list as List)
            .cast<Map<String, dynamic>>()
            .where((p) =>
                p['id'] != widget.productoId &&
                !widget.idsYaUsados.contains(p['id']))
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Tras seleccionar un componente, cargar su stock+costo en la sede para
  /// que el usuario vea de cuánto es el costo unitario y pueda corregirlo
  /// si está mal (caso típico: usuario tipeó total de compra en lugar de
  /// unitario). Si no hay sede o no hay stock, devuelve nulls.
  Future<void> _cargarInfoSeleccionado() async {
    if (_selected == null || widget.sedeId == null) return;
    setState(() {
      _loadingStockInfo = true;
      _selectedStockId = null;
      _selectedCosto = null;
      _selectedStockActual = null;
    });
    try {
      final resp = await _dio.get(
        '/producto-stock/producto/${_selected!['id']}/sede/${widget.sedeId}',
      );
      final data = resp.data as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _selectedStockId = data?['id'] as String?;
        final costoRaw = data?['precioCosto'];
        _selectedCosto = costoRaw is num
            ? costoRaw.toDouble()
            : (costoRaw is String ? double.tryParse(costoRaw) : null);
        _selectedStockActual = (data?['stockActual'] as num?)?.toInt();
        _loadingStockInfo = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStockInfo = false);
    }
  }

  /// Abre la calculadora "total ÷ cantidad" y, si el usuario aplica,
  /// actualiza el precioCosto del INSUMO (no del componente row) en la
  /// sede actual via PATCH /producto-stock/:id/precios.
  Future<void> _recalcularCostoInsumo() async {
    if (_selectedStockId == null) return;
    final nuevo = await showDialog<double>(
      context: context,
      builder: (_) => const _CalculadoraLoteDialogInline(),
    );
    if (nuevo == null) return;
    try {
      await _dio.patch(
        '/producto-stock/$_selectedStockId/precios',
        data: {
          'precioCosto': double.parse(nuevo.toStringAsFixed(2)),
          'tipoCambio': 'CORRECCION',
          'razon': 'Corrección de costo unitario desde page de componentes',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Costo actualizado: S/ ${nuevo.toStringAsFixed(2)}/u'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarInfoSeleccionado(); // refresca el costo mostrado
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInfoCostoInsumo() {
    if (_loadingStockInfo) {
      return const SizedBox(
        height: 14,
        child: Center(
          child: SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }
    if (_selectedCosto == null && _selectedStockId == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined,
                size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Este componente no tiene stock en la sede actual. Compralo o créalo manualmente para poder usarlo.',
                style: TextStyle(
                    fontSize: 10, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money,
              size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCosto != null
                      ? 'Costo unitario actual: S/ ${_selectedCosto!.toStringAsFixed(2)}'
                      : 'Sin costo unitario',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                if (_selectedStockActual != null)
                  Text(
                    'Stock: $_selectedStockActual unidades',
                    style: TextStyle(
                        fontSize: 9, color: Colors.blue.shade700),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: _recalcularCostoInsumo,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined,
                      size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'Recalcular',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_selected == null) return;
    final cantidad =
        double.tryParse(_cantidadCtrl.text.replaceAll(',', '.')) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá una cantidad > 0')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _dio.post(
        '/productos/${widget.productoId}/componentes',
        data: {
          'componenteId': _selected!['id'],
          'cantidad': cantidad,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DioException
                ? (e.response?.data?['message']?.toString() ?? 'Error')
                : e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_box_outlined,
                      color: Colors.indigo.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Agregar componente',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selected == null) ...[
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto (insumo)…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _searching
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                _searchCtrl.text.trim().length < 2
                                    ? 'Escribí al menos 2 caracteres'
                                    : 'Sin resultados',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (_, i) {
                                final p = _results[i];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(
                                    p['nombre']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    p['codigoEmpresa']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  onTap: () {
                                    setState(() => _selected = p);
                                    _cargarInfoSeleccionado();
                                  },
                                );
                              },
                            ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected!['nombre']?.toString() ?? '',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _selected!['codigoEmpresa']?.toString() ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        tooltip: 'Cambiar',
                        onPressed: () => setState(() {
                          _selected = null;
                          _selectedStockId = null;
                          _selectedCosto = null;
                          _selectedStockActual = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Info de costo del insumo en la sede actual. Permite
                // detectar de un vistazo si el costo unitario está mal
                // cargado (caso típico: total de compra en lugar de
                // unitario) y corregirlo desde acá.
                _buildInfoCostoInsumo(),
                const SizedBox(height: 12),
                CurrencyTextField(
                  label: 'Cantidad por unidad armada',
                  controller: _cantidadCtrl,
                  borderColor: AppColors.blue1,
                  allowZero: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'En unidad del componente. Ej: 0.05 si compraste por KG y usás 50g.',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancelar',
                        isOutlined: true,
                        textColor: AppColors.blue1,
                        borderColor: AppColors.blue1.withValues(alpha: 0.4),
                        enableShadows: false,
                        height: 36,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Agregar',
                        backgroundColor: AppColors.blue1,
                        textColor: Colors.white,
                        enableShadows: false,
                        isLoading: _saving,
                        height: 36,
                        icon: const Icon(Icons.check,
                            size: 14, color: Colors.white),
                        onPressed: _guardar,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Dialog "Fabricar N": preview de consumo + validación cliente + POST.
// =========================================================================

class _FabricarDialog extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String sedeId;
  final String? sedeNombre;

  /// Filas tal como las devuelve GET /productos/:id/componentes (con
  /// `cantidad`, `componente.nombre`, `componente.unidadMedida`).
  final List<Map<String, dynamic>> componentes;

  const _FabricarDialog({
    required this.productoId,
    required this.productoNombre,
    required this.sedeId,
    required this.sedeNombre,
    required this.componentes,
  });

  @override
  State<_FabricarDialog> createState() => _FabricarDialogState();
}

class _FabricarDialogState extends State<_FabricarDialog> {
  final DioClient _dio = locator<DioClient>();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _observacionesCtrl = TextEditingController();
  bool _fabricando = false;
  String? _error;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  int get _cantidad {
    return int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
  }

  /// Para cada componente: cuánto consume × N + si la cantidad consumida
  /// es entera (stock se maneja en Int, sino el backend rechaza) + cuánto
  /// hay disponible (de stockDisponible que devuelve el GET /componentes).
  List<_PreviewLinea> get _preview {
    return widget.componentes.map((item) {
      final cantidadPorUnidad = (item['cantidad'] as num).toDouble();
      final consumido = cantidadPorUnidad * _cantidad;
      final redondeado = consumido.round();
      final esEntero = (consumido - redondeado).abs() < 1e-6;
      final stock = (item['stockDisponible'] as num?)?.toInt();
      final excede = stock != null && esEntero && redondeado > stock;
      return _PreviewLinea(
        nombre: (item['componente']['nombre'] as String?) ?? '',
        unidadMedida: (item['componente']['unidadMedida'] as String?) ?? '',
        cantidadPorUnidad: cantidadPorUnidad,
        cantidadConsumida: consumido,
        esEntero: esEntero,
        stockDisponible: stock,
        excedeStock: excede,
      );
    }).toList();
  }

  bool get _hayFraccionarios => _preview.any((p) => !p.esEntero);
  bool get _hayInsuficiencia => _preview.any((p) => p.excedeStock);

  Future<void> _confirmar() async {
    if (_cantidad < 1) {
      setState(() => _error = 'Ingresá una cantidad ≥ 1');
      return;
    }
    if (_hayFraccionarios) {
      setState(() => _error =
          'Algún componente requiere cantidad fraccionaria. Cambia la unidad de medida (ej: KG→GR) o ajusta el lote.');
      return;
    }
    if (_hayInsuficiencia) {
      setState(() => _error =
          'Stock insuficiente en algún componente. Reducí la cantidad a fabricar o reabastecé el insumo.');
      return;
    }
    setState(() {
      _fabricando = true;
      _error = null;
    });
    try {
      final resp = await _dio.post(
        '/productos/${widget.productoId}/componentes/fabricar',
        data: {
          'sedeId': widget.sedeId,
          'cantidad': _cantidad,
          if (_observacionesCtrl.text.trim().isNotEmpty)
            'observaciones': _observacionesCtrl.text.trim(),
        },
      );
      final data = resp.data as Map<String, dynamic>?;
      if (!mounted) return;
      Navigator.pop(context, true);
      final costoAnt = (data?['precioCostoAnterior'] as num?)?.toDouble();
      final costoNuevo = (data?['precioCostoNuevo'] as num?)?.toDouble();
      final mostrarCosto = data?['costoActualizado'] == true &&
          costoNuevo != null &&
          costoNuevo != costoAnt;
      final base =
          'Fabricación OK · ${data?['cantidadProducida'] ?? _cantidad} '
          'unidad(es) · stock nuevo: ${data?['stockFinalNuevo'] ?? '—'} '
          '· lote ${data?['numeroDocumento'] ?? '—'}';
      final extraCosto = mostrarCosto
          ? '\nCosto: S/ ${costoAnt?.toStringAsFixed(2) ?? '—'} → S/ ${costoNuevo.toStringAsFixed(2)} (promedio ponderado)'
          : (data?['razonCostoNoActualizado'] != null
              ? '\n⚠️ Costo NO actualizado: ${data!['razonCostoNoActualizado']}'
              : '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$base$extraCosto'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String msg;
      if (e is DioException) {
        final body = e.response?.data;
        if (body is Map<String, dynamic>) {
          msg = (body['message']?.toString()) ?? 'Error al fabricar';
          // Si el backend devuelve faltantes/conflictivos, los anexamos
          final faltantes = body['faltantes'];
          if (faltantes is List && faltantes.isNotEmpty) {
            msg += '\n\nFaltantes:\n${faltantes.map((f) => '- ${f['nombre']}: necesita ${f['requerido']}, hay ${f['disponible']}').join('\n')}';
          }
        } else {
          msg = e.message ?? 'Error al fabricar';
        }
      } else {
        msg = e.toString();
      }
      setState(() {
        _fabricando = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final puedeConfirmar = _cantidad >= 1 &&
        !_hayFraccionarios &&
        !_hayInsuficiencia &&
        !_fabricando;
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.precision_manufacturing_outlined,
                      color: Colors.deepPurple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fabricar',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.productoNombre,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _fabricando
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              if (widget.sedeNombre != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 28),
                  child: Row(
                    children: [
                      Icon(Icons.store,
                          size: 11, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.sedeNombre!,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _cantidadCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'Cantidad a fabricar (unidades)',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (preview.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Insumo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Consumirá',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Stock',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      itemCount: preview.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 6,
                        color: Colors.deepPurple.shade100,
                      ),
                      itemBuilder: (_, i) {
                        final p = preview[i];
                        final mostrarRojo = !p.esEntero || p.excedeStock;
                        return Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                p.nombre,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                '${_fmt(p.cantidadConsumida)} ${p.unidadMedida}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: mostrarRojo
                                      ? Colors.red.shade700
                                      : Colors.deepPurple.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                p.stockDisponible != null
                                    ? '/ ${p.stockDisponible}'
                                    : '/ —',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: p.excedeStock
                                      ? Colors.red.shade700
                                      : Colors.grey.shade600,
                                  fontWeight: p.excedeStock
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (_hayFraccionarios) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Algún componente requiere cantidad fraccionaria. '
                            'Cambia la unidad de medida del componente '
                            '(ej: KG→GR) o ajusta el lote para que sea entero.',
                            style: TextStyle(
                                fontSize: 10, color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_hayInsuficiencia && !_hayFraccionarios) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Stock insuficiente en al menos un insumo. '
                            'Reducí el lote o reabastecé los marcados en rojo.',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _observacionesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  hintText: 'Ej: lote del día, encargo cliente X…',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                        fontSize: 10, color: Colors.red.shade900),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      textColor: Colors.deepPurple,
                      borderColor:
                          Colors.deepPurple.withValues(alpha: 0.4),
                      enableShadows: false,
                      height: 36,
                      onPressed: _fabricando
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Fabricar',
                      backgroundColor: Colors.deepPurple.shade600,
                      textColor: Colors.white,
                      enableShadows: false,
                      isLoading: _fabricando,
                      height: 36,
                      icon: const Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 14,
                          color: Colors.white),
                      onPressed: puedeConfirmar ? _confirmar : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-6) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(3);
  }
}

class _PreviewLinea {
  final String nombre;
  final String unidadMedida;
  final double cantidadPorUnidad;
  final double cantidadConsumida;
  final bool esEntero;
  final int? stockDisponible;
  final bool excedeStock;

  _PreviewLinea({
    required this.nombre,
    required this.unidadMedida,
    required this.cantidadPorUnidad,
    required this.cantidadConsumida,
    required this.esEntero,
    required this.stockDisponible,
    required this.excedeStock,
  });
}

/// Mini-dialog interno (mismo patrón que la calculadora del Configurar
/// Precios). StatefulWidget aparte para que los controllers no se
/// disposen antes de la última build.
class _CalculadoraLoteDialogInline extends StatefulWidget {
  const _CalculadoraLoteDialogInline();

  @override
  State<_CalculadoraLoteDialogInline> createState() =>
      _CalculadoraLoteDialogInlineState();
}

class _CalculadoraLoteDialogInlineState
    extends State<_CalculadoraLoteDialogInline> {
  final _cantidadCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  double? _unitario;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  void _recalcular() {
    final cant = double.tryParse(_cantidadCtrl.text.replaceAll(',', '.'));
    final tot = double.tryParse(_totalCtrl.text.replaceAll(',', '.'));
    setState(() {
      _unitario = (cant != null && cant > 0 && tot != null && tot > 0)
          ? tot / cant
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recalcular costo unitario',
          style: TextStyle(fontSize: 14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Si cargaste mal el costo del insumo (tipeaste el TOTAL en vez del unitario), corregilo acá. Ingresá la cantidad comprada y el total pagado.',
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cantidadCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cantidad comprada',
              hintText: 'Ej. 20',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _recalcular(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _totalCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total pagado (S/)',
              hintText: 'Ej. 200',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _recalcular(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _unitario != null
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _unitario != null
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Costo por unidad:',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade700),
                ),
                Text(
                  _unitario != null
                      ? 'S/ ${_unitario!.toStringAsFixed(2)}'
                      : '—',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _unitario != null
                        ? Colors.green.shade800
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _unitario != null
              ? () => Navigator.pop(context, _unitario)
              : null,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// =========================================================================
// BottomSheet "Historial de fabricaciones": lista de lotes PROD-* + tap
// para ver el detalle (insumos consumidos) on-demand.
// =========================================================================

class _HistorialFabricacionesSheet extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeId;
  final String? sedeNombre;

  const _HistorialFabricacionesSheet({
    required this.productoId,
    required this.productoNombre,
    required this.sedeId,
    required this.sedeNombre,
  });

  @override
  State<_HistorialFabricacionesSheet> createState() =>
      _HistorialFabricacionesSheetState();
}

class _HistorialFabricacionesSheetState
    extends State<_HistorialFabricacionesSheet> {
  final DioClient _dio = locator<DioClient>();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _lotes = const [];
  final Set<String> _expandidos = {};
  final Map<String, Map<String, dynamic>> _detalles = {};
  final Set<String> _cargandoDetalle = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/componentes/fabricaciones',
        queryParameters: {
          if (widget.sedeId != null) 'sedeId': widget.sedeId,
          'limit': 50,
        },
      );
      if (!mounted) return;
      setState(() {
        _lotes = (resp.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
            : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleExpand(String numeroDocumento) async {
    if (_expandidos.contains(numeroDocumento)) {
      setState(() => _expandidos.remove(numeroDocumento));
      return;
    }
    setState(() => _expandidos.add(numeroDocumento));
    if (_detalles.containsKey(numeroDocumento)) return;
    setState(() => _cargandoDetalle.add(numeroDocumento));
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/componentes/fabricaciones/$numeroDocumento',
      );
      if (!mounted) return;
      setState(() {
        _detalles[numeroDocumento] = resp.data as Map<String, dynamic>;
        _cargandoDetalle.remove(numeroDocumento);
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoDetalle.remove(numeroDocumento));
    }
  }

  String _fechaCorta(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final mi = d.minute.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year} $hh:$mi';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.history,
                    color: Colors.deepPurple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de fabricaciones',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.productoNombre +
                            (widget.sedeNombre != null
                                ? ' · ${widget.sedeNombre}'
                                : ''),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: Colors.red.shade400),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_lotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 50, color: Colors.deepPurple.shade300),
              const SizedBox(height: 8),
              const Text('Sin fabricaciones registradas',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                widget.sedeId != null
                    ? 'No hay lotes producidos en esta sede.'
                    : 'Aún no se fabricó este producto.',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _lotes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildLote(_lotes[i]),
    );
  }

  Widget _buildLote(Map<String, dynamic> lote) {
    final numero = lote['numeroDocumento'] as String? ?? '';
    final cantidad = lote['cantidadProducida'] as num?;
    final stockNuevo = lote['stockNuevo'] as num?;
    final fecha = lote['creadoEn'] as String?;
    final usuarioNombre =
        (lote['usuario'] as Map?)?['nombre'] as String? ?? '—';
    final sedeNombre = (lote['sede'] as Map?)?['nombre'] as String? ?? '—';
    final observaciones = lote['observaciones'] as String?;
    final expandido = _expandidos.contains(numero);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _toggleExpand(numero),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade100, width: 0.8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      numero,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fecha != null ? _fechaCorta(fecha) : '—',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expandido
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.deepPurple.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '+$cantidad unidad(es)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Stock: $stockNuevo',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      usuarioNombre,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.store,
                      size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    sedeNombre,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
              if (observaciones != null && observaciones.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    observaciones,
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              if (expandido) _buildDetalle(numero),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalle(String numero) {
    if (_cargandoDetalle.contains(numero)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final detalle = _detalles[numero];
    if (detalle == null) return const SizedBox.shrink();
    final insumos =
        (detalle['insumosConsumidos'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    if (insumos.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insumos consumidos',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade800,
            ),
          ),
          const SizedBox(height: 6),
          ...insumos.map((ins) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ins['nombre']?.toString() ?? '—',
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '-${ins['cantidadConsumida']} ${ins['unidadMedida'] ?? ''}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '→ ${ins['stockNuevo']}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
