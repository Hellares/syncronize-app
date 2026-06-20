import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/utils/date_formatter.dart';

/// PDF "Estado de cuenta" del tercero — MISMO diseño que la web
/// (estado-cuenta-tercero-pdf.ts): encabezado, cliente, cards de color (le debo
/// rojo / me debe verde / neto celeste) y secciones PENDIENTES e HISTORIAL como
/// TABLAS (Documento / Detalle / Total / Saldo).
class EstadoCuentaTerceroPdf {
  static String _sim(String? m) {
    switch ((m ?? 'PEN').toUpperCase()) {
      case 'USD':
        return '\$';
      case 'PEN':
        return 'S/';
      default:
        return '${(m ?? '').toUpperCase()} ';
    }
  }

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
  static String _money(String? moneda, dynamic v) => '${_sim(moneda)} ${_d(v).toStringAsFixed(2)}';
  static String _porMoneda(Map m) {
    final e = m.entries.where((x) => _d(x.value).abs() > 0.001).toList();
    return e.isEmpty ? '-' : e.map((x) => _money(x.key.toString(), x.value)).join('   ');
  }

  static const _azul = PdfColor.fromInt(0xFF004A94);

  static Future<Uint8List> generar({
    required Map<String, dynamic> data,
    required String empresaNombre,
    String? empresaRuc,
    required DateTime fechaEmision,
  }) async {
    final pdf = pw.Document();
    final prov = (data['proveedor'] as Map?) ?? {};
    final leDebo = (data['leDeboPorMoneda'] as Map?) ?? {};
    final meDebe = (data['meDebePorMoneda'] as Map?) ?? {};
    final neto = (data['netoPorMoneda'] as Map?) ?? {};
    final pend = (data['pendientes'] as Map?) ?? {};
    final hist = (data['historial'] as Map?) ?? {};
    final rango = (data['rango'] as Map?) ?? {};
    final pendVentas = (pend['ventas'] as List?) ?? [];
    final pendCompras = (pend['compras'] as List?) ?? [];
    final histVentas = (hist['ventas'] as List?) ?? [];
    final histCompras = (hist['compras'] as List?) ?? [];
    final rDesde = rango['desde'] != null ? DateTime.tryParse(rango['desde'].toString()) : null;
    final rHasta = rango['hasta'] != null ? DateTime.tryParse(rango['hasta'].toString()) : null;
    final rangoTxt = rDesde != null && rHasta != null
        ? ' (${DateFormatter.formatDate(rDesde)} - ${DateFormatter.formatDate(rHasta)})'
        : '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        build: (_) => [
          _header(empresaNombre, empresaRuc, fechaEmision),
          pw.SizedBox(height: 8),
          _cliente(prov),
          pw.SizedBox(height: 10),
          _resumen(leDebo, meDebe),
          pw.SizedBox(height: 6),
          _netoBox(neto),
          pw.SizedBox(height: 12),
          _seccion('PENDIENTES DE PAGO'),
          if (pendVentas.isEmpty && pendCompras.isEmpty)
            pw.Text('No hay saldos pendientes.', style: const pw.TextStyle(fontSize: 9))
          else ...[
            ..._tablaDocs('Ventas por cobrar', pendVentas),
            ..._tablaDocs('Compras por pagar', pendCompras),
          ],
          pw.SizedBox(height: 10),
          _seccion('HISTORIAL$rangoTxt'),
          if (histVentas.isEmpty && histCompras.isEmpty)
            pw.Text('Sin movimientos en el período.', style: const pw.TextStyle(fontSize: 9))
          else ...[
            ..._tablaDocs('Ventas', histVentas),
            ..._tablaDocs('Compras', histCompras),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _header(String empresa, String? ruc, DateTime fecha) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(empresa, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('ESTADO DE CUENTA', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _azul)),
      ]),
      pw.SizedBox(height: 2),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(ruc != null && ruc.isNotEmpty ? 'RUC: $ruc' : '', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Emitido: ${DateFormatter.formatDate(fecha)}', style: const pw.TextStyle(fontSize: 9)),
      ]),
      pw.SizedBox(height: 2),
      pw.Divider(thickness: 0.8, color: _azul),
    ]);
  }

  static pw.Widget _cliente(Map prov) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Cliente', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.Text(prov['nombre']?.toString() ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      if ((prov['numeroDocumento']?.toString() ?? '').isNotEmpty)
        pw.Text('RUC/Doc: ${prov['numeroDocumento']}', style: const pw.TextStyle(fontSize: 9)),
    ]);
  }

  static pw.Widget _resumen(Map leDebo, Map meDebe) {
    pw.Widget box(String label, Map m, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(3)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.SizedBox(height: 2),
            pw.Text(_porMoneda(m), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          ]),
        ),
      );
    }

    return pw.Row(children: [
      box('Le debo (compras)', leDebo, const PdfColor.fromInt(0xFFC83232)),
      box('Me debe (ventas)', meDebe, const PdfColor.fromInt(0xFF289650)),
    ]);
  }

  static pw.Widget _netoBox(Map neto) {
    final txt = neto.entries.map((e) {
      final v = _d(e.value);
      return v.abs() < 0.01
          ? '${_sim(e.key.toString())} 0.00 saldado'
          : v > 0
              ? 'Le debo ${_money(e.key.toString(), v)}'
              : 'Me debe ${_money(e.key.toString(), -v)}';
    }).join('     ');
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFF145AAA), borderRadius: pw.BorderRadius.circular(3)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('SALDO NETO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        pw.SizedBox(height: 2),
        pw.Text(txt.isEmpty ? 'Sin saldos' : txt, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ]),
    );
  }

  static pw.Widget _seccion(String t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
    );
  }

  static String _itemsTxt(Map d) {
    final moneda = d['moneda']?.toString();
    final items = (d['items'] as List?) ?? [];
    if (items.isEmpty) return '-';
    return items.map((it) {
      final i = it as Map;
      final c = _d(i['cantidad']);
      final cant = c == c.roundToDouble() ? c.toStringAsFixed(0) : c.toStringAsFixed(2);
      return '$cant x ${i['descripcion']}  (${_money(moneda, i['total'])})';
    }).join('\n');
  }

  static List<pw.Widget> _tablaDocs(String titulo, List docs) {
    if (docs.isEmpty) return [];
    return [
      pw.Text(titulo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _azul)),
      pw.SizedBox(height: 1.5),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.3),
        headers: ['Documento', 'Detalle', 'Total', 'Saldo'],
        data: docs.map((mov) {
          final d = mov as Map;
          final moneda = d['moneda']?.toString();
          final fecha = d['fecha'] != null ? DateTime.tryParse(d['fecha'].toString()) : null;
          final saldo = _d(d['saldoPendiente']);
          return [
            '${d['codigo'] ?? ''}\n${fecha != null ? DateFormatter.formatDate(fecha) : ''} · ${d['estado'] ?? ''}',
            _itemsTxt(d),
            _money(moneda, d['total']),
            saldo > 0.001 ? _money(moneda, saldo) : '-',
          ];
        }).toList(),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _azul),
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        cellPadding: const pw.EdgeInsets.all(2.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.2),
          1: const pw.FlexColumnWidth(4.5),
          2: const pw.FlexColumnWidth(1.6),
          3: const pw.FlexColumnWidth(1.6),
        },
        cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
      ),
      pw.SizedBox(height: 6),
    ];
  }
}
