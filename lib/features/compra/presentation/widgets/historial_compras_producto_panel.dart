import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../data/models/historial_compras_model.dart';
import '../../domain/entities/compra.dart';

/// Panel de HISTORIAL DE COMPRAS del producto seleccionado (al comprar).
/// Muestra a cuánto te dejó el producto cada proveedor (costo promedio / último),
/// resalta el mejor precio, y compara el precio que estás ingresando contra el
/// último costo (variación) y contra el precio de venta (margen).
///
/// Autocontenido: carga su data al cambiar el producto/variante (no en cada
/// tecla); el precio/venta solo recalculan los indicadores en pantalla.
class HistorialComprasProductoPanel extends StatefulWidget {
  final String empresaId;
  final String productoId;
  final String? varianteId;
  final double precioCompra; // costo unitario atómico que está ingresando
  final double? precioVenta; // precio de venta en la sede (para margen)

  const HistorialComprasProductoPanel({
    super.key,
    required this.empresaId,
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
      padding: const EdgeInsets.symmetric(horizontal:10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.blueborder, width: 0.6),
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
                    fontSize: 10, color: AppColors.blue1),
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
            const AppSubtitle('Por proveedor',
                fontSize: 10, color: AppColors.blueGrey),
            const SizedBox(height: 4),
            // Cada proveedor usa el empaque de SU último lote (puede variar
            // entre proveedores: 50, 40, ...).
            ...d.proveedores.take(4).map((p) {
              final paq = _factorDeProveedor(d, p.proveedorId);
              return _filaProveedor(
                p,
                d.mejorProveedorId,
                factorPaquete: paq?.factor,
                simboloPaquete: paq?.simbolo,
              );
            }),
            const SizedBox(height: 8),
            const AppSubtitle('Últimas compras', fontSize: 10, color: AppColors.blueGrey),
            const SizedBox(height: 4),
            _tablaUltimasCompras(d.compras.take(6).toList()),
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
        border: Border.all(color: color.withValues(alpha: 0.3),width: 0.6),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  /// Chip pequeño del conteo de compras (ej. "Cx3").
  Widget _countChip(int veces) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'Cx$veces',
        style: const TextStyle(
            fontSize: 9, color: AppColors.blue1, fontWeight: FontWeight.w700),
      ),
    );
  }

  /// Factor (unidades por paquete) + símbolo del ÚLTIMO lote de un proveedor.
  /// Las compras vienen ordenadas por fecha desc, así que la primera que
  /// coincide es la más reciente. Captura el empaque real de ese proveedor
  /// (que puede diferir de otros: 50 vs 40). Si no compró por paquete, null.
  ({double factor, String simbolo})? _factorDeProveedor(
      HistorialComprasResult d, String? proveedorId) {
    for (final c in d.compras) {
      if (c.proveedorId != proveedorId) continue;
      final f = c.unidadesPorPaquete;
      if (c.usaUnidadCompra &&
          f != null &&
          f > 0 &&
          c.unidadOriginalSimbolo != null) {
        return (factor: f, simbolo: c.unidadOriginalSimbolo!);
      }
    }
    return null;
  }

  Widget _filaProveedor(
    HistorialProveedor p,
    String? mejorId, {
    double? factorPaquete,
    String? simboloPaquete,
  }) {
    final esMejor = mejorId != null && p.proveedorId == mejorId;

    // Si el producto se compra por paquete (saco/caja...), mostramos el costo
    // por paquete (promedio/último × factor) y el desglose por unidad.
    final tienePaquete = factorPaquete != null &&
        simboloPaquete != null &&
        factorPaquete > 0;
    final promPaq = tienePaquete ? p.costoPromedio * factorPaquete : null;
    final ultPaq = (tienePaquete && p.ultimoCosto != null)
        ? p.ultimoCosto! * factorPaquete
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: esMejor ? Colors.teal.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: esMejor
              ? Colors.teal.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea 1: nombre del proveedor (+ badge "Mejor precio")
          Row(
            children: [
              if (esMejor)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.star, size: 13, color: Colors.amber),
                ),
              Expanded(
                child: Text(
                  p.proveedor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: esMejor ? FontWeight.w700 : FontWeight.w600,
                    color: esMejor ? Colors.teal.shade700 : Colors.black87,
                  ),
                ),
              ),
              if (esMejor) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Mejor precio',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              // Conteo de compras como chip (ej. "Cx3") → evita una fila.
              _countChip(p.veces),
            ],
          ),
          const SizedBox(height: 5),
          // Detalle del proveedor en tabla estilo Excel (igual que "Últimas
          // compras"). El nombre + estrella de arriba no se tocan.
          _detalleProveedorTabla(
            p,
            tienePaquete: tienePaquete,
            promPaq: promPaq,
            ultPaq: ultPaq,
            factorPaquete: factorPaquete,
            simboloPaquete: simboloPaquete,
          ),
        ],
      ),
    );
  }

  /// Tabla "Excel" con el detalle de costos de UN proveedor. Con paquete:
  /// 3 columnas (Concepto · Por paquete · Por unidad); sin paquete: 2
  /// columnas (Concepto · Costo, por unidad).
  Widget _detalleProveedorTabla(
    HistorialProveedor p, {
    required bool tienePaquete,
    double? promPaq,
    double? ultPaq,
    double? factorPaquete,
    String? simboloPaquete,
  }) {
    final headerStyle = TextStyle(
        fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700);
    final concepto = TextStyle(fontSize: 9.5, color: Colors.grey.shade600);
    final valor = TextStyle(
        fontSize: 9.5, color: Colors.grey.shade900, fontWeight: FontWeight.w700);

    const mensajeProm =
        'Costo promedio PONDERADO por cantidad: las compras de mayor '
        'cantidad pesan más en el promedio (no es un promedio simple). '
        'Calculado por unidad sobre todas las compras confirmadas de este '
        'producto a este proveedor.';

    final rows = <TableRow>[];

    if (tienePaquete) {
      // Encabezado de la columna paquete lleva el empaque (ej. "Por Saco ×40").
      final headerPaq =
          'Por $simboloPaquete ×${_fmtNum(factorPaquete!)}';
      rows.add(TableRow(
        decoration:
            BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07)),
        children: [
          _celda('Concepto', headerStyle),
          _celda(headerPaq, headerStyle, align: TextAlign.right, maxLines: 1),
          _celda('Por unidad', headerStyle, align: TextAlign.right),
        ],
      ));
      rows.add(TableRow(children: [
        _celdaConInfo('Costo.Prom', mensajeProm, concepto),
        _celda('S/ ${promPaq!.toStringAsFixed(2)}', valor,
            align: TextAlign.right, maxLines: 1),
        _celda('S/ ${p.costoPromedio.toStringAsFixed(2)}', valor,
            align: TextAlign.right, maxLines: 1),
      ]));
      if (p.ultimoCosto != null) {
        rows.add(TableRow(
          decoration:
              BoxDecoration(color: Colors.grey.withValues(alpha: 0.04)),
          children: [
            _celda('Ultimo P.Compra', concepto, maxLines: 1),
            _celda('S/ ${ultPaq!.toStringAsFixed(2)}', valor,
                align: TextAlign.right, maxLines: 1),
            _celda('S/ ${p.ultimoCosto!.toStringAsFixed(2)}', valor,
                align: TextAlign.right, maxLines: 1),
          ],
        ));
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
          columnWidths: const {
            0: FlexColumnWidth(1.6),
            1: FlexColumnWidth(1.3),
            2: FlexColumnWidth(1.1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      );
    }

    // Sin paquete: 2 columnas (Concepto | Costo, por unidad).
    rows.add(TableRow(
      decoration:
          BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07)),
      children: [
        _celda('Concepto', headerStyle),
        _celda('Costo', headerStyle, align: TextAlign.right),
      ],
    ));
    rows.add(TableRow(children: [
      _celda('C. prom.', concepto),
      _celda('S/ ${p.costoPromedio.toStringAsFixed(2)}/u', valor,
          align: TextAlign.right, maxLines: 1),
    ]));
    if (p.ultimoCosto != null) {
      rows.add(TableRow(
        decoration:
            BoxDecoration(color: Colors.grey.withValues(alpha: 0.04)),
        children: [
          _celda('Último', concepto),
          _celda('S/ ${p.ultimoCosto!.toStringAsFixed(2)}/u', valor,
              align: TextAlign.right, maxLines: 1),
        ],
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
        columnWidths: const {
          0: FlexColumnWidth(1.7),
          1: FlexColumnWidth(1.5),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows,
      ),
    );
  }

  /// Tabla estilo "Excel" de las últimas compras: fecha, proveedor, cantidad
  /// (en su unidad), costo por paquete (si compra por saco/caja) y costo/u.
  Widget _tablaUltimasCompras(List<HistorialCompraItem> compras) {
    final hayPaquete =
        compras.any((c) => c.usaUnidadCompra && c.costoPaquete != null);

    final headerStyle = TextStyle(
        fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700);
    final cellStyle = TextStyle(fontSize: 9.5, color: Colors.grey.shade700);
    final cellBold = TextStyle(
        fontSize: 9.5, color: Colors.grey.shade900, fontWeight: FontWeight.w700);

    final cols = <int, TableColumnWidth>{
      0: const FlexColumnWidth(1.1), // Fecha
      1: const FlexColumnWidth(1.7), // Proveedor
      2: const FlexColumnWidth(1.0), // Cantidad
    };
    if (hayPaquete) {
      cols[3] = const FlexColumnWidth(1.0); // C/paq.
      cols[4] = const FlexColumnWidth(0.95); // C/u
    } else {
      cols[3] = const FlexColumnWidth(0.95); // C/u
    }

    TableRow header() => TableRow(
          decoration:
              BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07)),
          children: [
            _celda('Fecha', headerStyle),
            _celda('Proveedor', headerStyle),
            _celda('Cant.', headerStyle, align: TextAlign.right),
            if (hayPaquete)
              _celda('C/paq.', headerStyle, align: TextAlign.right),
            _celda('C/u', headerStyle, align: TextAlign.right),
          ],
        );

    final cellTiny = TextStyle(fontSize: 8, color: Colors.grey.shade500);

    TableRow fila(HistorialCompraItem c, int i) {
      final usaUC = c.usaUnidadCompra && c.unidadOriginalSimbolo != null;
      final cant = usaUC
          ? '${_fmtNum(c.cantidadOriginal!)} ${c.unidadOriginalSimbolo}'
          : '${c.cantidad} u';
      // Empaque REAL de este lote (puede variar entre compras): 50, 40, ...
      final factorLote = c.unidadesPorPaquete;
      final tienePaqueteLote =
          usaUC && c.costoPaquete != null && factorLote != null;
      final onTap =
          c.compraId != null ? () => _abrirDetalleCompra(c) : null;
      return TableRow(
        decoration: BoxDecoration(
          color: i.isOdd ? Colors.grey.withValues(alpha: 0.04) : Colors.white,
        ),
        children: [
          _celda(c.fecha != null ? DateFormatter.formatDate(c.fecha!) : '—',
              cellStyle, maxLines: 1, onTap: onTap),
          _celda(c.proveedor, cellStyle, maxLines: 1, onTap: onTap),
          _celda(cant, cellStyle,
              align: TextAlign.right, maxLines: 1, onTap: onTap),
          if (hayPaquete)
            // Costo por paquete + cuántas unidades trae ESE lote (× 50 u).
            (tienePaqueteLote
                ? _celdaDual(
                    'S/ ${c.costoPaquete!.toStringAsFixed(2)}',
                    '× ${_fmtNum(factorLote)} u',
                    cellBold,
                    cellTiny,
                    onTap: onTap,
                  )
                : _celda('—', cellBold,
                    align: TextAlign.right, maxLines: 1, onTap: onTap)),
          _celda('S/ ${c.costoUnitario.toStringAsFixed(2)}', cellBold,
              align: TextAlign.right, maxLines: 1, onTap: onTap),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
            columnWidths: cols,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              header(),
              ...compras.asMap().entries.map((e) => fila(e.value, e.key)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 3, left: 2),
          child: Text(
            'Toca una fila para ver el detalle completo',
            style: TextStyle(
                fontSize: 8.5,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _celda(String text, TextStyle style,
      {TextAlign align = TextAlign.left, int? maxLines, VoidCallback? onTap}) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Text(
        text,
        style: style,
        textAlign: align,
        maxLines: maxLines,
        overflow:
            maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      ),
    );
    if (onTap == null) return child;
    // TableRowInkWell ocupa toda la fila → tocar cualquier celda abre el detalle.
    return TableRowInkWell(onTap: onTap, child: child);
  }

  /// Celda "Concepto" con ícono ⓘ que muestra una explicación al TOCAR.
  Widget _celdaConInfo(String label, String mensaje, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label,
                style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 3),
          Tooltip(
            message: mensaje,
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 8),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(10),
            textStyle: const TextStyle(
                fontSize: 10.5, color: Colors.white, height: 1.3),
            decoration: BoxDecoration(
              color: AppColors.blue1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline,
                size: 13, color: AppColors.blue1.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }

  /// Celda de dos líneas (ej. precio por paquete arriba + "× 50 u" abajo).
  Widget _celdaDual(
    String top,
    String bottom,
    TextStyle topStyle,
    TextStyle bottomStyle, {
    TextAlign align = TextAlign.right,
    VoidCallback? onTap,
  }) {
    final cross = align == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(top,
              style: topStyle,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(bottom,
              style: bottomStyle,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    if (onTap == null) return child;
    return TableRowInkWell(onTap: onTap, child: child);
  }

  /// Formatea una cantidad quitando el ".0" cuando es entera (2.0 → "2").
  String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String _money(String moneda, double v) {
    final sym = moneda == 'PEN' ? 'S/' : (moneda == 'USD' ? '\$' : '$moneda ');
    return '$sym ${v.toStringAsFixed(2)}';
  }

  /// Abre el detalle completo de la compra (trae la compra por id y la muestra
  /// en un StyledDialog).
  Future<void> _abrirDetalleCompra(HistorialCompraItem item) async {
    await StyledDialog.show(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.receipt_long,
      titulo: 'Compra ${item.codigo}',
      backgroundColor: Colors.white,
      content: [
        SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<Compra>(
            future:
                _ds.getCompra(empresaId: widget.empresaId, id: item.compraId!),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                );
              }
              if (snap.hasError || !snap.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'No se pudo cargar el detalle de la compra.',
                    style:
                        TextStyle(fontSize: 11, color: Colors.red.shade400),
                  ),
                );
              }
              return _detalleCompraContenido(snap.data!);
            },
          ),
        ),
      ],
    );
  }

  Widget _detalleCompraContenido(Compra c) {
    final detalles = c.detalles ?? [];

    String doc() {
      final partes = <String>[];
      if (c.tipoDocumentoProveedor != null) {
        partes.add(c.tipoDocumentoProveedor!);
      }
      final sn = [c.serieDocumentoProveedor, c.numeroDocumentoProveedor]
          .where((e) => e != null && e.isNotEmpty)
          .join('-');
      if (sn.isNotEmpty) partes.add(sn);
      return partes.isEmpty ? '—' : partes.join(' ');
    }

    String pago() {
      final esCredito =
          c.terminosPago == 'CREDITO' || (c.diasCredito ?? 0) > 0;
      if (esCredito) {
        final venc = c.fechaVencimientoPago != null
            ? ' · vence ${DateFormatter.formatDate(c.fechaVencimientoPago!)}'
            : '';
        return 'Crédito ${c.diasCredito ?? 0} días$venc';
      }
      return 'Contado';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _estadoChip(c),
            const Spacer(),
            Text(
              DateFormatter.formatDate(c.fechaRecepcion),
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _infoRow('Proveedor', c.proveedorNombre),
        _infoRow('Documento', doc()),
        _infoRow('Condición', pago()),
        _infoRow('Moneda', c.moneda),
        if (c.observaciones != null && c.observaciones!.trim().isNotEmpty)
          _infoRow('Obs.', c.observaciones!),
        const SizedBox(height: 12),
        const AppSubtitle('Ítems', fontSize: 11, color: AppColors.blueGrey),
        const SizedBox(height: 4),
        _itemsTabla(c, detalles),
        const SizedBox(height: 12),
        _totales(c),
      ],
    );
  }

  Widget _estadoChip(Compra c) {
    final color = switch (c.estado) {
      EstadoCompra.CONFIRMADA => Colors.green,
      EstadoCompra.ANULADA => Colors.red,
      EstadoCompra.BORRADOR => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.6),
      ),
      child: Text(
        c.estadoTexto,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(label,
                style:
                    TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _itemsTabla(Compra c, List<CompraDetalle> detalles) {
    final headerStyle = TextStyle(
        fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700);
    final cellStyle = TextStyle(fontSize: 9.5, color: Colors.grey.shade800);
    final cellBold = TextStyle(
        fontSize: 9.5, color: Colors.grey.shade900, fontWeight: FontWeight.w700);
    final cellTiny = TextStyle(fontSize: 8, color: Colors.grey.shade500);

    final header = TableRow(
      decoration:
          BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07)),
      children: [
        _celda('Descripción', headerStyle),
        _celda('Cant.', headerStyle, align: TextAlign.right),
        _celda('Total', headerStyle, align: TextAlign.right),
      ],
    );

    TableRow filaItem(CompraDetalle d, int i) {
      final usaUC = d.usaUnidadCompra && d.unidadOriginalSimbolo != null;
      final cant = usaUC
          ? '${_fmtNum(d.cantidadOriginal!)} ${d.unidadOriginalSimbolo}'
          : '${d.cantidad}';
      // Empaque de ESTE ítem (override puntual o factor del producto).
      final factor = d.factorAplicado ??
          ((d.cantidadOriginal != null && d.cantidadOriginal! > 0)
              ? d.cantidad / d.cantidadOriginal!
              : null);
      final mostrarFactor = usaUC && factor != null && factor > 0;
      // Resalta la línea del producto que estamos comprando.
      final esEste = widget.varianteId != null
          ? d.varianteId == widget.varianteId
          : d.productoId == widget.productoId;
      return TableRow(
        decoration: BoxDecoration(
          color: esEste
              ? AppColors.blue1.withValues(alpha: 0.08)
              : (i.isOdd ? Colors.grey.withValues(alpha: 0.04) : Colors.white),
        ),
        children: [
          _celda(d.descripcion, esEste ? cellBold : cellStyle, maxLines: 2),
          mostrarFactor
              ? _celdaDual(cant, '× ${_fmtNum(factor)} u', cellStyle, cellTiny)
              : _celda(cant, cellStyle, align: TextAlign.right, maxLines: 1),
          _celda(_money(c.moneda, d.total), cellBold,
              align: TextAlign.right, maxLines: 1),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1.0),
          2: FlexColumnWidth(1.1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          header,
          ...detalles.asMap().entries.map((e) => filaItem(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _totales(Compra c) {
    Widget linea(String label, double valor, {bool fuerte = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: fuerte ? 12 : 10.5,
                    color: color ?? Colors.grey.shade600,
                    fontWeight: fuerte ? FontWeight.bold : FontWeight.w500)),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              child: Text(
                _money(c.moneda, valor),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: fuerte ? 13 : 11,
                    color: color ??
                        (fuerte ? AppColors.blue1 : Colors.grey.shade800),
                    fontWeight: fuerte ? FontWeight.bold : FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        linea('Subtotal', c.subtotal),
        if (c.descuento > 0)
          linea('Descuento', -c.descuento, color: Colors.red.shade400),
        linea('IGV', c.impuestos),
        const Divider(height: 12),
        linea('Total', c.total, fuerte: true),
      ],
    );
  }
}
