import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../bloc/venta_analytics/venta_analytics_state.dart';

/// Reporte PDF A4 multipágina con el dashboard completo de Estadísticas de
/// Ventas — para compartir por WhatsApp/correo o imprimir. Se construye
/// desde los DATOS del estado (no screenshots), así pagina limpio y pesa
/// poco. Evitar caracteres fuera de WinAnsi (em-dash, flechas, emoji).
class VentaAnalyticsPdfGenerator {
  static const _azul = PdfColor.fromInt(0xFF1976D2);
  static const _gris = PdfColors.grey700;
  static const _grisClaro = PdfColors.grey300;

  static const _labelsCanal = {
    'POS': 'POS',
    'ONLINE': 'Online',
    'WHATSAPP_IA': 'WhatsApp IA',
    'COTIZACION': 'Cotizacion',
  };
  static const _labelsTipoEntrega = {
    'ENVIO': 'Con envio',
    'DELIVERY': 'Delivery',
    'RECOJO': 'Recoge en tienda',
    'FISICA': 'Venta fisica',
  };
  static const _labelsMetodoPago = {
    'EFECTIVO': 'Efectivo',
    'YAPE': 'Yape',
    'PLIN': 'Plin',
    'TARJETA': 'Tarjeta',
    'TRANSFERENCIA': 'Transferencia',
    'CREDITO': 'Credito',
    'MIXTO': 'Mixto',
  };
  static const _dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

  static String _n(dynamic v) {
    if (v == null) return '0.00';
    final n = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return n.toStringAsFixed(2);
  }

  /// WinAnsi-safe: las fuentes Type1 del PDF no tienen glifos fuera de
  /// Latin-1 y los pintan como tofu (x encajonada) — p. ej. el em-dash
  /// del nombre "Producto — Variante" que arma el backend. Se mapean los
  /// típicos y el resto (emoji, símbolos) se descarta.
  static String _s(dynamic v) {
    final s = (v ?? '').toString();
    final b = StringBuffer();
    for (final c in s.runes) {
      if (c == 0x2014 || c == 0x2013) {
        b.write('-'); // em/en dash
      } else if (c == 0x2018 || c == 0x2019) {
        b.write("'");
      } else if (c == 0x201C || c == 0x201D) {
        b.write('"');
      } else if (c == 0x2026) {
        b.write('...');
      } else if (c <= 0xFF) {
        b.writeCharCode(c); // Latin-1 (tildes y ñ incluidos)
      }
    }
    return b.toString();
  }

  static Future<Uint8List> generate({
    required String empresaNombre,
    required String sedeNombre,
    required String periodoLabel,
    required VentaAnalyticsLoaded data,
  }) async {
    final doc = pw.Document();
    final ahora = DateTime.now();
    final generado =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year} '
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

