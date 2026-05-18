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

  const ComponentesProductoPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
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
        child: Row(
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
      ),
    );
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
  final Set<String> idsYaUsados;

  const _AgregarComponenteDialog({
    required this.productoId,
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
                                  onTap: () =>
                                      setState(() => _selected = p),
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
                        onPressed: () => setState(() => _selected = null),
                      ),
                    ],
                  ),
                ),
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
