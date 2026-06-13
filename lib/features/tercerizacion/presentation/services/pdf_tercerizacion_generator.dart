import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/tercerizacion.dart';

/// Hoja de derivación B2B (A4): documento profesional de una tercerización.
/// Autocontenido — no depende de la config del destino (datos denormalizados).
class PdfTercerizacionGenerator {
  static const _azul = PdfColor.fromInt(0xFF004A94);
  static const _gris = PdfColor.fromInt(0xFF6B7280);
  static const _grisClaro = PdfColor.fromInt(0xFFF3F4F6);

  static String _estadoLabel(String e) {
    const m = {
      'PENDIENTE': 'Pendiente',
      'ACEPTADO': 'Aceptada',
      'RECHAZADO': 'Rechazada',
      'EN_PROCESO': 'En proceso',
      'COMPLETADO': 'Completada',
      'CANCELADO': 'Cancelada',
    };
    return m[e] ?? e;
  }

  static String _tipoNotaLabel(String t) {
    const m = {
      'NOTA': 'Nota',
      'REQUERIMIENTO': 'Requerimiento',
      'CAMBIO_ESTADO': 'Estado',
      'SISTEMA': 'Sistema',
    };
    return m[t] ?? t;
  }

  static String _valorAdicional(dynamic v) {
    if (v == null) return '';
    if (v is List) return v.join(', ');
    if (v is Map) {
      return v.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
    }
    return v.toString();
  }

  static Future<Uint8List> generar({
    required TercerizacionServicio t,
    List<TercerizacionNota> notas = const [],
  }) async {
    final fontRegular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Oxygen-Regular.ttf'));
    final fontBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Oxygen-Bold.ttf'));
    final fontLight =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Oxygen-Light.ttf'));

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontLight,
        boldItalic: fontBold,
      ),
    );

    final datos = (t.datosEquipo);
    final adicionales = (t.datosAdicionales ?? [])
        .whereType<Map>()
        .map((m) => MapEntry(
              (m['etiqueta'] ?? '').toString(),
              _valorAdicional(m['valor']),
            ))
        .where((e) => e.key.isNotEmpty && e.value.isNotEmpty)
        .toList();
    final componentes = (t.componentesData is List)
        ? (t.componentesData as List).whereType<Map>().toList()
        : <Map>[];
    final sintomas = (t.sintomas is List)
        ? (t.sintomas as List).map((e) => e.toString()).toList()
        : <String>[];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(t),
          pw.SizedBox(height: 14),
          _empresas(t),
          pw.SizedBox(height: 12),
          _equipo(datos),
          if (t.descripcionProblema != null && t.descripcionProblema!.isNotEmpty)
            _bloqueTexto('Problema reportado', t.descripcionProblema!),
          if (sintomas.isNotEmpty) _bloqueTexto('Síntomas', sintomas.join(', ')),
          if (componentes.isNotEmpty) _componentes(componentes),
          if (adicionales.isNotEmpty) _adicionales(adicionales),
          if ((t.precioB2B ?? 0) > 0) _precio(t),
          if (notas.isNotEmpty) _bitacora(t, notas),
          pw.SizedBox(height: 30),
          _firma(),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Secciones ───

  static pw.Widget _header(TercerizacionServicio t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('HOJA DE TERCERIZACIÓN B2B',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _azul)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _grisClaro,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(_estadoLabel(t.estado),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _azul)),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text('Emitida: ${DateFormatter.formatDate(t.fechaSolicitud)}',
            style: const pw.TextStyle(fontSize: 9, color: _gris)),
        pw.Divider(color: _azul, thickness: 1.2),
      ],
    );
  }

  static pw.Widget _empresas(TercerizacionServicio t) {
    pw.Widget col(String label, EmpresaResumen? e) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: _grisClaro,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _gris)),
              pw.SizedBox(height: 2),
              pw.Text(e?.nombre ?? '—',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              if (e?.telefono != null)
                pw.Text('Tel: ${e!.telefono}', style: const pw.TextStyle(fontSize: 9, color: _gris)),
              if (e?.direccionFiscal != null)
                pw.Text(e!.direccionFiscal!, style: const pw.TextStyle(fontSize: 8, color: _gris)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        col('EMPRESA QUE TERCERIZA (ORIGEN)', t.empresaOrigen),
        pw.SizedBox(width: 10),
        col('EMPRESA QUE EJECUTA (DESTINO)', t.empresaDestino),
      ],
    );
  }

  static pw.Widget _tituloSeccion(String txt) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Text(txt.toUpperCase(),
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _azul)),
    );
  }

  static pw.Widget _equipo(Map<String, dynamic> d) {
    final filas = <List<String>>[
      if (d['tipoEquipo'] != null) ['Tipo', '${d['tipoEquipo']}'],
      if (d['marcaEquipo'] != null) ['Marca', '${d['marcaEquipo']}'],
      if (d['numeroSerie'] != null) ['N° Serie', '${d['numeroSerie']}'],
      if (d['condicionEquipo'] != null) ['Condición', '${d['condicionEquipo']}'],
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Equipo'),
        ...filas.map((f) => _kv(f[0], f[1])),
      ],
    );
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 90, child: pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: _gris))),
          pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  static pw.Widget _bloqueTexto(String titulo, String texto) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion(titulo),
        pw.Text(texto, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _componentes(List<Map> comps) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Detalle de trabajos'),
        ...comps.map((c) {
          final comp = c['componente'] is Map ? c['componente'] as Map : const {};
          final nombre = (comp['nombre'] ?? comp['codigo'] ?? 'Componente').toString();
          final accion = (c['tipoAccion'] ?? '').toString();
          final desc = (c['descripcionAccion'] ?? '').toString();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• $nombre${accion.isNotEmpty ? '  ($accion)' : ''}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                if (desc.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10),
                    child: pw.Text(desc, style: const pw.TextStyle(fontSize: 8, color: _gris)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _adicionales(List<MapEntry<String, String>> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Datos adicionales'),
        ...items.map((e) => _kv(e.key, e.value)),
      ],
    );
  }

  static pw.Widget _precio(TercerizacionServicio t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Precio B2B'),
        _kv('Monto', 'S/ ${(t.precioB2B ?? 0).toStringAsFixed(2)}'),
        if (t.metodoPagoB2B != null) _kv('Método', t.metodoPagoB2B!),
      ],
    );
  }

  static pw.Widget _bitacora(TercerizacionServicio t, List<TercerizacionNota> notas) {
    String autor(String empresaAutorId) {
      if (empresaAutorId == t.empresaOrigenId) return t.empresaOrigen?.nombre ?? 'Origen';
      if (empresaAutorId == t.empresaDestinoId) return t.empresaDestino?.nombre ?? 'Destino';
      return 'Empresa';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Bitácora'),
        ...notas.map((n) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '[${_tipoNotaLabel(n.tipo)}] ${autor(n.empresaAutorId)} · ${DateFormatter.formatDate(n.creadoEn)}',
                    style: const pw.TextStyle(fontSize: 7.5, color: _gris),
                  ),
                  pw.Text(n.contenido, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            )),
      ],
    );
  }

  static pw.Widget _firma() {
    pw.Widget linea(String label) => pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(height: 0.8, color: _gris, margin: const pw.EdgeInsets.symmetric(horizontal: 10)),
              pw.SizedBox(height: 3),
              pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _gris)),
            ],
          ),
        );
    return pw.Row(children: [linea('Entrega (origen)'), pw.SizedBox(width: 30), linea('Recibe (destino)')]);
  }
}
