import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/smart_appbar.dart';

/// Ficha 360 / Trazabilidad de un producto: de dónde vino (compras, lotes,
/// fabricación) y a dónde fue (ventas, consumo como insumo) + stock/costo.
/// Si no se pasa [productoId], muestra un buscador para elegir el producto.
class TrazabilidadProductoPage extends StatefulWidget {
  final String? productoId;
  final String? productoNombre;
  final String? varianteId;

  const TrazabilidadProductoPage({
    super.key,
    this.productoId,
    this.productoNombre,
    this.varianteId,
  });

  @override
  State<TrazabilidadProductoPage> createState() =>
      _TrazabilidadProductoPageState();
}

class _TrazabilidadProductoPageState extends State<TrazabilidadProductoPage> {
  final _dio = locator<DioClient>();
  final _searchCtrl = TextEditingController();

  String? _productoId;
  bool _loading = false;
  bool _searching = false;
  String? _error;
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    _productoId = widget.productoId;
    if (_productoId != null) _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final resp = await _dio.get('/productos', queryParameters: {
        'search': q.trim(),
        'limit': 12,
        'isActive': 'true',
      });
      final data = resp.data;
      final list = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['items'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _results = (list as List).cast<Map<String, dynamic>>();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _cargar() async {
    if (_productoId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    try {
      final resp = await _dio.get(
        '/productos/$_productoId/trazabilidad',
        queryParameters: {
          if (widget.varianteId != null) 'varianteId': widget.varianteId,
        },
      );
      if (!mounted) return;
      setState(() {
        _data = resp.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la trazabilidad';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Trazabilidad del Producto'),
        body: _productoId == null ? _buildBuscador() : _buildContenido(),
      ),
    );
  }

  // ─── Buscador (entrada desde drawer, sin producto) ───
  Widget _buildBuscador() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: GradientContainer(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomSearchField(
                controller: _searchCtrl,
                hintText: 'Buscar producto o insumo…',
                borderColor: AppColors.blue1,
                debounceDelay: const Duration(milliseconds: 350),
                onChanged: _buscar,
              ),
            ),
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: AppText(
                        _searchCtrl.text.trim().length < 2
                            ? 'Escribí al menos 2 caracteres'
                            : 'Sin resultados',
                        size: 12,
                        color: Colors.grey,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final p = _results[i];
                        return ListTile(
                          dense: true,
                          title: Text(p['nombre']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(p['codigoEmpresa']?.toString() ?? '',
                              style: const TextStyle(fontSize: 10)),
                          trailing:
                              const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            setState(() => _productoId = p['id'] as String?);
                            _cargar();
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildContenido() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            AppText(_error!, size: 12, color: Colors.grey),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final d = _data;
    if (d == null) return const SizedBox.shrink();

    final p = d['producto'] as Map<String, dynamic>;
    final stock = d['stock'] as Map<String, dynamic>;
    final kardex = (d['kardex'] as List?) ?? const [];
    final compras = (d['compras'] as List?) ?? const [];
    final proveedores = (d['proveedores'] as List?) ?? const [];
    final lotes = (d['lotes'] as List?) ?? const [];
    final ventas = (d['ventas'] as List?) ?? const [];
    final devoluciones = (d['devoluciones'] as List?) ?? const [];
    final transferencias = (d['transferencias'] as List?) ?? const [];
    final fab = d['fabricacion'] as Map<String, dynamic>;
    final lotesFab = (fab['lotesFabricados'] as List?) ?? const [];
    final insumosCons = (fab['insumosConsumidos'] as List?) ?? const [];
    final usado = (fab['usadoEnRecetas'] as List?) ?? const [];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildCabecera(p, stock),
        const SizedBox(height: 12),
        _buildSeccionStock(stock),
        _buildSeccionKardex(kardex),
        _buildSeccionCompras(compras),
        if (proveedores.isNotEmpty) _buildSeccionProveedores(proveedores),
        _buildSeccionLotes(lotes),
        if (lotesFab.isNotEmpty) _buildSeccionFabricados(lotesFab),
        if (insumosCons.isNotEmpty) _buildSeccionInsumosConsumidos(insumosCons),
        if (usado.isNotEmpty) _buildSeccionUsado(usado),
        _buildSeccionVentas(ventas),
        if (devoluciones.isNotEmpty) _buildSeccionDevoluciones(devoluciones),
        _buildSeccionTransferencias(transferencias),
      ],
    );
  }

  Widget _buildCabecera(Map<String, dynamic> p, Map<String, dynamic> stock) {
    final base = p['unidadMedidaSimbolo'] as String?;
    final stockTotal = (stock['stockTotal'] as num?)?.toDouble() ?? 0;
    final valorizado = (stock['valorizado'] as num?)?.toDouble() ?? 0;
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle(p['nombre']?.toString() ?? '', fontSize: 14,
                color: AppColors.blue3),
            const SizedBox(height: 2),
            AppText(p['codigoEmpresa']?.toString() ?? '', size: 10,
                color: Colors.grey),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (p['esInsumo'] == true)
                _chip('Insumo', Colors.orange.shade700, Icons.inventory_2),
              if (p['esFabricado'] == true)
                _chip('Fabricado', Colors.indigo, Icons.precision_manufacturing),
              if (p['tieneVariantes'] == true)
                _chip('Con variantes', AppColors.blue1, Icons.account_tree),
            ]),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _kpi('Stock total',
                      '${_fmtNum(stockTotal)}${base != null ? ' $base' : ''}',
                      AppColors.blue1),
                ),
                Expanded(
                  child: _kpi('Valorizado',
                      'S/ ${valorizado.toStringAsFixed(2)}', Colors.green.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, size: 9, color: Colors.grey),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ─── Secciones (ExpansionTile) ───
  Widget _seccion(String titulo, IconData icon, int count, List<Widget> children,
      {bool inicialAbierto = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: inicialAbierto,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            leading: Icon(icon, size: 18, color: AppColors.blue1),
            title: Row(
              children: [
                AppSubtitle(titulo, fontSize: 12),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText('$count', size: 9,
                      fontWeight: FontWeight.w700, color: AppColors.blue1),
                ),
              ],
            ),
            children: children.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: AppText('Sin registros', size: 10,
                          color: Colors.grey),
                    )
                  ]
                : children,
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionStock(Map<String, dynamic> stock) {
    final porSede = (stock['porSede'] as List?) ?? const [];
    return _seccion('Stock por sede', Icons.store, porSede.length,
        inicialAbierto: true, [
      for (final s in porSede.cast<Map<String, dynamic>>())
        InkWell(
          onTap: s['productoStockId'] != null
              ? () => context.push(
                  '/empresa/inventario/kardex/${s['productoStockId']}?nombre=${Uri.encodeComponent(_data?['producto']?['nombre']?.toString() ?? '')}')
              : null,
          child: _fila(
            izqTop: '${s['sedeNombre'] ?? '—'}'
                '${s['varianteNombre'] != null ? ' · ${s['varianteNombre']}' : ''}',
            izqSub: 'Costo: S/ ${_fmtCosto(s['precioCosto'])}',
            derTop: '${s['stockActual'] ?? 0}',
            trailingIcon: Icons.bar_chart,
          ),
        ),
    ]);
  }

