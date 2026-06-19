import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../data/models/historial_compras_model.dart';

/// Panel de HISTORIAL DE COMPRAS del producto seleccionado (al comprar).
/// Muestra a cuánto te dejó el producto cada proveedor (costo promedio / último),
/// resalta el mejor precio, y compara el precio que estás ingresando contra el
/// último costo (variación) y contra el precio de venta (margen).
///
/// Autocontenido: carga su data al cambiar el producto/variante (no en cada
/// tecla); el precio/venta solo recalculan los indicadores en pantalla.
class HistorialComprasProductoPanel extends StatefulWidget {
  final String productoId;
  final String? varianteId;
  final double precioCompra; // costo unitario atómico que está ingresando
  final double? precioVenta; // precio de venta en la sede (para margen)

  const HistorialComprasProductoPanel({
    super.key,
    required this.productoId,
    this.varianteId,
    this.precioCompra = 0,
    this.precioVenta,
  });

  @override
  State<HistorialComprasProductoPanel> createState() =>
      _HistorialComprasProductoPanelState();
}

class _HistorialComprasProductoPanelState
    extends State<HistorialComprasProductoPanel> {
  final _ds = locator<CompraRemoteDataSource>();
  HistorialComprasResult? _data;
  bool _loading = true;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HistorialComprasProductoPanel old) {
    super.didUpdateWidget(old);
    if (old.productoId != widget.productoId || old.varianteId != widget.varianteId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _ds.getHistorialComprasProducto(
        productoId: widget.productoId,
        varianteId: widget.varianteId,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _data = r;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: const [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            AppSubtitle('Cargando historial de compras…', fontSize: 11, color: AppColors.blueGrey),
          ],
        ),
      );
    }
    final d = _data;
    if (d == null || d.vacio) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: AppSubtitle('Sin compras previas de este producto.',
            fontSize: 11, color: AppColors.blueGrey),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blueborder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con último costo + variación + margen
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Row(
              children: [
                const Icon(Icons.history, size: 15, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle('Historial de compras (${d.compras.length})',
                    fontSize: 12, color: AppColors.blue1),
                const Spacer(),
                Icon(_expandido ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: AppColors.blue1),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (d.ultimoCosto != null)
                _chip('Últ. costo S/ ${d.ultimoCosto!.toStringAsFixed(2)}',
                    Colors.blueGrey),
              ..._variacionChip(d.ultimoCosto),
              ..._margenChip(),
            ],
          ),
          if (_expandido) ...[
            const SizedBox(height: 10),
            const AppSubtitle('Por proveedor', fontSize: 10, color: AppColors.blueGrey),
            const SizedBox(height: 4),
            ...d.proveedores.take(4).map((p) => _filaProveedor(p, d.mejorProveedorId)),
            const SizedBox(height: 8),
            const AppSubtitle('Últimas compras', fontSize: 10, color: AppColors.blueGrey),
            const SizedBox(height: 4),
            ...d.compras.take(6).map(_filaCompra),
          ],
        ],
      ),
    );
  }

  List<Widget> _variacionChip(double? ultimo) {
    if (ultimo == null || ultimo <= 0 || widget.precioCompra <= 0) return [];
    final pct = (widget.precioCompra - ultimo) / ultimo * 100;
    if (pct.abs() < 0.05) {
      return [_chip('= igual al último', Colors.grey)];
    }
    final sube = pct > 0;
    return [
      _chip(
        '${sube ? '▲' : '▼'} ${pct.abs().toStringAsFixed(1)}% vs último',
        sube ? Colors.red : Colors.green,
      ),
    ];
  }

  List<Widget> _margenChip() {
    final venta = widget.precioVenta;
    if (venta == null || venta <= 0 || widget.precioCompra <= 0) return [];
    final margen = (venta - widget.precioCompra) / venta * 100;
    return [
      _chip('Margen ${margen.toStringAsFixed(0)}%',
          margen >= 0 ? Colors.teal : Colors.red),
    ];
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _filaProveedor(HistorialProveedor p, String? mejorId) {
    final esMejor = mejorId != null && p.proveedorId == mejorId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          if (esMejor)
            const Padding(
              padding: EdgeInsets.only(right: 3),
              child: Icon(Icons.star, size: 12, color: Colors.amber),
            ),
          Expanded(
            child: Text(
              p.proveedor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: esMejor ? FontWeight.w700 : FontWeight.w500,
                color: esMejor ? Colors.teal.shade700 : Colors.black87,
              ),
            ),
          ),
          Text(
            'prom S/ ${p.costoPromedio.toStringAsFixed(2)}'
            '${p.ultimoCosto != null ? '  ·  últ S/ ${p.ultimoCosto!.toStringAsFixed(2)}' : ''}'
            '  ·  ${p.veces}x',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _filaCompra(HistorialCompraItem c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(
            c.fecha != null ? DateFormatter.formatDate(c.fecha!) : '—',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(c.proveedor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10)),
          ),
          Text('S/ ${c.costoUnitario.toStringAsFixed(2)} ×${c.cantidad}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
