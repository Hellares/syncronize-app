import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_filter_chip.dart';
import '../../../../core/widgets/date/custom_date.dart' hide DateFormatter;
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';

/// Registro de Ventas e Ingresos (base del formato 14.1 del PLE SUNAT):
/// comprobantes fiscales emitidos del mes (01 Factura / 03 Boleta / 07 NC /
/// 08 ND) con bases imponibles, IGV y resumen para el PDT 621. Exportable a
/// Excel para el contador.
class RegistroVentasPage extends StatefulWidget {
  const RegistroVentasPage({super.key});

  @override
  State<RegistroVentasPage> createState() => _RegistroVentasPageState();
}

class _RegistroVentasPageState extends State<RegistroVentasPage> {
  final DioClient _dio = locator<DioClient>();
  static final _money =
      NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);

  int _mes = DateTime.now().month;
  int _anio = DateTime.now().year;
  String? _sedeId;

  /// Rango personalizado (manda sobre mes/año cuando está seteado).
  DateTime? _rangoDesde;
  DateTime? _rangoHasta;
  bool get _usandoRango => _rangoDesde != null && _rangoHasta != null;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  // Scroll horizontal sincronizado entre la cabecera sticky y el cuerpo de
  // filas (mismo patrón que la tabla de Inventario por Sede).
  final ScrollController _headerHCtrl = ScrollController();
  final ScrollController _bodyHCtrl = ScrollController();
  bool _syncingScroll = false;

  final List<String> _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  void initState() {
    super.initState();
    _headerHCtrl.addListener(() => _syncH(_headerHCtrl, _bodyHCtrl));
    _bodyHCtrl.addListener(() => _syncH(_bodyHCtrl, _headerHCtrl));
    _cargar();
  }

  void _syncH(ScrollController src, ScrollController dst) {
    if (_syncingScroll) return;
    if (!dst.hasClients) return;
    if (src.offset == dst.offset) return;
    _syncingScroll = true;
    dst.jumpTo(src.offset);
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _headerHCtrl.dispose();
    _bodyHCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(
        '/reportes-financieros/registro-ventas',
        queryParameters: {
          'mes': _mes,
          'anio': _anio,
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_usandoRango) ...{
            'fechaInicio': DateFormat('yyyy-MM-dd').format(_rangoDesde!),
            'fechaFin': DateFormat('yyyy-MM-dd').format(_rangoHasta!),
          },
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
    final rango = _usandoRango
        ? '${DateFormat('yyyyMMdd').format(_rangoDesde!)}_${DateFormat('yyyyMMdd').format(_rangoHasta!)}'
        : '${_anio}_$_mes';
    await locator<ExportService>().exportAndShare(
      context: context,
      endpoint: '/reportes-financieros/export/registro-ventas',
      queryParams: {
        'mes': _mes,
        'anio': _anio,
        if (_sedeId != null) 'sedeId': _sedeId,
        if (_usandoRango) ...{
          'fechaInicio': DateFormat('yyyy-MM-dd').format(_rangoDesde!),
          'fechaFin': DateFormat('yyyy-MM-dd').format(_rangoHasta!),
        },
      },
      fileName: 'registro_ventas_$rango.xlsx',
    );
  }

  void _seleccionarSede(String? sedeId) {
    if (_sedeId == sedeId) return;
    setState(() => _sedeId = sedeId);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Registro de Ventas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          actions: [
            if (_data != null)
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar a Excel',
                onPressed: _exportar,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
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

  Widget _buildContent() {
    if (_data == null) return const SizedBox.shrink();
    final resumen = _data!['resumen'] as Map<String, dynamic>;
    final comprobantes =
        (_data!['comprobantes'] as List).cast<Map<String, dynamic>>();

    // Filtros + resumen fijos arriba; la tabla ocupa el resto con su propio
    // scroll vertical y cabecera sticky (patrón de Inventario por Sede).
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              _buildSedeSelector(),
              _buildPeriodoSelector(),
              const SizedBox(height: 10),
              _buildResumen(resumen),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: comprobantes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 50, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('Sin comprobantes emitidos en el periodo',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : _buildTabla(comprobantes),
        ),
      ],
    );
  }

  // ── Selectores (mismos controles que Libro Contable) ────────────────────

  Widget _buildSedeSelector() {
    final sedes = context.watch<SedeActivaCubit>().state.operables;
    if (sedes.length < 2) return const SizedBox.shrink();

    final expandir = sedes.length + 1 <= 3;
    final items = [
      _tabSedeItem(
        label: 'Toda la empresa',
        icon: Icons.business,
        selected: _sedeId == null,
        expanded: expandir,
        onTap: () => _seleccionarSede(null),
      ),
      ...sedes.map((s) => _tabSedeItem(
            label: s.nombre,
            icon: Icons.store,
            selected: _sedeId == s.id,
            expanded: expandir,
            onTap: () => _seleccionarSede(s.id),
          )),
    ];

    final control = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );

    if (expandir) return control;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal, child: control);
  }

  Widget _tabSedeItem({
    required String label,
    required IconData icon,
    required bool selected,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    final item = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            EdgeInsets.symmetric(vertical: 7, horizontal: expanded ? 0 : 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? AppColors.blue1 : Colors.grey.shade500),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.blue1 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? Expanded(child: item) : item;
  }

  Widget _buildPeriodoSelector() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final mes = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CustomFilterChip(
                    label: _meses[index],
                    // Con rango personalizado activo ningún mes se marca.
                    selected: !_usandoRango && mes == _mes,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    onSelected: () {
                      setState(() {
                        _mes = mes;
                        _rangoDesde = null;
                        _rangoHasta = null;
                      });
                      _cargar();
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: CustomDropdown<int>(
            value: _anio,
            borderColor: AppColors.blue1,
            items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                .map((y) => DropdownItem(value: y, label: '$y'))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _anio = val;
                  _rangoDesde = null;
                  _rangoHasta = null;
                });
                _cargar();
              }
            },
          ),
        ),
        const SizedBox(width: 6),
        // Rango personalizado (manda sobre mes/año). Limpiar el rango desde
        // el picker vuelve al mes seleccionado.
        SizedBox(
          width: 130,
          child: CustomDate(
            key: ValueKey(
                _usandoRango ? '${_rangoDesde}_$_rangoHasta' : 'sin-rango'),
            dateType: DateFieldType.dateRange,
            initialDateRange: _usandoRango
                ? DateRange(startDate: _rangoDesde, endDate: _rangoHasta)
                : null,
            borderColor: AppColors.blue1,
            hintText: 'Rango',
            showDaysSelectedLabel: false,
            onDateRangeSelected: (range) {
              setState(() {
                if (range?.startDate != null && range?.endDate != null) {
                  _rangoDesde = range!.startDate;
                  _rangoHasta = range.endDate;
                } else {
                  _rangoDesde = null;
                  _rangoHasta = null;
                }
              });
              _cargar();
            },
          ),
        ),
      ],
    );
  }

  // ── Resumen (lo que el contador vuelca al PDT 621) ──────────────────────

  Widget _buildResumen(Map<String, dynamic> r) {
    double d(String k) => (r[k] as num?)?.toDouble() ?? 0;
    final porTipo = (r['porTipo'] as List? ?? []).cast<Map<String, dynamic>>();
    final anulados = r['cantidadAnulados'] as int? ?? 0;

    Widget stat(String label, String valor, Color color, {IconData? icon}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(valor,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            stat('Base gravada (neta)', _money.format(d('gravada')),
                AppColors.blue1, icon: Icons.receipt_long),
            const SizedBox(width: 8),
            stat('IGV (neto)', _money.format(d('igv')), Colors.indigo,
                icon: Icons.account_balance),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            stat('Total neto del periodo', _money.format(d('totalNeto')),
                Colors.green.shade700, icon: Icons.payments_outlined),
            const SizedBox(width: 8),
            stat(
                'NC emitidas',
                '- ${_money.format(d('totalNotasCredito'))}',
                Colors.red.shade700,
                icon: Icons.assignment_return_outlined),
          ],
        ),
        const SizedBox(height: 8),
        // Chips por tipo de comprobante + anulados.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...porTipo.map((t) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.blue1.withValues(alpha: 0.25),
                          width: 0.5),
                    ),
                    child: Text(
                      '${t['codigoSunat']} ${_labelTipo(t['tipo'] as String)}: ${t['cantidad']} · ${_money.format((t['total'] as num).toDouble())}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue1),
                    ),
                  )),
              if (anulados > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200, width: 0.5),
                  ),
                  child: Text(
                    '$anulados anulado${anulados != 1 ? 's' : ''} (no suman)',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Nombre corto para la columna Tipo de la tabla.
  String _tipoCorto(String? tipo) {
    switch (tipo) {
      case 'FACTURA':
        return 'Factura';
      case 'BOLETA':
        return 'Boleta';
      case 'NOTA_CREDITO':
        return 'NC';
      case 'NOTA_DEBITO':
        return 'ND';
      default:
        return tipo ?? '—';
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'FACTURA':
        return 'Facturas';
      case 'BOLETA':
        return 'Boletas';
      case 'NOTA_CREDITO':
        return 'NC';
      case 'NOTA_DEBITO':
        return 'ND';
      default:
        return tipo;
    }
  }

  // ─── Tabla estilo Excel (patrón Inventario por Sede: anchos fijos, header
  // sticky con scroll horizontal sincronizado y franjas de color) ──────────

  static const double _wFecha = 73;
  static const double _wTipo = 78;
  static const double _wSerie = 48;
  static const double _wNumero = 90;
  static const double _wEstado = 82;
  static const double _wCliente = 280;
  static const double _wDoc = 110;
  static const double _wGravada = 70;
  static const double _wIgv = 60;
  static const double _wTotal = 88;
  static const double _rowH = 34;
  static const double _headerH = 28;

  static final Color _bgGravadaH = Colors.blue.shade100;
  static final Color _bgGravada = Colors.blue.shade50;
  static final Color _bgIgvH = Colors.orange.shade100;
  static final Color _bgIgv = Colors.orange.shade50;
  static final Color _bgTotalH = Colors.teal.shade100;
  static final Color _bgTotal = Colors.teal.shade50;

  double get _totalWidth =>
      _wFecha +
      _wTipo +
      _wSerie +
      _wNumero +
      _wEstado +
      _wCliente +
      _wDoc +
      _wGravada +
      _wIgv +
      _wTotal;

  Widget _buildTabla(List<Map<String, dynamic>> comprobantes) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${comprobantes.length} comprobante(s)',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // HEADER STICKY: solo scroll horizontal, espejado con el body.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerHCtrl,
            physics: const ClampingScrollPhysics(),
            child: _buildHeaderRow(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: AppColors.blue1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _bodyHCtrl,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: _totalWidth,
                  child: ListView.builder(
                    itemCount: comprobantes.length,
                    itemExtent: _rowH,
                    itemBuilder: (_, i) => _buildItemRow(comprobantes[i], i),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final s = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.blue1,
    );
    return Container(
      width: _totalWidth,
      height: _headerH,
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(
        children: [
          _hCell('Fecha', _wFecha, s),
          _hCell('Tipo', _wTipo, s),
          _hCell('Serie', _wSerie, s),
          _hCell('Número', _wNumero, s),
          _hCell('Estado', _wEstado, s),
          _hCell('Cliente', _wCliente, s),
          _hCell('RUC/DNI', _wDoc, s),
          _hCell('Gravada', _wGravada, s, alignRight: true, bgColor: _bgGravadaH),
          _hCell('IGV', _wIgv, s, alignRight: true, bgColor: _bgIgvH),
          _hCell('Total', _wTotal, s, alignRight: true, bgColor: _bgTotalH),
        ],
      ),
    );
  }

  Widget _hCell(String text, double width, TextStyle s,
      {bool alignRight = false, Color? bgColor}) {
    return Container(
      width: width,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(text, style: s),
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> c, int i) {
    final anulado = c['anulado'] == true;
    final esNC = c['tipoComprobante'] == 'NOTA_CREDITO';
    final fecha = c['fechaEmision'] != null
        ? DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(c['fechaEmision'].toString()).toLocal())
        : '—';
    final sunat = anulado ? 'ANULADO' : (c['sunatStatus']?.toString() ?? '');
    final refNota = c['referencia'] != null ? ' → ${c['referencia']}' : '';
    // El backend manda "SERIE-CORRELATIVO" (la serie SUNAT nunca lleva guión).
    final numero = c['numero']?.toString() ?? '';
    final guion = numero.indexOf('-');
    final serie = guion > 0 ? numero.substring(0, guion) : numero;
    final correlativo = guion > 0 ? numero.substring(guion + 1) : '—';
    final doc = [c['tipoDocCliente'], c['numeroDocumento']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' ');

    final tdBase = TextStyle(
      fontSize: 9,
      color: anulado ? Colors.grey.shade400 : Colors.grey.shade700,
      decoration: anulado ? TextDecoration.lineThrough : null,
    );
    final tdBold = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: anulado ? Colors.grey.shade400 : Colors.grey.shade900,
      decoration: anulado ? TextDecoration.lineThrough : null,
    );
    final estadoStyle = TextStyle(
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      color: anulado
          ? Colors.red.shade400
          : sunat == 'ACEPTADO'
              ? Colors.green.shade700
              : sunat == 'RECHAZADO'
                  ? Colors.red.shade700
                  : Colors.orange.shade800,
    );

    return Container(
      width: _totalWidth,
      decoration: BoxDecoration(
        color: i.isOdd ? Colors.grey.withValues(alpha: 0.04) : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _dCell(Text(fecha, style: tdBase), _wFecha),
          _dCell(
            Text('${c['codigoSunat']} ${_tipoCorto(c['tipoComprobante'] as String?)}',
                style: tdBase, maxLines: 1, overflow: TextOverflow.ellipsis),
            _wTipo,
          ),
          _dCell(
            Text(serie, style: tdBold, maxLines: 1,
                overflow: TextOverflow.ellipsis),
            _wSerie,
          ),
          _dCell(
            refNota.isEmpty
                ? Text(correlativo,
                    style: tdBold, maxLines: 1, overflow: TextOverflow.ellipsis)
                : _dual(correlativo, refNota.trim(), tdBold,
                    TextStyle(fontSize: 7.5, color: Colors.grey.shade500)),
            _wNumero,
          ),
          _dCell(
            Text(sunat,
                style: estadoStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            _wEstado,
          ),
          _dCell(
            Text(c['nombreCliente']?.toString() ?? '—',
                style: tdBase, maxLines: 2, overflow: TextOverflow.ellipsis),
            _wCliente,
          ),
          _dCell(
            Text(doc.isEmpty ? '—' : doc,
                style: tdBase, maxLines: 1, overflow: TextOverflow.ellipsis),
            _wDoc,
          ),
          _dCell(
            Text((c['gravada'] as num).toStringAsFixed(2),
                style: tdBase, textAlign: TextAlign.right),
            _wGravada,
            alignRight: true,
            bgColor: anulado ? null : _bgGravada,
          ),
          _dCell(
            Text((c['igv'] as num).toStringAsFixed(2),
                style: tdBase, textAlign: TextAlign.right),
            _wIgv,
            alignRight: true,
            bgColor: anulado ? null : _bgIgv,
          ),
          _dCell(
            Text(
              '${esNC && !anulado ? '-' : ''}${(c['total'] as num).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: anulado
                  ? tdBase
                  : TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: esNC
                          ? Colors.red.shade700
                          : Colors.grey.shade900),
            ),
            _wTotal,
            alignRight: true,
            bgColor: anulado ? null : _bgTotal,
          ),
        ],
      ),
    );
  }

  Widget _dCell(Widget child, double width,
      {bool alignRight = false, Color? bgColor}) {
    return Container(
      width: width,
      height: _rowH,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    );
  }

  Widget _dual(String top, String bottom, TextStyle topStyle,
      TextStyle bottomStyle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(top,
            style: topStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(bottom,
            style: bottomStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
