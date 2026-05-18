import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';

/// Sección embebida en ConfigurarPreciosDialog para gestionar la receta
/// (BOM) de un producto compuesto.
///
/// MVP: solo CRUD de componentes + cálculo de costo total. NO toca stock.
/// El botón "Aplicar como precio costo" llama a [onAplicarCosto] con el
/// total calculado, y el dialog padre lo pone en el campo precioCosto.
class ComponentesProductoSection extends StatefulWidget {
  final String productoId;
  final String sedeId;
  final ValueChanged<double> onAplicarCosto;

  const ComponentesProductoSection({
    super.key,
    required this.productoId,
    required this.sedeId,
    required this.onAplicarCosto,
  });

  @override
  State<ComponentesProductoSection> createState() =>
      _ComponentesProductoSectionState();
}

class _ComponentesProductoSectionState
    extends State<ComponentesProductoSection> {
  final DioClient _dio = locator<DioClient>();
  bool _expanded = false;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    // Carga inicial silenciosa (no expande aún) para saber si ya hay
    // componentes definidos y mostrar contador en el header.
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
        queryParameters: {'sedeId': widget.sedeId},
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['componente']['nombre'] as String),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                'Cantidad (${item['componente']['unidadMedida'] ?? '—'})',
          ),
          autofocus: true,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100, width: 0.6),
      ),
      child: Column(
        children: [
          // Header colapsable
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 16, color: Colors.indigo.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calcular desde componentes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                        Text(
                          _items.isEmpty
                              ? 'Sin componentes — productos como peluches/PCs armadas'
                              : '${_items.length} componente(s) · S/ ${_costoTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.indigo.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.indigo.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _buildContenido(),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 11)),
            const SizedBox(height: 8),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      color: Colors.white,
      child: Column(
        children: [
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Agregá los insumos que componen este producto.\nEl costo se calculará sumando cantidad × precio costo de cada uno.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            // Header de tabla
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 5, child: _Hcell('Componente')),
                  Expanded(flex: 3, child: _Hcell('Cantidad', right: true)),
                  Expanded(flex: 3, child: _Hcell('Costo', right: true)),
                  Expanded(flex: 3, child: _Hcell('Subtotal', right: true)),
                  SizedBox(width: 56),
                ],
              ),
            ),
            const SizedBox(height: 2),
            ..._items.map(_buildFila),
            const Divider(height: 8, thickness: 0.5),
            // Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  const Expanded(
                    flex: 11,
                    child: Text('TOTAL',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'S/ ${_costoTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            if (_algunoSinCosto)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Hay componentes sin precio costo en esta sede — el total es parcial.',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange.shade800,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Agregar',
                  icon: const Icon(Icons.add, size: 14, color: Colors.white),
                  backgroundColor: Colors.indigo.shade600,
                  textColor: Colors.white,
                  enableShadows: false,
                  height: 32,
                  onPressed: _agregar,
                ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Aplicar a Costo',
                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                    backgroundColor: AppColors.blue1,
                    textColor: Colors.white,
                    enableShadows: false,
                    height: 32,
                    onPressed: _costoTotal > 0
                        ? () {
                            widget.onAplicarCosto(_costoTotal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Costo aplicado: S/ ${_costoTotal.toStringAsFixed(2)}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item['componente']['nombre'] as String,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${cantidad.toStringAsFixed(cantidad == cantidad.truncateToDouble() ? 0 : 3)} ${um ?? ''}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10),
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
                fontSize: 10,
                color: costoUnit == null ? Colors.orange.shade700 : null,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              subtotal != null ? 'S/ ${subtotal.toStringAsFixed(2)}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subtotal == null ? Colors.orange.shade700 : null,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _editarCantidad(item),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit,
                        size: 14, color: Colors.indigo.shade600),
                  ),
                ),
                InkWell(
                  onTap: () => _eliminar(item),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 14, color: Colors.red.shade400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        fontSize: 9,
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
