import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/flujo_proyectado.dart';
import '../bloc/flujo_proyectado_cubit.dart';
import '../bloc/flujo_proyectado_state.dart';

class FlujoProyectadoPage extends StatelessWidget {
  const FlujoProyectadoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<FlujoProyectadoCubit>(),
      child: const _FlujoProyectadoView(),
    );
  }
}

class _FlujoProyectadoView extends StatefulWidget {
  const _FlujoProyectadoView();

  @override
  State<_FlujoProyectadoView> createState() => _FlujoProyectadoViewState();
}

class _FlujoProyectadoViewState extends State<_FlujoProyectadoView> {
  int _mesesSeleccionados = 3;

  final List<Map<String, dynamic>> _opcionesPeriodo = [
    {'label': '1 mes', 'value': 1},
    {'label': '3 meses', 'value': 3},
    {'label': '6 meses', 'value': 6},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<FlujoProyectadoCubit>().loadProyeccion(
          meses: _mesesSeleccionados,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Flujo Proyectado',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocBuilder<FlujoProyectadoCubit, FlujoProyectadoState>(
          builder: (context, state) {
            if (state is FlujoProyectadoLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FlujoProyectadoError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }
            if (state is FlujoProyectadoLoaded) {
              return _buildContent(state.periodos);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<PeriodoFlujo> periodos) {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          if (periodos.isNotEmpty) _buildCurrentBalanceCard(periodos.first),
          const SizedBox(height: 12),
          if (periodos.length > 1) _buildChart(periodos),
          const SizedBox(height: 12),
          if (periodos.isEmpty)
            _buildEmptyState()
          else
            ...periodos.map((p) => _PeriodoCard(periodo: p)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const AppSubtitle('Proyeccion:', fontSize: 13),
        const SizedBox(width: 12),
        ..._opcionesPeriodo.map((op) {
          final value = op['value'] as int;
          final isSelected = value == _mesesSeleccionados;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                op['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.blue1,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.blue1,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.blue1 : Colors.grey.shade300,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                setState(() => _mesesSeleccionados = value);
                _load();
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCurrentBalanceCard(PeriodoFlujo first) {
    final saldoProyectado = first.saldoProyectado;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, size: 24, color: AppColors.blue1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Proyectado Inicial',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  AppSubtitle(
                    'S/ ${saldoProyectado.toStringAsFixed(2)}',
                    fontSize: 20,
                    color: saldoProyectado >= 0 ? AppColors.blue1 : AppColors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<PeriodoFlujo> periodos) {
    final maxVal = periodos.fold<double>(0, (prev, p) {
      final maxInPeriod = [p.cobrosEsperados, p.pagosEsperados, p.cuotasPrestamos]
          .reduce((a, b) => a > b ? a : b);
      return maxInPeriod > prev ? maxInPeriod : prev;
    });

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('Comparativa por periodo', fontSize: 12),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.green, 'Cobros'),
                const SizedBox(width: 12),
                _legendDot(AppColors.red, 'Pagos'),
                const SizedBox(width: 12),
                _legendDot(AppColors.orange, 'Cuotas'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final labels = ['Cobros', 'Pagos', 'Cuotas'];
                        return BarTooltipItem(
                          '${labels[rodIndex]}\nS/ ${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= periodos.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              periodos[idx].label,
                              style: const TextStyle(fontSize: 9, color: AppColors.blue3),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          String label;
                          if (value >= 1000) {
                            label = '${(value / 1000).toStringAsFixed(1)}k';
                          } else {
                            label = value.toStringAsFixed(0);
                          }
                          return Text(
                            label,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 0.8,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: periodos.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: p.cobrosEsperados,
                          color: AppColors.green,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: p.pagosEsperados,
                          color: AppColors.red,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: p.cuotasPrestamos,
                          color: AppColors.orange,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.trending_up, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No hay datos de flujo proyectado',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodoCard extends StatelessWidget {
  final PeriodoFlujo periodo;
  const _PeriodoCard({required this.periodo});

  @override
  Widget build(BuildContext context) {
    final flujoNeto = periodo.flujoNeto ?? (periodo.cobrosEsperados - periodo.pagosEsperados - periodo.cuotasPrestamos);
    final saldoProyectado = periodo.saldoProyectado;

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: saldoProyectado < 0 ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, size: 14, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle(periodo.label, fontSize: 13, color: AppColors.blue1),
              ],
            ),
            const SizedBox(height: 10),
            _buildRow('Cobros esperados', periodo.cobrosEsperados, AppColors.green),
            const SizedBox(height: 4),
            _buildRow('Pagos esperados', periodo.pagosEsperados, AppColors.red),
            const SizedBox(height: 4),
            _buildRow('Cuotas prestamos', periodo.cuotasPrestamos, AppColors.orange),
            Divider(color: Colors.grey.shade300, height: 16),
            _buildRow('Flujo neto', flujoNeto, flujoNeto >= 0 ? AppColors.green : AppColors.red),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (saldoProyectado >= 0 ? AppColors.blue1 : AppColors.red).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo proyectado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: saldoProyectado >= 0 ? AppColors.blue3 : AppColors.red,
                    ),
                  ),
                  Text(
                    'S/ ${saldoProyectado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: saldoProyectado >= 0 ? AppColors.blue1 : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double monto, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        Text(
          'S/ ${monto.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
