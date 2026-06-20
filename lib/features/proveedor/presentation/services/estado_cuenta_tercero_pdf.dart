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
    final movs = (data['movimientos'] as List?) ?? [];
    final ventas = movs.where((m) => m['tipo'] == 'VENTA').toList();
    final compras = movs.where((m) => m['tipo'] == 'COMPRA').toList();

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
          pw.SizedBox(height: 14),
          if (ventas.isNotEmpty) ...[
            _seccionTitulo('VENTAS — lo que me debe', PdfColors.green800),
            ...ventas.map(_docBloque),
            pw.SizedBox(height: 12),
          ],
          if (compras.isNotEmpty) ...[
            _seccionTitulo('COMPRAS — lo que le debo', PdfColors.red800),
            ...compras.map(_docBloque),
            pw.SizedBox(height: 12),
          ],
          _netoFinal(neto),
        ],
      ),
    );
    return pdf.save();
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
            color: PdfColor.fromInt(color.toInt()).shade(0.05),
            border: pw.Border.all(color: color, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(titulo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            if (entradas.isEmpty)
              pw.Text('—', style: const pw.TextStyle(fontSize: 11))
            else
              ...entradas.map((e) => pw.Text(_money(e.key, e.value),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color))),
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
              pw.Expanded(child: pw.Text('$cant x ${i['descripcion']}', style: const pw.TextStyle(fontSize: 9))),
              pw.Text(_money(moneda, i['total']), style: const pw.TextStyle(fontSize: 9)),
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
      decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue800)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('SALDO NETO', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 2),
        if (entradas.isEmpty)
          pw.Text('Sin saldos', style: const pw.TextStyle(fontSize: 11))
        else
          ...entradas.map((e) {
            final v = _d(e.value);
            final texto = v.abs() < 0.01
                ? '${_sim(e.key)} 0.00 — saldado'
                : v > 0
                    ? 'Le debo ${_money(e.key, v)}'
                    : 'Me debe ${_money(e.key, -v)}';
            final color = v.abs() < 0.01 ? PdfColors.grey700 : (v > 0 ? PdfColors.red800 : PdfColors.green800);
            return pw.Text(texto, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color));
          }),
      ]),
    );
  }
}
