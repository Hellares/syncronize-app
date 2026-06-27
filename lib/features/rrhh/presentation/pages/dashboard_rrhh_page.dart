import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

import '../../domain/entities/dashboard_rrhh.dart';
import '../bloc/dashboard_rrhh/dashboard_rrhh_cubit.dart';
import '../bloc/dashboard_rrhh/dashboard_rrhh_state.dart';

class DashboardRrhhPage extends StatefulWidget {
  const DashboardRrhhPage({super.key});

  @override
  State<DashboardRrhhPage> createState() => _DashboardRrhhPageState();
}

class _DashboardRrhhPageState extends State<DashboardRrhhPage> {
  late final DashboardRrhhCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<DashboardRrhhCubit>();
    _cubit.loadDashboard();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'RRHH',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientContainer(
          child: BlocBuilder<DashboardRrhhCubit, DashboardRrhhState>(
            builder: (context, state) {
              if (state is DashboardRrhhLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DashboardRrhhError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.red),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _cubit.loadDashboard(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (state is DashboardRrhhLoaded) {
                return _buildDashboard(context, state.dashboard);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardRrhh dashboard) {
    return RefreshIndicator(
      onRefresh: () async => await _cubit.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat cards grid
          _buildStatCardsGrid(context, dashboard),
          const SizedBox(height: 20),

          // Asistencia hoy
          _buildAsistenciaHoyCard(
              context, dashboard.asistenciaHoy, dashboard.totalEmpleados),
          const SizedBox(height: 16),

          // Planilla actual
          if (dashboard.planillaActual != null) ...[
            _buildPlanillaActualCard(dashboard.planillaActual!),
            const SizedBox(height: 16),
          ],

          // Alertas
          if (dashboard.alertas.isNotEmpty) ...[
            _buildSectionTitle('Alertas', Icons.notifications_active_outlined),
            const SizedBox(height: 10),
            ...dashboard.alertas.map((a) => _buildAlertaCard(a)),
          ],

          // Quick navigation
          const SizedBox(height: 20),
          _buildSectionTitle('Accesos Directos', Icons.apps_rounded),
          const SizedBox(height: 12),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.blue1,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsGrid(BuildContext context, DashboardRrhh dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
          icon: Icons.people_rounded,
          label: 'Total Empleados',
          value: '${dashboard.totalEmpleados}',
          color: AppColors.blue1,
          onTap: () => context.push('/empresa/rrhh/empleados'),
        ),
        _buildStatCard(
          icon: Icons.fingerprint_rounded,
          label: 'Asistencia Hoy',
          value: '${dashboard.asistenciaHoy.presentes}',
          color: Colors.green,
          onTap: () => context.push('/empresa/rrhh/asistencia'),
        ),
        _buildStatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Incidencias Pend.',
          value: '${dashboard.incidenciasPendientes}',
          color: Colors.orange,
          onTap: () => context.push('/empresa/rrhh/incidencias'),
        ),
        _buildStatCard(
          icon: Icons.request_quote_rounded,
          label: 'Adelantos Pend.',
          value: '${dashboard.adelantosPendientes}',
          color: Colors.purple,
          onTap: () => context.push('/empresa/rrhh/adelantos'),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: GradientContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciaHoyCard(
      BuildContext context, AsistenciaHoy a, int totalEmpleados) {
    final items = <_AsistStat>[
      _AsistStat('Presentes', a.presentes, Colors.green, Icons.check_circle),
      _AsistStat('Tardanzas', a.tardanzas, Colors.orange, Icons.timelapse),
      _AsistStat('Ausentes', a.ausentes, Colors.red, Icons.cancel),
      _AsistStat(
          'Justificados', a.justificados, Colors.blue, Icons.verified_outlined),
      _AsistStat('Vacaciones', a.enVacacion, Colors.teal, Icons.beach_access),
      _AsistStat('Licencia', a.enLicencia, Colors.purple, Icons.local_hospital),
      _AsistStat(
          'Sin registro', a.sinRegistro, Colors.blueGrey, Icons.help_outline),
    ];
    final total = items.fold<int>(0, (s, i) => s + i.count);
    final registrados = total - a.sinRegistro;
    final pct = total > 0 ? (a.presentes / total * 100).round() : 0;
    final visibles = items.where((i) => i.count > 0).toList();

    return InkWell(
      onTap: () => context.push('/empresa/rrhh/asistencia'),
      borderRadius: BorderRadius.circular(16),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fingerprint_rounded,
                      size: 20, color: Colors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asistencia de Hoy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue3,
                        ),
                      ),
                      Text(
                        '$registrados de $totalEmpleados registrados',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // % de asistencia
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'presentes',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 14),

            // Barra apilada por estado
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: total == 0
                    ? Container(color: Colors.grey.withValues(alpha: 0.15))
                    : Row(
                        children: visibles
                            .map((i) => Expanded(
                                  flex: i.count,
                                  child: Container(color: i.color),
                                ))
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Desglose: TODOS los estados (2 por fila), ícono + número + label
            for (var i = 0; i < items.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildAsistStatTile(items[i])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: i + 1 < items.length
                          ? _buildAsistStatTile(items[i + 1])
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistStatTile(_AsistStat item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 14, color: item.color),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.count}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: item.color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanillaActualCard(PlanillaActualResumen planilla) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Planilla Actual',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  planilla.estado,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Periodo: ${planilla.periodo}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (planilla.totalNeto != null) ...[
            const SizedBox(height: 4),
            Text(
              'Total Neto: S/ ${planilla.totalNeto!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniChip(
                'Pendientes',
                '${planilla.boletasPendientes}',
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildMiniChip(
                'Pagadas',
                '${planilla.boletasPagadas}',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaCard(AlertaRrhh alerta) {
    Color alertColor;
    IconData alertIcon;
    switch (alerta.tipo.toUpperCase()) {
      case 'URGENTE':
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case 'ADVERTENCIA':
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: alertColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(alertIcon, size: 20, color: alertColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alerta.mensaje,
              style: TextStyle(
                fontSize: 13,
                color: alertColor.withValues(alpha: 0.9),
              ),
            ),
          ),
          if (alerta.cantidad > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: alertColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${alerta.cantidad}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
          Icons.people, 'Empleados', '/empresa/rrhh/empleados', AppColors.blue1),
      _QuickAction(
          Icons.schedule, 'Turnos', '/empresa/rrhh/turnos', Colors.indigo),
      _QuickAction(Icons.calendar_view_week, 'Horarios',
          '/empresa/rrhh/horarios', Colors.deepPurple),
      _QuickAction(Icons.fingerprint, 'Asistencia',
          '/empresa/rrhh/asistencia', Colors.green),
      _QuickAction(Icons.event_note, 'Incidencias',
          '/empresa/rrhh/incidencias', Colors.orange),
      _QuickAction(Icons.receipt_long, 'Planilla', '/empresa/rrhh/planilla',
          Colors.teal),
      _QuickAction(Icons.payments, 'Adelantos', '/empresa/rrhh/adelantos',
          Colors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () => context.push(action.route),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: action.color.withValues(alpha: 0.18)),
                ),
                child: Icon(action.icon, size: 24, color: action.color),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _QuickAction(this.icon, this.label, this.route, this.color);
}

class _AsistStat {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _AsistStat(this.label, this.count, this.color, this.icon);
}
