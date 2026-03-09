import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/orden_servicio.dart';

/// Color primario por defecto
const _defaultPrimaryHex = '#1565C0';

PdfColor _hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return PdfColor.fromInt(int.parse(hex, radix: 16));
}

class PdfOrdenServicioGenerator {
  static Future<Uint8List> generarTicket({
    required OrdenServicio orden,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logoEmpresa,
    String? colorPrimario,
    Uint8List? firmaCliente,
  }) async {
    // Load Unicode-compatible fonts
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Oxygen-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Oxygen-Bold.ttf'),
    );

    final fontLight = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Oxygen-Light.ttf'),
    );
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontLight,
        boldItalic: fontBold,
      ),
    );
    final primaryColor = _hexToColor(colorPrimario ?? _defaultPrimaryHex);
    const fsSmall = 7.5;
    const fsTiny = 6.5;

    final ticketWidth = 80 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(ticketWidth, double.infinity),
        margin: const pw.EdgeInsets.all(8 * PdfPageFormat.mm),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // ── Header: Empresa ──
            _buildEmpresaHeader(
              empresaNombre: empresaNombre,
              empresaRuc: empresaRuc,
              empresaDireccion: empresaDireccion,
              empresaTelefono: empresaTelefono,
              sedeNombre: sedeNombre,
              logo: logoEmpresa,
              primaryColor: primaryColor,
            ),
            pw.SizedBox(height: 8),
            _divider(),
            pw.SizedBox(height: 6),

            // ── Titulo ──
            pw.Center(
              child: pw.Text(
                'ORDEN DE SERVICIO',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                orden.codigo,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Fecha: ${DateFormatter.formatDate(orden.creadoEn)}',
                style: const pw.TextStyle(fontSize: fsTiny),
              ),
            ),
            if (orden.cantidadReingresos > 0) ...[
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  child: pw.Text(
                    'REINGRESO #${orden.cantidadReingresos}',
                    style: pw.TextStyle(fontSize: fsTiny, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 6),
            _divider(),
            pw.SizedBox(height: 6),

            // ── Cliente ──
            if (orden.cliente != null) ...[
              pw.Text('CLIENTE',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              _infoRow('Nombre', orden.cliente!.nombreCompleto, fs: fsSmall),
              if (orden.cliente!.documentoNumero != null)
                _infoRow('Documento', orden.cliente!.documentoNumero!, fs: fsSmall),
              if (orden.cliente!.telefono != null)
                _infoRow('Telefono', orden.cliente!.telefono!, fs: fsSmall),
              if (orden.cliente!.email != null)
                _infoRow('Email', orden.cliente!.email!, fs: fsSmall),
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
            ],

            // ── Detalle del servicio ──
            pw.Text('DETALLE DEL SERVICIO',
                style: pw.TextStyle(
                    fontSize: fsSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor)),
            pw.SizedBox(height: 3),
            _infoRow('Tipo', _tipoServicioLabel(orden.tipoServicio), fs: fsSmall),
            _infoRow('Estado', _estadoLabel(orden.estado), fs: fsSmall),
            _infoRow('Prioridad', orden.prioridad, fs: fsSmall),
            if (orden.tecnico != null)
              _infoRow('Tecnico', orden.tecnico!.nombreCompleto, fs: fsSmall),

            // ── Equipo ──
            if (orden.tipoEquipo != null || orden.marcaEquipo != null || orden.numeroSerie != null) ...[
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
              pw.Text('EQUIPO',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              if (orden.tipoEquipo != null)
                _infoRow('Tipo', orden.tipoEquipo!, fs: fsSmall),
              if (orden.marcaEquipo != null)
                _infoRow('Marca', orden.marcaEquipo!, fs: fsSmall),
              if (orden.numeroSerie != null)
                _infoRow('N/Serie', orden.numeroSerie!, fs: fsSmall),
              if (orden.condicionEquipo != null)
                _infoRow('Condicion', orden.condicionEquipo!, fs: fsSmall),
            ],

            // ── Datos Personalizados (después de equipo) ──
            if (orden.datosPersonalizados != null && orden.datosPersonalizados!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
              pw.Text('DATOS ADICIONALES',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              ...orden.datosPersonalizados!.entries
                  .where((entry) => _isRelevantField(entry.value))
                  .map((entry) {
                final value = _formatFieldValue(entry.value);
                if (value.isEmpty) return pw.SizedBox.shrink();
                return _infoRow(entry.key, value, fs: fsSmall);
              }),
            ],

            // ── Problema ──
            if (orden.descripcionProblema != null) ...[
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
              pw.Text('PROBLEMA REPORTADO',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              pw.Text(orden.descripcionProblema!,
                  style: const pw.TextStyle(fontSize: fsSmall)),
            ],

            // ── Accesorios ──
            if (orden.accesorios != null) ...[
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
              pw.Text('ACCESORIOS ENTREGADOS',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              pw.Text(
                _formatAccesorios(orden.accesorios),
                style: const pw.TextStyle(fontSize: fsSmall),
              ),
            ],

            // ── Componentes detallados ──
            if (orden.componentes != null && orden.componentes!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
              pw.Text('DETALLE DE TRABAJOS',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              ...orden.componentes!.map((comp) {
                final nombre = comp.componente?.displayName ?? comp.componenteId;
                final costoTotal = (comp.costoAccion ?? 0) + (comp.costoRepuestos ?? 0);
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ', style: pw.TextStyle(fontSize: fsSmall, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Text(
                              '$nombre (${comp.tipoAccion})',
                              style: pw.TextStyle(fontSize: fsSmall, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          if (costoTotal > 0)
                            pw.Text('S/ ${costoTotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: fsSmall, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      if (comp.descripcionAccion != null && comp.descripcionAccion!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8),
                          child: pw.Text(comp.descripcionAccion!,
                              style: const pw.TextStyle(fontSize: fsTiny)),
                        ),
                      if (comp.costoAccion != null || comp.costoRepuestos != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8),
                          child: pw.Row(
                            children: [
                              if (comp.costoAccion != null)
                                pw.Text('M.O: S/ ${comp.costoAccion!.toStringAsFixed(2)}  ',
                                    style: const pw.TextStyle(fontSize: fsTiny)),
                              if (comp.costoRepuestos != null)
                                pw.Text('Rep: S/ ${comp.costoRepuestos!.toStringAsFixed(2)}',
                                    style: const pw.TextStyle(fontSize: fsTiny)),
                            ],
                          ),
                        ),
                      if (comp.garantiaMeses != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8),
                          child: pw.Text('Garantia: ${comp.garantiaMeses} meses',
                              style: const pw.TextStyle(fontSize: fsTiny)),
                        ),
                    ],
                  ),
                );
              }),
            ],

            // ── Notas ──
            if (orden.notas != null && orden.notas!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 6),
              pw.Text('NOTAS',
                  style: pw.TextStyle(
                      fontSize: fsSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              pw.Text(orden.notas!, style: const pw.TextStyle(fontSize: fsSmall)),
            ],

            // ── Resumen de costos (después de notas) ──
            ...() {
              final comps = orden.componentes ?? [];
              double totalMO = 0;
              double totalRep = 0;
              for (final comp in comps) {
                totalMO += comp.costoAccion ?? 0;
                totalRep += comp.costoRepuestos ?? 0;
              }
              final subtotalComp = totalMO + totalRep;
              final hasCosts = subtotalComp > 0 ||
                  orden.costoTotal != null;
              if (!hasCosts) return <pw.Widget>[];

              final costoFinal = orden.costoFinal;
              final saldoPendiente = orden.saldoPendiente;

              return <pw.Widget>[
                pw.SizedBox(height: 6),
                _divider(),
                pw.SizedBox(height: 6),
                pw.Text('COSTOS',
                    style: pw.TextStyle(
                        fontSize: fsSmall,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor)),
                pw.SizedBox(height: 3),
                if (totalMO > 0)
                  _costRow('Mano de obra', 'S/ ${totalMO.toStringAsFixed(2)}', fs: fsSmall),
                if (totalRep > 0)
                  _costRow('Repuestos', 'S/ ${totalRep.toStringAsFixed(2)}', fs: fsSmall),
                if (totalMO > 0 && totalRep > 0)
                  _costRow('Subtotal componentes', 'S/ ${subtotalComp.toStringAsFixed(2)}', fs: fsSmall),
                if (orden.costoTotal != null)
                  _costRow('Costo del servicio', 'S/ ${orden.costoTotal!.toStringAsFixed(2)}', fs: fsSmall),
                if (orden.costoTotal != null && subtotalComp > 0)
                  _costRow('Subtotal', 'S/ ${orden.subtotal!.toStringAsFixed(2)}', fs: fsSmall, bold: true),
                if (orden.descuento != null && orden.descuento! > 0)
                  _costRow('Descuento', '- S/ ${orden.descuento!.toStringAsFixed(2)}', fs: fsSmall),
                if (costoFinal != null)
                  _costRow('Costo final', 'S/ ${costoFinal.toStringAsFixed(2)}', fs: fsSmall, bold: true),
                if (orden.adelanto != null && orden.adelanto! > 0)
                  _costRow('Adelanto${orden.metodoPagoAdelanto != null ? " (${orden.metodoPagoAdelanto})" : ""}',
                      'S/ ${orden.adelanto!.toStringAsFixed(2)}', fs: fsSmall),
                if (saldoPendiente != null)
                  _costRow(
                    saldoPendiente <= 0 ? 'PAGADO' : 'SALDO PENDIENTE',
                    'S/ ${saldoPendiente <= 0 ? "0.00" : saldoPendiente.toStringAsFixed(2)}',
                    fs: fsSmall,
                    bold: true,
                  )
                else if (orden.costoTotal == null && subtotalComp > 0)
                  _costRow('TOTAL', 'S/ ${subtotalComp.toStringAsFixed(2)}', fs: fsSmall, bold: true),
              ];
            }(),

            // ── QR Code ──
            pw.SizedBox(height: 10),
            _divider(),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: '${orden.codigo}|${_estadoLabel(orden.estado)}|${DateFormatter.formatDate(orden.creadoEn)}',
                width: 60,
                height: 60,
              ),
            ),
            pw.SizedBox(height: 4),

            // ── Footer ──
            _divider(),
            pw.SizedBox(height: 6),

            // Firma del cliente
            if (firmaCliente != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(firmaCliente),
                  height: 50,
                  width: 120,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.Center(
                child: pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Center(
                      child: pw.Text('Firma del cliente',
                          style: const pw.TextStyle(fontSize: fsTiny)),
                    ),
                  ),
                ),
              ),
            ] else ...[
              pw.SizedBox(height: 25),
              pw.Center(
                child: pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Center(
                      child: pw.Text('Firma del cliente',
                          style: const pw.TextStyle(fontSize: fsTiny)),
                    ),
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Gracias por su preferencia',
                style: pw.TextStyle(
                  fontSize: fsTiny,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Helpers ──

  static pw.Widget _buildEmpresaHeader({
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logo,
    required PdfColor primaryColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Image(
            pw.MemoryImage(logo),
            height: 50,
            width: 120,
            fit: pw.BoxFit.contain,
          ),
        pw.SizedBox(height: logo != null ? 4 : 0),
        pw.Text(
          empresaNombre,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        if (sedeNombre != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(sedeNombre,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center),
        ],
        if (empresaRuc != null) ...[
          pw.SizedBox(height: 2),
          pw.Text('RUC: $empresaRuc', style: const pw.TextStyle(fontSize: 7)),
        ],
        if (empresaDireccion != null) ...[
          pw.SizedBox(height: 1),
          pw.Text(empresaDireccion,
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center),
        ],
        if (empresaTelefono != null) ...[
          pw.SizedBox(height: 1),
          pw.Text('Tel: $empresaTelefono',
              style: const pw.TextStyle(fontSize: 7)),
        ],
      ],
    );
  }

  static String _formatAccesorios(dynamic accesorios) {
    if (accesorios == null) return '';
    if (accesorios is List) {
      return accesorios.map((e) => e.toString()).join(', ');
    }
    if (accesorios is Map) {
      return accesorios.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return accesorios.toString();
  }

  static pw.Widget _divider() {
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.5, style: pw.BorderStyle.dashed),
        ),
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value, {double fs = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text('$label:',
                style: pw.TextStyle(fontSize: fs, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: fs)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _costRow(String label, String value, {double fs = 7, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: fs,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fs,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static String _tipoServicioLabel(String tipo) {
    const labels = {
      'REPARACION': 'Reparacion',
      'MANTENIMIENTO': 'Mantenimiento',
      'INSTALACION': 'Instalacion',
      'DIAGNOSTICO': 'Diagnostico',
      'ACTUALIZACION': 'Actualizacion',
      'LIMPIEZA': 'Limpieza',
      'RECUPERACION_DATOS': 'Recuperacion de datos',
      'CONFIGURACION': 'Configuracion',
      'CONSULTORIA': 'Consultoria',
      'FORMACION': 'Formacion',
      'SOPORTE': 'Soporte',
    };
    return labels[tipo] ?? tipo;
  }

  /// Filtra campos no relevantes para el ticket (imágenes, booleanos)
  static bool _isRelevantField(dynamic value) {
    if (value == null) return false;
    if (value is bool) return false;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == 'false') return false;
    }
    return true;
  }

  /// Formatea valores de campos personalizados para lectura legible
  static String _formatFieldValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => '${e.key}: ${e.value}')
          .join(' | ');
    }
    if (value is List) {
      return value.map((e) => _formatFieldValue(e)).join(', ');
    }
    return value.toString();
  }

  static String _estadoLabel(String estado) {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'En Diagnostico',
      'ESPERANDO_APROBACION': 'Esperando Aprobacion',
      'EN_REPARACION': 'En Reparacion',
      'PENDIENTE_PIEZAS': 'Pendiente Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Listo para Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }
}
