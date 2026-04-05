import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart' as df;
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/venta_analytics/venta_analytics_cubit.dart';
import '../bloc/venta_analytics/venta_analytics_state.dart';

class VentaAnalyticsPage extends StatefulWidget {
  const VentaAnalyticsPage({super.key});

  @override
  State<VentaAnalyticsPage> createState() => _VentaAnalyticsPageState();
}

class _VentaAnalyticsPageState extends State<VentaAnalyticsPage> {
  String _modoFiltro = 'rapido';
  String _periodoRapido = 'MES';
  DateRange _dateRange = DateRange();
  String? _sedeId;
  // Mes y año seleccionados para filtro principal
  late int _mesSeleccionado;
  late int _anioSeleccionado;
  // Comparativo: mes/año para cada periodo
  late int _compMesActual;
  late int _compAnioActual;
  late int _compMesAnterior;
  late int _compAnioAnterior;
  bool _compFiltroExpandido = false;

  static const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSeleccionado = now.month;
    _anioSeleccionado = now.year;
    // Comparativo default: mes actual vs anterior
    _compMesActual = now.month;
    _compAnioActual = now.year;
    _compMesAnterior = now.month == 1 ? 12 : now.month - 1;
    _compAnioAnterior = now.month == 1 ? now.year - 1 : now.year;
    _load();
  }

  Map<String, String?> _getFechasFromPeriodo() {
    final now = DateTime.now();
    switch (_periodoRapido) {
      case 'HOY':
        final hoy = df.DateFormatter.formatForApi(now);
        return {'fechaInicio': hoy, 'fechaFin': hoy, 'periodo': 'DIARIO'};
      case 'SEMANA':
        final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
        return {
          'fechaInicio': df.DateFormatter.formatForApi(inicioSemana),
          'fechaFin': df.DateFormatter.formatForApi(now),
          'periodo': 'DIARIO',
        };
      case 'MES':
        final inicioMes = DateTime(_anioSeleccionado, _mesSeleccionado, 1);
        final finMes = DateTime(_anioSeleccionado, _mesSeleccionado + 1, 0);
        // Si es el mes actual, usar hoy como fin
        final fechaFin = (_anioSeleccionado == now.year && _mesSeleccionado == now.month) ? now : finMes;
        return {
          'fechaInicio': df.DateFormatter.formatForApi(inicioMes),
          'fechaFin': df.DateFormatter.formatForApi(fechaFin),
          'periodo': 'DIARIO',
        };
      case 'ANUAL':
        final inicioAnio = DateTime(_anioSeleccionado, 1, 1);
        final finAnio = _anioSeleccionado == now.year ? now : DateTime(_anioSeleccionado, 12, 31);
        return {
          'fechaInicio': df.DateFormatter.formatForApi(inicioAnio),
          'fechaFin': df.DateFormatter.formatForApi(finAnio),
          'periodo': 'MENSUAL',
        };
      default:
        return {'fechaInicio': null, 'fechaFin': null, 'periodo': 'DIARIO'};
    }
  }

  void _load() {
    String? fechaInicio;
    String? fechaFin;
    String periodo = 'DIARIO';

    if (_modoFiltro == 'rapido') {
      final fechas = _getFechasFromPeriodo();
      fechaInicio = fechas['fechaInicio'];
      fechaFin = fechas['fechaFin'];
      periodo = fechas['periodo'] ?? 'DIARIO';
    } else {
      fechaInicio = _dateRange.startDate != null ? df.DateFormatter.formatForApi(_dateRange.startDate!) : null;
      fechaFin = _dateRange.endDate != null ? df.DateFormatter.formatForApi(_dateRange.endDate!) : null;
      // Auto-detectar periodo según rango
      if (_dateRange.isComplete) {
        final dias = _dateRange.daysDifference ?? 0;
        if (dias <= 7) {
          periodo = 'DIARIO';
        } else if (dias <= 60) {
          periodo = 'SEMANAL';
        } else if (dias <= 365) {
          periodo = 'MENSUAL';
        } else {
          periodo = 'ANUAL';
        }
      }
    }

    // Comparativo: enviar ambos periodos explícitamente
    final now = DateTime.now();

    // Periodo A (anterior/izquierda)
    final compAInicio = DateTime(_compAnioAnterior, _compMesAnterior, 1);
    final compAFin = (_compAnioAnterior == now.year && _compMesAnterior == now.month)
        ? now
        : DateTime(_compAnioAnterior, _compMesAnterior + 1, 0);

    // Periodo B (actual/derecha)
    final compBInicio = DateTime(_compAnioActual, _compMesActual, 1);
    final compBFin = (_compAnioActual == now.year && _compMesActual == now.month)
        ? now
        : DateTime(_compAnioActual, _compMesActual + 1, 0);

    context.read<VentaAnalyticsCubit>().load(
      sedeId: _sedeId,
      periodo: periodo,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      compAInicio: df.DateFormatter.formatForApi(compAInicio),
      compAFin: df.DateFormatter.formatForApi(compAFin),
      compBInicio: df.DateFormatter.formatForApi(compBInicio),
      compBFin: df.DateFormatter.formatForApi(compBFin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Reportes de Ventas',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: BlocBuilder<VentaAnalyticsCubit, VentaAnalyticsState>(
        builder: (context, state) {
          if (state is VentaAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VentaAnalyticsError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
              ],
            ));
          }
          if (state is VentaAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  _buildResumenCards(state.resumen),
                  const SizedBox(height: 16),
                  _buildComparativo(state.comparativo),
                  const SizedBox(height: 16),
                  _buildTopProductos(state.topProductos),
                  const SizedBox(height: 16),
                  _buildTopClientes(state.topClientes),
                  const SizedBox(height: 16),
                  _buildVentasPeriodo(state.ventasPeriodo),
                  if (state.alertas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAlertas(state.alertas),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFiltros() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes.where((s) => s.isActive).toList()
        : [];

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs: Periodo Rápido | Rango Personalizado
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _modoFiltro = 'rapido'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _modoFiltro == 'rapido' ? AppColors.blue1 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _modoFiltro == 'rapido' ? AppColors.blue1 : Colors.grey.shade300),
                      ),
                      child: Text(
                        'Periodo Rápido',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _modoFiltro == 'rapido' ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _modoFiltro = 'rango'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _modoFiltro == 'rango' ? AppColors.blue1 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _modoFiltro == 'rango' ? AppColors.blue1 : Colors.grey.shade300),
                      ),
                      child: Text(
                        'Rango Personalizado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _modoFiltro == 'rango' ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Contenido según modo
            if (_modoFiltro == 'rapido') ...[
              // Chips de periodo rápido
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPeriodoChip('HOY', 'Hoy', Icons.today),
                  _buildPeriodoChip('SEMANA', 'Esta Semana', Icons.date_range),
                  _buildPeriodoChip('MES', 'Mes', Icons.calendar_month),
                  _buildPeriodoChip('ANUAL', 'Año', Icons.calendar_today),
                ],
              ),
              // Selector de mes cuando periodo = MES
              if (_periodoRapido == 'MES') ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 12,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, i) {
                      final mes = i + 1;
                      final selected = mes == _mesSeleccionado;
                      final now = DateTime.now();
                      final esFuturo = _anioSeleccionado == now.year && mes > now.month;
                      return GestureDetector(
                        onTap: esFuturo ? null : () => setState(() => _mesSeleccionado = mes),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.blue1 : (esFuturo ? Colors.grey.shade100 : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300),
                          ),
                          child: Text(
                            _meses[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : (esFuturo ? Colors.grey.shade400 : Colors.grey.shade700),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Selector de año para el mes
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _anioSeleccionado > 2020 ? () => setState(() => _anioSeleccionado--) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_anioSeleccionado', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _anioSeleccionado < DateTime.now().year ? () => setState(() => _anioSeleccionado++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
              // Selector de año cuando periodo = ANUAL
              if (_periodoRapido == 'ANUAL') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _anioSeleccionado > 2020 ? () => setState(() => _anioSeleccionado--) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_anioSeleccionado', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _anioSeleccionado < DateTime.now().year ? () => setState(() => _anioSeleccionado++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Rango personalizado con CustomDate
              CustomDate(
                dateType: DateFieldType.dateRange,
                label: 'Seleccionar rango de fechas',
                hintText: 'Desde — Hasta',
                borderColor: AppColors.blue1,
                initialDateRange: _dateRange,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                onDateRangeSelected: (range) {
                  if (range != null) setState(() => _dateRange = range);
                },
              ),
            ],

            const SizedBox(height: 8),

            // Sede selector
            if (sedes.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _sedeId,
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    hint: const Text('Todas las sedes', style: TextStyle(fontSize: 11)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas las sedes', style: TextStyle(fontSize: 11))),
                      ...sedes.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre, style: const TextStyle(fontSize: 11)))),
                    ],
                    onChanged: (v) => setState(() => _sedeId = v),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Botón buscar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoChip(String value, String label, IconData icon) {
    final selected = _periodoRapido == value;
    return GestureDetector(
      onTap: () => setState(() => _periodoRapido = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.blue1 : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppColors.blue1 : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCards(Map<String, dynamic> resumen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSubtitle('Resumen General', fontSize: 14),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            _kpiCard('Total Ventas', '${resumen['totalVentas'] ?? 0}', Icons.receipt_long, Colors.blue),
            _kpiCard('Monto Total', 'S/${_formatNumber(resumen['montoTotal'])}', Icons.attach_money, Colors.green),
            _kpiCard('Ticket Promedio', 'S/${_formatNumber(resumen['promedioPorVenta'])}', Icons.trending_up, Colors.orange),
            _kpiCard('Pendientes', '${resumen['ventasBorrador'] ?? 0}', Icons.pending, Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
            ]),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparativo(Map<String, dynamic> comparativo) {
    final actual = comparativo['periodoActual'] as Map<String, dynamic>?;
    final anterior = comparativo['periodoAnterior'] as Map<String, dynamic>?;
    final cambio = (comparativo['porcentajeCambio'] ?? 0).toDouble();
    final isPositive = cambio >= 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header con botón de filtro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppSubtitle('Comparativo Mensual', fontSize: 13),
              GestureDetector(
                onTap: () => setState(() => _compFiltroExpandido = !_compFiltroExpandido),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _compFiltroExpandido ? AppColors.blue1.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 12, color: _compFiltroExpandido ? AppColors.blue1 : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${_meses[_compMesAnterior - 1]} vs ${_meses[_compMesActual - 1]} $_compAnioActual',
                        style: TextStyle(fontSize: 9, color: _compFiltroExpandido ? AppColors.blue1 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Filtros expandibles del comparativo
          if (_compFiltroExpandido) ...[
            const SizedBox(height: 10),
            // Periodo A (anterior)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periodo A', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 12,
                          separatorBuilder: (_, __) => const SizedBox(width: 3),
                          itemBuilder: (_, i) {
                            final mes = i + 1;
                            final sel = mes == _compMesAnterior;
                            return GestureDetector(
                              onTap: () => setState(() => _compMesAnterior = mes),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.blue1 : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: sel ? AppColors.blue1 : Colors.grey.shade300),
                                ),
                                child: Text(_meses[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildMiniYearSelector(_compAnioAnterior, (v) => setState(() => _compAnioAnterior = v)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Periodo B (actual)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periodo B', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.blue1)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 12,
                          separatorBuilder: (_, __) => const SizedBox(width: 3),
                          itemBuilder: (_, i) {
                            final mes = i + 1;
                            final sel = mes == _compMesActual;
                            return GestureDetector(
                              onTap: () => setState(() => _compMesActual = mes),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.blue1 : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: sel ? AppColors.blue1 : Colors.grey.shade300),
                                ),
                                child: Text(_meses[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildMiniYearSelector(_compAnioActual, (v) => setState(() => _compAnioActual = v)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { setState(() => _compFiltroExpandido = false); _load(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Comparar', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Datos
          Row(children: [
            Expanded(child: Column(children: [
              Text('${_meses[_compMesAnterior - 1]} $_compAnioAnterior', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('S/ ${_formatNumber(anterior?['montoTotal'])}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              Text('${anterior?['totalVentas'] ?? 0} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14, color: isPositive ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text('${cambio.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: isPositive ? Colors.green : Colors.red)),
              ]),
            ),
            Expanded(child: Column(children: [
              Text('${_meses[_compMesActual - 1]} $_compAnioActual', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('S/ ${_formatNumber(actual?['montoTotal'])}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${actual?['totalVentas'] ?? 0} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMiniYearSelector(int year, ValueChanged<int> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: year > 2020 ? () => onChanged(year - 1) : null,
          child: Icon(Icons.chevron_left, size: 16, color: year > 2020 ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        Text('$year', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: year < DateTime.now().year ? () => onChanged(year + 1) : null,
          child: Icon(Icons.chevron_right, size: 16, color: year < DateTime.now().year ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildTopProductos(List<dynamic> productos) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Productos', fontSize: 13),
          const SizedBox(height: 12),
          if (productos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...productos.take(5).map((p) {
              final item = p as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${item['cantidadVendida'] ?? 0} vendidos', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ])),
                  Text('S/${_formatNumber(item['ingresoTotal'])}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildTopClientes(List<dynamic> clientes) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Clientes', fontSize: 13),
          const SizedBox(height: 12),
          if (clientes.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...clientes.take(5).map((c) {
              final item = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${item['totalCompras'] ?? 0} compras', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ])),
                  Text('S/${_formatNumber(item['montoTotal'])}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildVentasPeriodo(List<dynamic> periodos) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Ventas por Periodo', fontSize: 13),
          const SizedBox(height: 12),
          if (periodos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...periodos.take(12).map((p) {
              final item = p as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(item['periodo'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  Text('${item['cantidad'] ?? 0} ventas', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text('S/${_formatNumber(item['total'])}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildAlertas(List<dynamic> alertas) {
    return GradientContainer(
      borderColor: Colors.amber.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber, size: 16, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            AppSubtitle('Alertas (${alertas.length})', fontSize: 13),
          ]),
          const SizedBox(height: 12),
          ...alertas.map((a) {
            final item = a as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.circle, size: 6, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(item['mensaje'] ?? '', style: const TextStyle(fontSize: 11))),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final n = value is double ? value : (value is int ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0);
    return n.toStringAsFixed(2);
  }
}