    final empresa = _s(empresaNombre);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            '$empresa  ·  pag. ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _gris),
          ),
        ),
        build: (ctx) => [
          _cabecera(empresa, _s(sedeNombre), _s(periodoLabel), generado),
          pw.SizedBox(height: 10),
          _resumen(data.resumen),
          _proyeccion(data.proyeccion),
          _comparativo(data.comparativo),
          _distribuciones(data),
          _porEmisorPdf(data.porEmisor),
          _seccionTabla(
            'Productos mas vendidos',
            ['#', 'Producto', 'Categoria', 'Und.', 'Ingreso S/', 'Margen S/'],
            [
              for (final (i, p) in _tomar(data.topProductos, 10).indexed)
                [
                  '${i + 1}',
                  _s(p['nombre']),
                  _s(p['categoria']),
                  _n(p['cantidadVendida']),
                  _n(p['ingresoTotal']),
                  '${_n(p['margenTotal'])} (${_n(p['margenPorcentaje'])}%)',
                ],
            ],
          ),
          _seccionTabla(
            'Productos menos vendidos',
            ['#', 'Producto', 'Und.', 'Ingreso S/'],
            [
              for (final (i, p) in _tomar(data.menosVendidos, 5).indexed)
                [
                  '${i + 1}',
                  _s(p['nombre']),
                  _n(p['cantidadVendida']),
                  _n(p['ingresoTotal']),
                ],
            ],
          ),
          _seccionTabla(
            'Top clientes',
            ['#', 'Cliente', 'Compras', 'Monto S/'],
            [
              for (final (i, c) in _tomar(data.topClientes, 10).indexed)
                [
                  '${i + 1}',
                  _s(c['nombre']),
                  '${c['totalCompras'] ?? 0}',
                  _n(c['montoTotal']),
                ],
            ],
          ),
          _porGrupo('Ventas por categoria', data.porCategoria, 'categoria'),
          _porGrupo('Ventas por marca', data.porMarca, 'marca'),
          _porGrupo('Ventas por proveedor', data.porProveedor, 'proveedor'),
          _horasPico(data.horasPico),
          _zonas(data.entregas),
          _reposicion(data.reposicion),
          _alertas(data.alertas),
        ],
      ),
    );

    return doc.save();
  }

  // ── Secciones ─────────────────────────────────────────────────────────

  static pw.Widget _cabecera(
      String empresa, String sede, String periodo, String generado) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _azul, width: 1.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(empresa,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold, color: _azul)),
            pw.Text('Estadisticas de Ventas',
                style: const pw.TextStyle(fontSize: 10, color: _gris)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Periodo: $periodo',
                style: const pw.TextStyle(fontSize: 8, color: _gris)),
            pw.Text('Sede: $sede',
                style: const pw.TextStyle(fontSize: 8, color: _gris)),
            pw.Text('Generado: $generado',
                style: const pw.TextStyle(fontSize: 8, color: _gris)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _kpi(String titulo, String valor) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.all(2),
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _grisClaro, width: 0.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(titulo, style: const pw.TextStyle(fontSize: 7, color: _gris)),
          pw.SizedBox(height: 2),
          pw.Text(valor,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );
  }

  static pw.Widget _resumen(Map<String, dynamic> r) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _titulo('Resumen general'),
      pw.Row(children: [
        _kpi('Total ventas', '${r['totalVentas'] ?? 0}'),
        _kpi('Monto total', 'S/ ${_n(r['montoTotal'])}'),
        _kpi('Ticket promedio', 'S/ ${_n(r['promedioPorVenta'])}'),
        _kpi('Pendientes', '${r['ventasBorrador'] ?? 0}'),
      ]),
      pw.Row(children: [
        _kpi('Utilidad bruta', 'S/ ${_n(r['utilidadBruta'])}'),
        _kpi('Margen', '${_n(r['margenPorcentaje'])}%'),
        _kpi('Anuladas',
            '${r['ventasAnuladas'] ?? 0} (S/ ${_n(r['montoAnulado'])})'),
        _kpi('Devoluciones',
            '${r['devoluciones'] ?? 0} (${r['itemsDevueltos'] ?? 0} und.)'),
      ]),
    ]);
  }

  static pw.Widget _proyeccion(Map<String, dynamic> p) {
    if (p.isEmpty || p['suficiente'] != true) return pw.SizedBox();
    final variacion = (p['variacionPct'] as num?)?.toDouble();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _titulo('Proyeccion del mes'),
      pw.Text(
        'Cierre estimado: S/ ${_n(p['proyeccionCierre'])}  '
        '(entre S/ ${_n(p['proyeccionMin'])} y S/ ${_n(p['proyeccionMax'])})'
        '${variacion != null ? '  ·  ${variacion >= 0 ? '+' : ''}${variacion.toStringAsFixed(1)}% vs mes anterior' : ''}',
        style: const pw.TextStyle(fontSize: 9),
      ),
      pw.Text(
        'Lleva S/ ${_n(p['ventasActual'])} al dia ${p['diasTranscurridos']} de ${p['diasEnMes']} '
        '· ritmo por dia de semana con ${p['diasHistoria']} dias de historia',
        style: const pw.TextStyle(fontSize: 7, color: _gris),
      ),
    ]);
  }

  static pw.Widget _comparativo(Map<String, dynamic> c) {
    final actual = c['periodoActual'] as Map<String, dynamic>?;
    final anterior = c['periodoAnterior'] as Map<String, dynamic>?;
    if (actual == null && anterior == null) return pw.SizedBox();
    final cambio = ((c['porcentajeCambio'] ?? 0) as num).toDouble();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _titulo('Comparativo mensual'),
      pw.Text(
        'Anterior: S/ ${_n(anterior?['montoTotal'])} (${anterior?['totalVentas'] ?? 0} ventas)   '
        'Actual: S/ ${_n(actual?['montoTotal'])} (${actual?['totalVentas'] ?? 0} ventas)   '
        'Cambio: ${cambio >= 0 ? '+' : ''}${cambio.toStringAsFixed(1)}%',
        style: const pw.TextStyle(fontSize: 9),
      ),
    ]);
  }

  /// Canal + tipo de entrega + metodos de pago, en tablas con % y barra.
  static pw.Widget _distribuciones(VentaAnalyticsLoaded data) {
    final porCanal = (data.porCanal['porCanal'] as List<dynamic>? ?? []);
    final porTipo =
        (data.entregas['porTipoEntrega'] as List<dynamic>? ?? []);
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _tablaPct(
        'Ventas por canal',
        porCanal,
        (m) => _labelsCanal[m['canal']] ?? (m['canal'] ?? '') as String,
        cantidadLabel: 'ventas',
      ),
      _tablaPct(
        'Ventas por tipo de entrega',
        porTipo,
        (m) => _labelsTipoEntrega[m['tipo']] ?? (m['tipo'] ?? '') as String,
        cantidadLabel: 'ventas',
      ),
      _tablaPct(
        'Metodos de pago (cobrado)',
        data.metodosPago,
        (m) => _labelsMetodoPago[m['metodo']] ?? (m['metodo'] ?? '') as String,
        cantidadLabel: 'pagos',
      ),
    ]);
  }

  /// Multi-RUC: participacion por RUC emisor. Solo si la empresa tiene
  /// emisores socio (multiEmisor); los Tickets van como fila propia.
  static pw.Widget _porEmisorPdf(Map<String, dynamic> data) {
    if (data['multiEmisor'] != true) return pw.SizedBox();
    final emisores = (data['emisores'] as List<dynamic>? ?? []);
    final sinComp =
        (data['sinComprobante'] as Map<String, dynamic>? ?? const {});
    final items = <Map<String, dynamic>>[
      for (final e in emisores.whereType<Map>())
        {
          'label': '${e['razonSocial'] ?? e['ruc']} - RUC ${e['ruc']}'
              '${e['esPrincipal'] == true ? ' (Principal)' : ' (Socio)'}',
          'monto': e['monto'],
          'cantidad': e['ventas'],
        },
      if (((sinComp['ventas'] ?? 0) as num) > 0)
        {
          'label': 'Ticket (sin comprobante)',
          'monto': sinComp['monto'],
          'cantidad': sinComp['ventas'],
        },
    ];
    return _tablaPct(
      'Ventas por emisor (RUC)',
      items,
      (m) => (m['label'] ?? '') as String,
      cantidadLabel: 'ventas',
    );
  }

  static pw.Widget _porGrupo(String titulo, List<dynamic> items, String key) {
    return _seccionTabla(
      titulo,
      ['#', 'Nombre', 'Und.', 'Ingreso S/', 'Productos'],
      [
        for (final (i, g) in _tomar(items, 5).indexed)
          [
            '${i + 1}',
            _s(g[key]),
            _n(g['cantidadVendida']),
            _n(g['ingresoTotal']),
            '${g['productosDistintos'] ?? ''}',
          ],
      ],
    );
  }

  static pw.Widget _horasPico(Map<String, dynamic> data) {
    final porHora = (data['porHora'] as List<dynamic>? ?? [])
        .map((h) => (h as Map).cast<String, dynamic>())
        .where((h) => ((h['cantidad'] as num?) ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          ((b['cantidad'] as num)).compareTo((a['cantidad'] as num)));
    final porDia = (data['porDiaSemana'] as List<dynamic>? ?? [])
        .map((d) => (d as Map).cast<String, dynamic>())
        .toList();
    if (porHora.isEmpty) return pw.SizedBox();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _seccionTabla(
        'Horas pico (top 5)',
        ['Hora', 'Ventas', 'Monto S/'],
        [
          for (final h in porHora.take(5))
            ['${h['hora']}:00', '${h['cantidad']}', _n(h['monto'])],
        ],
      ),
      _seccionTabla(
        'Por dia de semana',
        ['Dia', 'Ventas', 'Monto S/'],
        [
          for (final d in porDia)
            [
              _dias[((d['dia'] as num?) ?? 1).toInt() - 1],
              '${d['cantidad']}',
              _n(d['monto']),
            ],
        ],
      ),
    ]);
  }

  static pw.Widget _zonas(Map<String, dynamic> entregas) {
    final envio = (entregas['zonasEnvio'] as List<dynamic>? ?? []);
    final delivery = (entregas['zonasDelivery'] as List<dynamic>? ?? []);
    if (envio.isEmpty && delivery.isEmpty) return pw.SizedBox();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (envio.isNotEmpty)
        _seccionTabla(
          'Zonas de envio (agencia)',
          ['Destino', 'Envios', 'Monto S/'],
          [
            for (final z in _tomar(envio, 5))
              [_s(z['zona']), '${z['cantidad']}', _n(z['monto'])],
          ],
        ),
      if (delivery.isNotEmpty)
        _seccionTabla(
          'Zonas de delivery (distrito)',
          ['Distrito', 'Deliveries', 'Monto S/'],
          [
            for (final z in _tomar(delivery, 5))
              [_s(z['zona']), '${z['cantidad']}', _n(z['monto'])],
          ],
        ),
    ]);
  }

  static pw.Widget _reposicion(List<dynamic> reposicion) {
    if (reposicion.isEmpty) return pw.SizedBox();
    return _seccionTabla(
      'Reposicion sugerida (velocidad 30 dias vs stock)',
      ['Nivel', 'Producto', 'Venta/dia', 'Stock', 'Cobertura', 'Comprar'],
      [
        for (final r in reposicion)
          [
            _s(r['nivel']),
            _s(r['nombre']),
            _n(r['ventaDiaria']),
            '${r['stockActual'] ?? 0}',
            '${_n(r['diasCobertura'])} dias',
            '${r['sugeridoComprar'] ?? 0}',
          ],
      ],
    );
  }

  static pw.Widget _alertas(List<dynamic> alertas) {
    if (alertas.isEmpty) return pw.SizedBox();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _titulo('Alertas'),
      for (final a in alertas)
        pw.Bullet(
          text: _s((a as Map)['mensaje']),
          style: const pw.TextStyle(fontSize: 8),
          bulletSize: 1.5,
        ),
    ]);
  }

  // ── Piezas ────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _tomar(List<dynamic> items, int n) => items
      .take(n)
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();

  static pw.Widget _titulo(String texto) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Text(texto.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 9, fontWeight: pw.FontWeight.bold, color: _azul)),
    );
  }

  /// Tabla monto/cantidad/% con mini barra de participacion.
  static pw.Widget _tablaPct(
    String titulo,
    List<dynamic> items,
    String Function(Map<String, dynamic>) labelDe, {
    required String cantidadLabel,
  }) {
    if (items.isEmpty) return pw.SizedBox();
    final maps = _tomar(items, 10);
    final total = maps.fold<double>(
        0, (s, m) => s + (((m['monto'] as num?) ?? 0).toDouble()));
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _titulo(titulo),
      for (final m in maps)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 110,
                child: pw.Text(_s(labelDe(m)),
                    style: const pw.TextStyle(fontSize: 8))),
            pw.SizedBox(
              width: 160,
              child: pw.Stack(children: [
                pw.Container(height: 6, color: PdfColors.grey200),
                pw.Container(
                  height: 6,
                  width: total > 0
                      ? 160 * ((m['monto'] as num?) ?? 0).toDouble() / total
                      : 0,
                  color: _azul,
                ),
              ]),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Text(
                'S/ ${_n(m['monto'])} · ${m['cantidad'] ?? 0} $cantidadLabel · '
                '${total > 0 ? (((m['monto'] as num?) ?? 0).toDouble() / total * 100).toStringAsFixed(1) : '0.0'}%',
                style: const pw.TextStyle(fontSize: 7, color: _gris),
              ),
            ),
          ]),
        ),
    ]);
  }

  static pw.Widget _seccionTabla(
      String titulo, List<String> headers, List<List<String>> filas) {
    if (filas.isEmpty) return pw.SizedBox();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _titulo(titulo),
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: filas,
        headerStyle: pw.TextStyle(
            fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _azul),
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(color: _grisClaro, width: 0.4),
      ),
    ]);
  }
}