  Widget _buildSeccionCompras(List compras) {
    return _seccion('Entradas — Compras', Icons.shopping_bag,
        compras.length, [
      for (final c in compras.cast<Map<String, dynamic>>())
        InkWell(
          onTap: () => context.push(
              '/empresa/flujo-documentos?codigo=${Uri.encodeComponent(c['compraCodigo']?.toString() ?? '')}'),
          child: _fila(
            izqTop:
                '${c['compraCodigo'] ?? ''}${c['varianteNombre'] != null ? ' · ${c['varianteNombre']}' : ''}',
            izqSub:
                '${c['proveedor'] ?? ''} · ${_fecha(c['fecha'])} · x${c['cantidad']}',
            derTop:
                '${c['moneda'] == 'USD' ? '\$' : 'S/'} ${_fmtNum((c['total'] as num?)?.toDouble() ?? 0)}',
          ),
        ),
    ]);
  }

  Widget _buildSeccionLotes(List lotes) {
    return _seccion('Lotes', Icons.inventory, lotes.length, [
      for (final l in lotes.cast<Map<String, dynamic>>())
        _fila(
          izqTop:
              '${l['codigo'] ?? ''}${l['varianteNombre'] != null ? ' · ${l['varianteNombre']}' : ''}',
          izqSub:
              '${l['proveedor'] ?? '—'} · ${_fecha(l['fechaIngreso'])}${l['fechaVencimiento'] != null ? ' · vence ${_fecha(l['fechaVencimiento'])}' : ''}',
          derTop: '${l['cantidadActual']}/${l['cantidadInicial']}',
          derSub: 'S/ ${_fmtCosto(l['precioCosto'])}',
        ),
    ]);
  }

