import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class EtiquetaData {
  final String nombre;
  final String codigoBarras;
  final double? precio;
  final String? sku;
  final int cantidad;

  EtiquetaData({
    required this.nombre,
    required this.codigoBarras,
    this.precio,
    this.sku,
    this.cantidad = 1,
  });
}

class ConfiguracionEtiqueta {
  final double anchoMm;
  final double altoMm;
  final String tipoBarcode; // Code128, EAN13, QR
  final bool mostrarNombre;
  final bool mostrarPrecio;
  final bool mostrarSku;
  final double tamanoFuente;

  ConfiguracionEtiqueta({
    this.anchoMm = 50,
    this.altoMm = 25,
    this.tipoBarcode = 'Code128',
    this.mostrarNombre = true,
    this.mostrarPrecio = true,
    this.mostrarSku = false,
    this.tamanoFuente = 8,
  });
}

class BarcodePdfService {
  static Future<Uint8List> generarEtiquetas({
    required List<EtiquetaData> items,
    required ConfiguracionEtiqueta config,
  }) async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat.a4;
    final etiquetaW = config.anchoMm * PdfPageFormat.mm;
    final etiquetaH = config.altoMm * PdfPageFormat.mm;
    final usableW = pageFormat.width - 10 * PdfPageFormat.mm;
    final usableH = pageFormat.height - 10 * PdfPageFormat.mm;
    final columnas = (usableW / etiquetaW).floor().clamp(1, 10);
    final filas = (usableH / etiquetaH).floor().clamp(1, 30);
    final porPagina = columnas * filas;

    // Expand by quantity
    final etiquetas = <EtiquetaData>[];
    for (final item in items) {
      for (var i = 0; i < item.cantidad; i++) {
        etiquetas.add(item);
      }
    }

    for (var i = 0; i < etiquetas.length; i += porPagina) {
      final pageItems = etiquetas.skip(i).take(porPagina).toList();

      pdf.addPage(pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(5 * PdfPageFormat.mm),
        build: (context) => pw.Wrap(
          children: pageItems
              .map((item) => _buildEtiqueta(item, config))
              .toList(),
        ),
      ));
    }

    return pdf.save();
  }

  static pw.Widget _buildEtiqueta(
    EtiquetaData item,
    ConfiguracionEtiqueta config,
  ) {
    // Auto-detect barcode type from the code value
    Barcode barcodeType;
    try {
      final code = item.codigoBarras;
      final isEan13 = code.length == 13 && RegExp(r'^\d{13}$').hasMatch(code);
      barcodeType = isEan13 ? Barcode.ean13() : Barcode.code128();
    } catch (_) {
      barcodeType = Barcode.code128();
    }

    return pw.Container(
      width: config.anchoMm * PdfPageFormat.mm,
      height: config.altoMm * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.all(1.5 * PdfPageFormat.mm),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.3, color: PdfColors.grey400),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (config.mostrarNombre)
            pw.Text(
              item.nombre,
              style: pw.TextStyle(fontSize: config.tamanoFuente - 1),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              textAlign: pw.TextAlign.center,
            ),
          if (config.mostrarNombre)
            pw.SizedBox(height: 0.5 * PdfPageFormat.mm),
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: barcodeType,
              data: item.codigoBarras,
              drawText: true,
              textStyle: const pw.TextStyle(fontSize: 6),
            ),
          ),
          if (config.mostrarPrecio && item.precio != null) ...[
            pw.SizedBox(height: 0.5 * PdfPageFormat.mm),
            pw.Text(
              'S/ ${item.precio!.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: config.tamanoFuente,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
          if (config.mostrarSku && item.sku != null && item.sku!.isNotEmpty) ...[
            pw.SizedBox(height: 0.3 * PdfPageFormat.mm),
            pw.Text(
              item.sku!,
              style: pw.TextStyle(fontSize: config.tamanoFuente - 2),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> preview(BuildContext context, Uint8List pdfBytes) {
    return Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}
