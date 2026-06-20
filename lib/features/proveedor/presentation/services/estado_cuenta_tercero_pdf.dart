import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/utils/date_formatter.dart';

/// Genera el PDF "Estado de cuenta" de un tercero (proveedor que también es
/// cliente) para compartir: resumen del neto por moneda + ventas (lo que me
/// debe) y compras (lo que le debo), cada documento con sus ítems y total.
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
    final hayPend = pendVentas.isNotEmpty || pendCompras.isNotEmpty;
    final hayHist = histVentas.isNotEmpty || histCompras.isNotEmpty;
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
          pw.SizedBox(height: 10),
          _clienteBlock(prov),
          pw.SizedBox(height: 12),
          _resumen(leDebo, meDebe, neto),
          pw.SizedBox(height: 6),
          _netoFinal(neto),
          pw.SizedBox(height: 14),

          // ── PENDIENTES (deuda viva) ──
          _seccionTitulo('PENDIENTES DE PAGO', PdfColors.blue800),
          if (!hayPend)
            pw.Text('No hay saldos pendientes.', style: const pw.TextStyle(fontSize: 10))
          else ...[
            if (pendVentas.isNotEmpty) ...[
              _subtitulo('Ventas por cobrar', PdfColors.green800),
              ...pendVentas.map(_docBloque),
            ],
            if (pendCompras.isNotEmpty) ...[
              _subtitulo('Compras por pagar', PdfColors.red800),
              ...pendCompras.map(_docBloque),
            ],
          ],
          pw.SizedBox(height: 14),

          // ── HISTORIAL (rango) ──
          _seccionTitulo('HISTORIAL$rangoTxt', PdfColors.blue800),
          if (!hayHist)
            pw.Text('Sin movimientos en el período.', style: const pw.TextStyle(fontSize: 10))
          else ...[
            if (histVentas.isNotEmpty) ...[
              _subtitulo('Ventas', PdfColors.green800),
              ...histVentas.map(_docBloque),
            ],
            if (histCompras.isNotEmpty) ...[
              _subtitulo('Compras', PdfColors.red800),
              ...histCompras.map(_docBloque),
            ],
          ],
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _subtitulo(String t, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
    );
  }

  static pw.Widget _header(String empresa, String? ruc, DateTime fecha) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(empresa, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
              if (ruc != null && ruc.isNotEmpty)
                pw.Text('RUC: $ruc', style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('ESTADO DE CUENTA',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.Text('Emitido: ${DateFormatter.formatDate(fecha)}', style: const pw.TextStyle(fontSize: 9)),
            ]),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.blue800),
      ],
    );
  }

  static pw.Widget _clienteBlock(Map prov) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Cliente', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Text(prov['nombre']?.toString() ?? '',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        if ((prov['numeroDocumento']?.toString() ?? '').isNotEmpty)
          pw.Text('RUC/Doc: ${prov['numeroDocumento']}', style: const pw.TextStyle(fontSize: 10)),
      ]),
    );
  }

  static pw.Widget _resumen(Map leDebo, Map meDebe, Map neto) {
    pw.Widget col(String titulo, Map porMoneda, PdfColor color) {
      final entradas = porMoneda.entries.where((e) => _d(e.value).abs() > 0.001).toList();
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          decoration: pw.BoxDecoration(
            color: color, // fondo sólido para que resalte
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(titulo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.SizedBox(height: 2),
            if (entradas.isEmpty)
              pw.Text('—', style: const pw.TextStyle(fontSize: 11, color: PdfColors.white))
            else
              ...entradas.map((e) => pw.Text(_money(e.key, e.value),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
          ]),
        ),
      );
    }

    return pw.Row(children: [
      col('Le debo (compras)', leDebo, PdfColors.red800),
      col('Me debe (ventas)', meDebe, PdfColors.green800),
    ]);
  }

  static pw.Widget _seccionTitulo(String t, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      color: PdfColor.fromInt(color.toInt()).shade(0.08),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
    );
  }

  static pw.Widget _docBloque(dynamic mov) {
    final m = mov as Map;
    final moneda = m['moneda']?.toString();
    final fecha = m['fecha'] != null ? DateTime.tryParse(m['fecha'].toString()) : null;
    final items = (m['items'] as List?) ?? [];
    final saldo = _d(m['saldoPendiente']);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('${m['codigo'] ?? ''}  ·  ${fecha != null ? DateFormatter.formatDate(fecha) : ''}  ·  ${m['estado'] ?? ''}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text('Total ${_money(moneda, m['total'])}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 3),
        // Ítems
        ...items.map((it) {
          final i = it as Map;
          final c = _d(i['cantidad']);
          final cant = c == c.roundToDouble() ? c.toStringAsFixed(0) : c.toStringAsFixed(2);
          return pw.Padding(
            padding: const pw.EdgeInsets.only(left: 6, top: 1),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Expanded(child: pw.Text('$cant x ${i['descripcion']}', style: const pw.TextStyle(fontSize: 7))),
              pw.Text(_money(moneda, i['total']), style: const pw.TextStyle(fontSize: 7)),
            ]),
          );
        }),
        if (saldo > 0.001)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text('Saldo pendiente: ${_money(moneda, saldo)}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
          ),
      ]),
    );
  }

  static pw.Widget _netoFinal(Map neto) {
    final entradas = neto.entries.toList();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.blue700), // celeste sólido
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('SALDO NETO', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        pw.SizedBox(height: 2),
        if (entradas.isEmpty)
          pw.Text('Sin saldos', style: const pw.TextStyle(fontSize: 11, color: PdfColors.white))
        else
          ...entradas.map((e) {
            final v = _d(e.value);
            final texto = v.abs() < 0.01
                ? '${_sim(e.key)} 0.00 — saldado'
                : v > 0
                    ? 'Le debo ${_money(e.key, v)}'
                    : 'Me debe ${_money(e.key, -v)}';
            return pw.Text(texto, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white));
          }),
      ]),
    );
  }
}