  Widget _buildSeccionFabricados(List lotesFab) {
    return _seccion(
        'Fabricación — Lotes producidos', Icons.precision_manufacturing,
        lotesFab.length, [
      for (final f in lotesFab.cast<Map<String, dynamic>>())
        _fila(
          izqTop: f['numeroDocumento']?.toString() ?? '',
          izqSub: _fecha(f['fecha']),
          derTop: '+${f['cantidad']}',
          derSub: f['precioCostoUnitario'] != null
              ? 'S/ ${_fmtCosto(f['precioCostoUnitario'])}'
              : null,
        ),
    ]);
  }

  Widget _buildSeccionUsado(List usado) {
    return _seccion('Se usa como insumo en', Icons.account_tree, usado.length, [
      for (final u in usado.cast<Map<String, dynamic>>())
        _fila(
          izqTop:
              '${u['productoFinalNombre'] ?? ''}${u['varianteFinalNombre'] != null ? ' · ${u['varianteFinalNombre']}' : ''}',
          izqSub: u['componenteVarianteNombre'] != null
              ? 'usa variante: ${u['componenteVarianteNombre']}'
              : null,
          derTop: 'x${_fmtNum((u['cantidadPorUnidad'] as num?)?.toDouble() ?? 0)}',
        ),
    ]);
  }

  Widget _buildSeccionVentas(List ventas) {
    return _seccion('Salidas — Ventas', Icons.point_of_sale, ventas.length, [
      for (final v in ventas.cast<Map<String, dynamic>>())
        InkWell(
          onTap: () => context.push(
              '/empresa/flujo-documentos?codigo=${Uri.encodeComponent(v['ventaCodigo']?.toString() ?? '')}'),
          child: _fila(
            izqTop:
                '${v['ventaCodigo'] ?? ''}${v['varianteNombre'] != null ? ' · ${v['varianteNombre']}' : ''}',
            izqSub: '${v['cliente'] ?? ''} · ${_fecha(v['fecha'])} · x${_fmtNum((v['cantidad'] as num?)?.toDouble() ?? 0)}',
            derTop:
                '${v['moneda'] == 'USD' ? '\$' : 'S/'} ${_fmtNum((v['total'] as num?)?.toDouble() ?? 0)}',
            trailingIcon: Icons.account_tree_outlined,
          ),
        ),
    ]);
  }

  Widget _buildSeccionKardex(List kardex) {
    return _seccion('Kardex consolidado (todas las sedes)', Icons.history,
        kardex.length, [
      for (final m in kardex.cast<Map<String, dynamic>>())
        _fila(
          izqTop: '${m['tipo']}${m['numeroDocumento'] != null ? ' · ${m['numeroDocumento']}' : ''}',
          izqSub: '${m['sedeNombre'] ?? '—'} · ${_fecha(m['fecha'])}',
          derTop: '${(m['cantidad'] as num? ?? 0) >= 0 ? '+' : ''}${m['cantidad']}',
          derSub: m['precioCostoUnitario'] != null
              ? 'S/ ${_fmtCosto(m['precioCostoUnitario'])}'
              : null,
        ),
    ]);
  }

