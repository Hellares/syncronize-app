import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/services/pdf/builders/pdf_header_builder.dart';
import 'package:syncronize/core/services/pdf/builders/pdf_party_builder.dart';
import 'package:syncronize/core/services/pdf/pdf_document_service.dart';
import 'package:syncronize/core/services/pdf/pdf_document_style.dart';
import 'package:syncronize/core/services/pdf/pdf_row_builders.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/estado_cuenta_cliente.dart';

/// Genera el PDF del estado de cuenta de un cliente (resumen + ventas a crédito
/// + abonos). Reusa la infraestructura de PDF compartida (A4).
class PdfEstadoCuentaGenerator {
  static Future<Uint8List> generar({
    required EstadoCuentaCliente estado,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    Uint8List? logoEmpresa,
  }) async {
    final style = PdfDocumentStyle.fromConfig(
      documentConfig: null,
      empresaNombre: empresaNombre,
      empresaRuc: empresaRuc,
      empresaDireccion: empresaDireccion,
      empresaTelefono: empresaTelefono,
      defaultMarginMm: 10.0,
    );
    final primary = style.colorPrimario;
    final c = estado.cliente;
    final r = estado.resumen;

    final body = <pw.Widget>[
      PdfHeaderBuilder.build(
        empresaNombre: style.empresaNombre,
        empresaRuc: style.empresaRuc,
        empresaDireccion: style.empresaDireccion,
        empresaTelefono: style.empresaTelefono,
        logo: style.showLogo ? logoEmpresa : null,
        tipoDocumento: 'ESTADO DE CUENTA',
        codigo: c.nombre ?? 'Cliente',
        documentLines: [
          'Fecha: ${DateFormatter.formatDate(DateTime.now())}',
          'Saldo pendiente: S/ ${r.saldoPendiente.toStringAsFixed(2)}',
        ],
        primaryColor: primary,
        showDatosEmpresa: style.showDatosEmpresa,
        isTicket: false,
      ),
      pw.SizedBox(height: 20),
      PdfPartyBuilder.build(
        title: 'CLIENTE',
        fields: [
          PdfPartyField('Nombre', c.nombre ?? '—'),
          if (c.documento != null && c.documento!.isNotEmpty)
            PdfPartyField('RUC/DNI', c.documento!),
          PdfPartyField('Tipo', c.tipo == 'EMPRESA' ? 'Empresa' : 'Persona'),
        ],
        primaryColor: primary,
        isTicket: false,
      ),
      pw.SizedBox(height: 16),
      _resumen(r),
      pw.SizedBox(height: 18),
      _ventasTable(estado.ventas, primary),
      pw.SizedBox(height: 18),
      _abonosTable(estado.abonos, primary),
    ];

    return PdfDocumentService.build(
      style: style,
      bodyWidgets: body,
      footerText:
          'Estado de cuenta generado el ${DateFormatter.formatDate(DateTime.now())}',
      showPaginacion: true,
    );
  }

  static pw.Widget _resumen(ResumenEstadoCuenta r) {
    pw.Widget item(String label, String value) => pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.SizedBox(height: 2),
              pw.Text(value,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          item('Saldo pendiente', 'S/ ${r.saldoPendiente.toStringAsFixed(2)}'),
          item('Total vendido', 'S/ ${r.totalVendido.toStringAsFixed(2)}'),
          item('Total abonado', 'S/ ${r.totalAbonado.toStringAsFixed(2)}'),
          if (r.totalMora > 0) item('Mora', 'S/ ${r.totalMora.toStringAsFixed(2)}'),
          item('Ventas', '${r.cantidadVentas}'),
        ],
      ),
    );
  }

  static pw.Widget _ventasTable(List<VentaCreditoItem> ventas, PdfColor primary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('VENTAS A CRÉDITO',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (ventas.isEmpty)
          pw.Text('Sin ventas a crédito',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FixedColumnWidth(60),
              2: pw.FixedColumnWidth(60),
              3: pw.FixedColumnWidth(60),
              4: pw.FixedColumnWidth(60),
              5: pw.FixedColumnWidth(60),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primary),
                children: [
                  _cell('Código', header: true),
                  _cell('Fecha', header: true, align: pw.TextAlign.center),
                  _cell('Vence', header: true, align: pw.TextAlign.center),
                  _cell('Total', header: true, align: pw.TextAlign.right),
                  _cell('Saldo', header: true, align: pw.TextAlign.right),
                  _cell('Estado', header: true, align: pw.TextAlign.center),
                ],
              ),
              ...ventas.asMap().entries.map((e) {
                final v = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: e.key % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                  ),
                  children: [
                    _cell(v.codigo),
                    _cell(DateFormatter.formatDate(v.fechaVenta ?? DateTime.now()),
                        align: pw.TextAlign.center),
                    _cell(v.fechaVencimiento != null
                        ? DateFormatter.formatDate(v.fechaVencimiento!)
                        : '—',
                        align: pw.TextAlign.center),
                    _cell(v.total.toStringAsFixed(2), align: pw.TextAlign.right),
                    _cell(v.saldoPendiente.toStringAsFixed(2), align: pw.TextAlign.right),
                    _cell(v.estado, align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  static pw.Widget _abonosTable(List<AbonoItem> abonos, PdfColor primary) {
    String fuente(String? f) {
      switch (f) {
        case 'TESORERIA':
          return 'Tesorería';
        case 'CAJA':
          return 'Caja';
        case 'BANCO':
          return 'Banco';
        default:
          return f ?? '—';
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ABONOS',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (abonos.isEmpty)
          pw.Text('Sin abonos registrados',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: const {
              0: pw.FixedColumnWidth(65),
              1: pw.FlexColumnWidth(2),
              2: pw.FixedColumnWidth(70),
              3: pw.FlexColumnWidth(2),
              4: pw.FixedColumnWidth(65),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primary),
                children: [
                  _cell('Fecha', header: true, align: pw.TextAlign.center),
                  _cell('Método', header: true),
                  _cell('Fuente', header: true),
                  _cell('Venta', header: true),
                  _cell('Monto', header: true, align: pw.TextAlign.right),
                ],
              ),
              ...abonos.asMap().entries.map((e) {
                final a = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: e.key % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                  ),
                  children: [
                    _cell(a.fechaPago != null ? DateFormatter.formatDate(a.fechaPago!) : '—',
                        align: pw.TextAlign.center),
                    _cell(a.metodoPago),
                    _cell(fuente(a.fuente)),
                    _cell(a.ventaCodigo ?? '—'),
                    _cell(a.monto.toStringAsFixed(2), align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  static pw.Widget _cell(String text,
          {bool header = false, pw.TextAlign align = pw.TextAlign.left}) =>
      PdfRowBuilders.tableCell(
        text,
        isHeader: header,
        fontSize: 8.5,
        color: header ? PdfColors.white : null,
        align: align,
        padding: 5,
      );
}
