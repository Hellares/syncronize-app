import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/estadisticas_servicio.dart';
import '../bloc/dashboard/servicio_dashboard_cubit.dart';

class ServicioDashboardPage extends StatelessWidget {
  const ServicioDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';

        return BlocProvider(
          create: (_) => locator<ServicioDashboardCubit>()
            ..loadEstadisticas(empresaId: empresaId),
          child: _DashboardContent(empresaId: empresaId),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final String empresaId;
  const _DashboardContent({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(
          title: 'Dashboard de Servicios',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<ServicioDashboardCubit, ServicioDashboardState>(
          builder: (context, state) {
            if (state is ServicioDashboardLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.blue1));
            }

            if (state is ServicioDashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ServicioDashboardCubit>()
                          .loadEstadisticas(empresaId: empresaId),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is ServicioDashboardLoaded) {
              return _buildDashboard(context, state.estadisticas);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(
      BuildContext context, EstadisticasServicio stats) {
    return RefreshIndicator(
      onRefresh: () => context
          .read<ServicioDashboardCubit>()
          .loadEstadisticas(empresaId: empresaId),
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          _buildSummaryCards(stats),
          const SizedBox(height: 16),

          // Estado chart
          _buildEstadoChart(stats),
          const SizedBox(height: 16),

          // Monthly chart
          if (stats.ordenesPorMes.isNotEmpty) ...[
            _buildMonthlyChart(stats),
            const SizedBox(height: 16),
          ],

          // Tipo distribution
          if (stats.ordenesPorTipo.isNotEmpty) _buildTipoList(stats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(EstadisticasServicio stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.assignment,
                label: 'Total',
                value: '${stats.totalOrdenes}',
                color: AppColors.blue1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.pending_actions,
                label: 'En progreso',
                value: '${stats.enProgreso}',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.check_circle,
                label: 'Completadas',
                value: '${stats.completadas}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.monetization_on,
                label: 'Ingresos',
                value: 'S/ ${stats.ingresoTotal.toStringAsFixed(0)}',
                color: Colors.teal,
              ),
            ),
          ],
        ),
        if (stats.tiempoPromedioResolucion > 0) ...[
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.timer,
            label: 'Tiempo promedio de resolucion',
            value: _formatHours(stats.tiempoPromedioResolucion),
            color: Colors.indigo,
          ),
        ],
      ],
    );
  }

  Widget _buildEstadoChart(EstadisticasServicio stats) {
    if (stats.ordenesPorEstado.isEmpty) return const SizedBox.shrink();

    final entries = stats.ordenesPorEstado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('ORDENES POR ESTADO', fontSize: 12),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (entries.first.value * 1.2).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_estadoShortLabel(entries[groupIndex].key)}\n${rod.toY.toInt()}',
                          const TextStyle(
                              color: Colors.white, fontSize: 11),
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
                          if (value.toInt() >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _estadoInitials(
                                  entries[value.toInt()].key),
                              style: const TextStyle(fontSize: 8),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text('${value.toInt()}',
                                style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  barGroups: entries.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value.toDouble(),
                          color: _estadoColor(e.value.key),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
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

  Widget _buildMonthlyChart(EstadisticasServicio stats) {
    final meses = stats.ordenesPorMes;
    final rawMax = meses
        .fold<int>(0, (max, m) => m.cantidad > max ? m.cantidad : max);
    final maxY = rawMax > 0 ? rawMax.toDouble() : 1.0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('TENDENCIA MENSUAL', fontSize: 12),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY * 1.2,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= meses.length) {
                            return const SizedBox.shrink();
                          }
                          final parts = meses[idx].mes.split('-');
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              parts.length > 1 ? parts[1] : parts[0],
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text('${value.toInt()}',
                                style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: meses.asMap().entries.map((e) {
                        return FlSpot(
                            e.key.toDouble(), e.value.cantidad.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.blue1,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.blue1.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoList(EstadisticasServicio stats) {
    final entries = stats.ordenesPorTipo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('DISTRIBUCION POR TIPO', fontSize: 12),
            const SizedBox(height: 12),
            ...entries.map((e) {
              final pct = total > 0 ? (e.value / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_tipoLabel(e.key),
                            style: const TextStyle(fontSize: 12)),
                        Text('${e.value} (${pct.toStringAsFixed(0)}%)',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total > 0 ? e.value / total : 0,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.blue1,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatHours(int hours) {
    if (hours >= 24) {
      final days = hours ~/ 24;
      final h = hours % 24;
      return '${days}d ${h}h';
    }
    return '${hours}h';
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'RECIBIDO':
        return Colors.blue;
      case 'EN_DIAGNOSTICO':
        return Colors.orange;
      case 'ESPERANDO_APROBACION':
        return Colors.amber;
      case 'EN_REPARACION':
        return Colors.indigo;
      case 'PENDIENTE_PIEZAS':
        return Colors.deepOrange;
      case 'REPARADO':
        return Colors.teal;
      case 'LISTO_ENTREGA':
        return Colors.green;
      case 'ENTREGADO':
        return Colors.green.shade700;
      case 'FINALIZADO':
        return Colors.grey;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _estadoShortLabel(String estado) {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'Diagnostico',
      'ESPERANDO_APROBACION': 'Aprobacion',
      'EN_REPARACION': 'Reparacion',
      'PENDIENTE_PIEZAS': 'Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }

  String _estadoInitials(String estado) {
    const initials = {
      'RECIBIDO': 'REC',
      'EN_DIAGNOSTICO': 'DIA',
      'ESPERANDO_APROBACION': 'APR',
      'EN_REPARACION': 'REP',
      'PENDIENTE_PIEZAS': 'PIE',
      'REPARADO': 'RPD',
      'LISTO_ENTREGA': 'ENT',
      'ENTREGADO': 'ETG',
      'FINALIZADO': 'FIN',
      'CANCELADO': 'CAN',
    };
    return initials[estado] ?? estado.substring(0, 3);
  }

  String _tipoLabel(String tipo) {
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
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