  Widget _buildSeccionProveedores(List proveedores) {
    return _seccion('Proveedores', Icons.local_shipping, proveedores.length, [
      for (final p in proveedores.cast<Map<String, dynamic>>())
        _fila(
          izqTop: p['proveedor']?.toString() ?? '—',
          izqSub:
              '${p['veces']} compra(s) · ${p['cantidadAcum']} u${p['ultimaCompra'] != null ? ' · últ. ${_fecha(p['ultimaCompra'])}' : ''}',
          derTop: 'S/ ${_fmtCosto(p['precioPromedio'])}',
          derSub: 'prom.',
        ),
    ]);
  }

  Widget _buildSeccionInsumosConsumidos(List insumos) {
    return _seccion('Fabricación — Insumos consumidos', Icons.layers,
        insumos.length, [
      for (final i in insumos.cast<Map<String, dynamic>>())
        _fila(
          izqTop: i['insumo']?.toString() ?? '—',
          derTop: _fmtNum((i['cantidad'] as num?)?.toDouble() ?? 0),
          derSub: 'S/ ${_fmtCosto(i['costo'])}',
        ),
    ]);
  }

  Widget _buildSeccionDevoluciones(List devs) {
    return _seccion('Salidas — Devoluciones', Icons.assignment_return,
        devs.length, [
      for (final d in devs.cast<Map<String, dynamic>>())
        InkWell(
          onTap: d['ventaCodigo'] != null
              ? () => context.push(
                  '/empresa/flujo-documentos?codigo=${Uri.encodeComponent(d['ventaCodigo'].toString())}')
              : null,
          child: _fila(
            izqTop:
                '${d['codigo'] ?? ''}${d['varianteNombre'] != null ? ' · ${d['varianteNombre']}' : ''}',
            izqSub:
                '${d['motivo'] ?? ''} · ${_fecha(d['fecha'])}${d['ventaCodigo'] != null ? ' · ${d['ventaCodigo']}' : ''}',
            derTop: '-${d['cantidad']}',
            trailingIcon:
                d['ventaCodigo'] != null ? Icons.account_tree_outlined : null,
          ),
        ),
    ]);
  }

  Widget _buildSeccionTransferencias(List transf) {
    return _seccion('Transferencias entre sedes', Icons.swap_horiz,
        transf.length, [
      for (final t in transf.cast<Map<String, dynamic>>())
        _fila(
          izqTop:
              '${t['origen'] ?? '?'} → ${t['destino'] ?? '?'}${t['varianteNombre'] != null ? ' · ${t['varianteNombre']}' : ''}',
          izqSub:
              '${t['codigo'] ?? ''} · ${t['estado'] ?? ''} · ${_fecha(t['fecha'])}',
          derTop: '${t['cantidadRecibida'] ?? t['cantidadEnviada'] ?? t['cantidadSolicitada'] ?? 0}',
        ),
    ]);
  }

  // ─── helpers UI ───
  Widget _fila({
    required String izqTop,
    String? izqSub,
    required String derTop,
    String? derSub,
    IconData? trailingIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(izqTop,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (izqSub != null)
                  Text(izqSub,
                      style:
                          TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(derTop,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
              if (derSub != null)
                Text(derSub,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            ],
          ),
          if (trailingIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(trailingIcon, size: 14, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ]),
    );
  }

  String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

  String _fmtCosto(dynamic c) {
    final v = (c as num?)?.toDouble();
    return v != null ? v.toStringAsFixed(2) : '—';
  }

  String _fecha(dynamic f) {
    if (f == null) return '—';
    final d = DateTime.tryParse(f.toString());
    return d != null ? DateFormatter.formatDate(d) : '—';
  }
}
