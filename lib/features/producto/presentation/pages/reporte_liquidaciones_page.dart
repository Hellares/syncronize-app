import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_stock.dart' show MotivoLiquidacion, MotivoLiquidacionX;

/// Reporte de liquidaciones y pérdidas comerciales.
/// Llama `GET /reportes-financieros/liquidaciones` y muestra resumen,
/// desglose por motivo y por producto. Permite exportar a Excel.
class ReporteLiquidacionesPage extends StatefulWidget {
  const ReporteLiquidacionesPage({super.key});

  @override
  State<ReporteLiquidacionesPage> createState() =>
      _ReporteLiquidacionesPageState();
}

class _ReporteLiquidacionesPageState extends State<ReporteLiquidacionesPage> {
  final DioClient _dio = locator<DioClient>();
  static final _money = NumberFormat.currency(
      locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);

  List<Sede> _sedes = [];
  String? _sedeId;
  MotivoLiquidacion? _motivo;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  bool _loading = false;
  bool _exporting = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
    }
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(
        '/reportes-financieros/liquidaciones',
        queryParameters: {
          'fechaInicio': DateFormat('yyyy-MM-dd').format(_fechaInicio),
          'fechaFin': DateFormat('yyyy-MM-dd').format(_fechaFin),
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_motivo != null) 'motivo': _motivo!.apiValue,
        },
      );
      if (mounted) {
        setState(() {
          _data = response.data as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is DioException
              ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
              : e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportar() async {
    setState(() => _exporting = true);
    try {
      final response = await _dio.get(
        '/reportes-financieros/export/liquidaciones',
        queryParameters: {
          'fechaInicio': DateFormat('yyyy-MM-dd').format(_fechaInicio),
          'fechaFin': DateFormat('yyyy-MM-dd').format(_fechaFin),
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_motivo != null) 'motivo': _motivo!.apiValue,
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      final bytes = response.data as List<int>;
      final fileName =
          'liquidaciones_${DateFormat('yyyyMMdd').format(_fechaInicio)}_${DateFormat('yyyyMMdd').format(_fechaFin)}.xlsx';
      String filePath;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          filePath = '${downloadDir.path}/$fileName';
        } else {
          final extDir = await getExternalStorageDirectory();
          filePath =
              '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/$fileName';
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      }
      await File(filePath).writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportado: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Liquidaciones y pérdidas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          actions: [
            if (_data != null)
              IconButton(
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                onPressed: _exporting ? null : _exportar,
                tooltip: 'Exportar a Excel',
              ),
          ],
        ),
        body: Column(
          children: [
            _buildFiltros(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  /// Sentinela para "Todas/Todos" en los dropdowns (DropdownItem no acepta
  /// value null como opción distinguible de "sin selección").
  static const String _todos = '__TODOS__';

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          CustomDate(
            key: ValueKey('${_fechaInicio}_$_fechaFin'),
            dateType: DateFieldType.dateRange,
            initialDateRange:
                DateRange(startDate: _fechaInicio, endDate: _fechaFin),
            borderColor: AppColors.blue1,
            hintText: 'Rango de fechas',
            height: 33,
            showDaysSelectedLabel: false,
            onDateRangeSelected: (range) {
              if (range?.startDate == null || range?.endDate == null) return;
              setState(() {
                _fechaInicio = range!.startDate!;
                _fechaFin = range.endDate!;
              });
              _cargar();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_sedes.length > 1) ...[
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Sede',
                    value: _sedeId ?? _todos,
                    borderColor: AppColors.blue1,
                    items: [
                      const DropdownItem(value: _todos, label: 'Todas'),
                      ..._sedes.map(
                          (s) => DropdownItem(value: s.id, label: s.nombre)),
                    ],
                    onChanged: (v) {
                      setState(() => _sedeId = v == _todos ? null : v);
                      _cargar();
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: CustomDropdown<String>(
                  label: 'Motivo',
                  value: _motivo?.apiValue ?? _todos,
                  borderColor: AppColors.blue1,
                  items: [
                    const DropdownItem(value: _todos, label: 'Todos'),
                    ...MotivoLiquidacion.values.map(
                        (m) => DropdownItem(value: m.apiValue, label: m.label)),
                  ],
                  onChanged: (v) {
                    setState(() => _motivo = v == null || v == _todos
                        ? null
                        : MotivoLiquidacionX.fromApi(v));
                    _cargar();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_data == null) return const SizedBox.shrink();
    final resumen = _data!['resumen'] as Map<String, dynamic>;
    final porMotivo = (_data!['porMotivo'] as List).cast<Map<String, dynamic>>();
    final porProducto = (_data!['porProducto'] as List).cast<Map<String, dynamic>>();
    final detalle =
        ((_data!['detalle'] as List?) ?? []).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildResumenCards(resumen),
          const SizedBox(height: 16),
          if (porMotivo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 50, color: Colors.deepOrange.shade300),
                    const SizedBox(height: 8),
                    const Text('Sin ventas bajo costo en el periodo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else ...[
            _sectionTitle('Por motivo'),
            _panelPorMotivo(porMotivo),
            const SizedBox(height: 16),
            _sectionTitle('Por producto'),
            _tablaPorProducto(porProducto.take(50).toList()),
            if (porProducto.length > 50)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mostrando 50 de ${porProducto.length}. Exportá a Excel para ver todos.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            if (detalle.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Detalle de ventas'),
              _tablaDetalle(detalle.take(100).toList()),
              if (detalle.length > 100)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Mostrando 100 de ${detalle.length} líneas. Exportá a Excel para ver todas.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResumenCards(Map<String, dynamic> r) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _ResumenCard(
              titulo: 'Líneas bajo costo',
              valor: '${r['cantidadLineas']}',
              color: AppColors.blue1,
              icon: Icons.list_alt,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _ResumenCard(
              titulo: 'Ventas afectadas',
              valor: '${r['cantidadVentas']}',
              color: Colors.indigo,
              icon: Icons.receipt_long,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _ResumenCard(
              titulo: 'Ingreso recuperado',
              valor: _money.format((r['ingresoTotal'] as num).toDouble()),
              color: Colors.green.shade700,
              icon: Icons.trending_up,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _ResumenCard(
              titulo: 'Pérdida total',
              valor: _money.format((r['perdidaTotal'] as num).toDouble()),
              color: Colors.red.shade700,
              icon: Icons.trending_down,
            )),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  String _labelMotivo(String motivoKey) =>
      MotivoLiquidacionX.fromApi(motivoKey)?.label ??
      (motivoKey == 'SIN_LIQUIDACION_AUTORIZADA'
          ? 'Autorización gerencial'
          : motivoKey);

  IconData _iconoMotivo(String motivoKey) {
    switch (motivoKey) {
      case 'FUERA_DE_CAMPANA':
        return Icons.event_busy;
      case 'SIN_ROTACION':
        return Icons.trending_down;
      case 'PROXIMO_A_VENCER':
        return Icons.schedule;
      case 'DESCONTINUADO':
        return Icons.do_disturb_alt;
      case 'SIN_LIQUIDACION_AUTORIZADA':
        return Icons.verified_user_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  /// Panel analítico por motivo: ordenado por pérdida, con barra del % de la
  /// pérdida total y el % de RECUPERACIÓN de costo (ingreso ÷ costo) — la
  /// métrica de decisión: liquidar recuperando 80% del costo es gestión
  /// sana; recuperar 30% es quemar plata.
  Widget _panelPorMotivo(List<Map<String, dynamic>> motivos) {
    final items = [...motivos]..sort((a, b) =>
        (b['perdida'] as num).toDouble().compareTo((a['perdida'] as num).toDouble()));
    final totalPerdida =
        items.fold<double>(0, (s, m) => s + (m['perdida'] as num).toDouble());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
            _motivoTile(items[i], totalPerdida),
          ],
        ],
      ),
    );
  }

  Widget _motivoTile(Map<String, dynamic> m, double totalPerdida) {
    final motivoKey = m['motivo'] as String;
    final perdida = (m['perdida'] as num).toDouble();
    final ingreso = (m['ingreso'] as num).toDouble();
    final costo = (m['costo'] as num).toDouble();
    final share = totalPerdida > 0 ? perdida / totalPerdida : 0.0;
    // Cuánto del costo se rescató vendiendo barato.
    final recuperacion = costo > 0 ? (ingreso / costo * 100) : 0.0;
    final colorRecup = recuperacion >= 70
        ? Colors.green.shade700
        : recuperacion >= 40
            ? Colors.orange.shade800
            : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconoMotivo(motivoKey),
                size: 16, color: Colors.red.shade400),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _labelMotivo(motivoKey),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _money.format(perdida),
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Barra: proporción de la pérdida total que aporta el motivo.
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${m['cantidadLineas']} línea${m['cantidadLineas'] != 1 ? 's' : ''} · ${(share * 100).toStringAsFixed(0)}% de la pérdida',
                      style:
                          TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    Text(
                      'recuperó ${recuperacion.toStringAsFixed(0)}% del costo',
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: colorRecup),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tablas estilo Excel (mismo patrón que historial de compras) ─────────

  static final _headerStyle = TextStyle(
      fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700);
  static final _cellStyle =
      TextStyle(fontSize: 9.5, color: Colors.grey.shade700);
  static final _cellBold = TextStyle(
      fontSize: 9.5, color: Colors.grey.shade900, fontWeight: FontWeight.w700);
  static final _cellTiny = TextStyle(fontSize: 8, color: Colors.grey.shade500);
  static final _cellRojo = TextStyle(
      fontSize: 9.5, color: Colors.red.shade700, fontWeight: FontWeight.w700);

  Widget _celda(String text, TextStyle style,
      {TextAlign align = TextAlign.left, int? maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Text(
        text,
        style: style,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      ),
    );
  }

  Widget _celdaDual(String top, String bottom, TextStyle topStyle,
      {TextAlign align = TextAlign.left}) {
    final cross = align == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Padding(
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
              style: _cellTiny,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  BoxDecoration _zebra(int i) => BoxDecoration(
      color: i.isOdd ? Colors.grey.withValues(alpha: 0.04) : Colors.white);

  BoxDecoration get _headerDeco =>
      BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07));

  String _fmtMonto(num? v) => _money.format((v ?? 0).toDouble());

  /// Agregado por producto: cantidad, precio de venta y costo PROMEDIO por
  /// unidad (derivados de ingreso/costo ÷ cantidad) y pérdida total.
  Widget _tablaPorProducto(List<Map<String, dynamic>> productos) {
    final rows = <TableRow>[
      TableRow(
        decoration: _headerDeco,
        children: [
          _celda('Producto', _headerStyle),
          _celda('Cant.', _headerStyle, align: TextAlign.right),
          _celda('P.Venta/u', _headerStyle, align: TextAlign.right),
          _celda('Costo/u', _headerStyle, align: TextAlign.right),
          _celda('Pérdida', _headerStyle, align: TextAlign.right),
        ],
      ),
    ];

    double totCant = 0, totIngreso = 0, totCosto = 0, totPerdida = 0;
    for (var i = 0; i < productos.length; i++) {
      final p = productos[i];
      final cant = (p['cantidadVendida'] as num).toDouble();
      final ingreso = (p['ingreso'] as num).toDouble();
      final costo = (p['costo'] as num).toDouble();
      final perdida = (p['perdida'] as num).toDouble();
      totCant += cant;
      totIngreso += ingreso;
      totCosto += costo;
      totPerdida += perdida;
      // Promedios por unidad: el agregado puede mezclar ventas a precios
      // distintos — el precio exacto de cada venta está en el Detalle.
      final pvProm = cant > 0 ? ingreso / cant : 0;
      final costoProm = cant > 0 ? costo / cant : 0;
      rows.add(TableRow(
        decoration: _zebra(i),
        children: [
          _celda(p['descripcion'] as String? ?? '—', _cellStyle, maxLines: 2),
          _celda(cant.toStringAsFixed(0), _cellStyle, align: TextAlign.right),
          _celda('S/ ${pvProm.toStringAsFixed(2)}', _cellStyle,
              align: TextAlign.right),
          _celda('S/ ${costoProm.toStringAsFixed(2)}', _cellStyle,
              align: TextAlign.right),
          _celda(_fmtMonto(perdida), _cellRojo, align: TextAlign.right),
        ],
      ));
    }

    // Fila de totales (los promedios de la fila total son ponderados).
    rows.add(TableRow(
      decoration:
          BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.05)),
      children: [
        _celda('TOTAL', _cellBold),
        _celda(totCant.toStringAsFixed(0), _cellBold, align: TextAlign.right),
        _celda('S/ ${(totCant > 0 ? totIngreso / totCant : 0).toStringAsFixed(2)}',
            _cellBold, align: TextAlign.right),
        _celda('S/ ${(totCant > 0 ? totCosto / totCant : 0).toStringAsFixed(2)}',
            _cellBold, align: TextAlign.right),
        _celda(_fmtMonto(totPerdida), _cellRojo, align: TextAlign.right),
      ],
    ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: Colors.white,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
          columnWidths: const {
            0: FlexColumnWidth(2.1),
            1: FlexColumnWidth(0.65),
            2: FlexColumnWidth(1.0),
            3: FlexColumnWidth(0.95),
            4: FlexColumnWidth(1.05),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
  }

  /// Detalle línea por línea con el precio REAL al que se vendió cada vez:
  /// fecha + venta, producto (con motivo/autorizador), cantidad, precio de
  /// venta unitario, costo snapshot y pérdida de la línea.
  Widget _tablaDetalle(List<Map<String, dynamic>> detalle) {
    final fmtFecha = DateFormat('dd/MM/yy');
    final rows = <TableRow>[
      TableRow(
        decoration: _headerDeco,
        children: [
          _celda('Venta', _headerStyle),
          _celda('Producto', _headerStyle),
          _celda('Cant.', _headerStyle, align: TextAlign.right),
          _celda('P.Venta', _headerStyle, align: TextAlign.right),
          _celda('Costo/u', _headerStyle, align: TextAlign.right),
          _celda('Pérdida', _headerStyle, align: TextAlign.right),
        ],
      ),
    ];

    for (var i = 0; i < detalle.length; i++) {
      final d = detalle[i];
      final cant = (d['cantidad'] as num).toDouble();
      final precio = (d['precioUnitario'] as num).toDouble();
      final costo = (d['precioCostoSnapshot'] as num).toDouble();
      final margenU = (d['margenSnapshot'] as num).toDouble(); // negativo
      final perdidaLinea = margenU * cant;
      final fecha = d['fechaVenta'] != null
          ? fmtFecha.format(DateTime.parse(d['fechaVenta'].toString()).toLocal())
          : '—';
      final motivoKey = d['motivo'] as String?;
      final motivo = motivoKey == null
          ? (d['autorizadoPorNombre'] != null
              ? 'Aut: ${d['autorizadoPorNombre']}'
              : 'Autorización')
          : (MotivoLiquidacionX.fromApi(motivoKey)?.label ?? motivoKey);

      rows.add(TableRow(
        decoration: _zebra(i),
        children: [
          _celdaDual(d['ventaCodigo'] as String? ?? '—', fecha, _cellStyle),
          _celdaDual(d['descripcion'] as String? ?? '—', motivo, _cellStyle),
          _celda(cant.toStringAsFixed(0), _cellStyle, align: TextAlign.right),
          _celda('S/ ${precio.toStringAsFixed(2)}', _cellBold,
              align: TextAlign.right),
          _celda('S/ ${costo.toStringAsFixed(2)}', _cellStyle,
              align: TextAlign.right),
          _celdaDual(_fmtMonto(perdidaLinea), '${margenU.toStringAsFixed(2)}/u',
              _cellRojo, align: TextAlign.right),
        ],
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: Colors.white,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
          columnWidths: const {
            0: FlexColumnWidth(1.0),
            1: FlexColumnWidth(1.9),
            2: FlexColumnWidth(0.6),
            3: FlexColumnWidth(0.95),
            4: FlexColumnWidth(0.9),
            5: FlexColumnWidth(1.05),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icon;
  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

