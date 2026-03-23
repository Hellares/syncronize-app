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
          _buildAsistenciaHoyCard(dashboard.asistenciaHoy),
          const SizedBox(height: 16),

          // Planilla actual
          if (dashboard.planillaActual != null) ...[
            _buildPlanillaActualCard(dashboard.planillaActual!),
            const SizedBox(height: 16),
          ],

          // Alertas
          if (dashboard.alertas.isNotEmpty) ...[
            const Text(
              'Alertas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...dashboard.alertas.map((a) => _buildAlertaCard(a)),
          ],

          // Quick navigation
          const SizedBox(height: 20),
          const Text(
            'Accesos Directos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildStatCardsGrid(BuildContext context, DashboardRrhh dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          icon: Icons.people_rounded,
          label: 'Total Empleados',
          value: '${dashboard.totalEmpleados}',
          color: AppColors.blue1,
        ),
        _buildStatCard(
          icon: Icons.fingerprint_rounded,
          label: 'Asistencia Hoy',
          value: '${dashboard.asistenciaHoy.presentes}',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Incidencias Pend.',
          value: '${dashboard.incidenciasPendientes}',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.request_quote_rounded,
          label: 'Adelantos Pend.',
          value: '${dashboard.adelantosPendientes}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAsistenciaHoyCard(AsistenciaHoy asistencia) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniChip('Presentes', '${asistencia.presentes}', Colors.green),
              _buildMiniChip('Tardanzas', '${asistencia.tardanzas}', Colors.orange),
              _buildMiniChip('Ausentes', '${asistencia.ausentes}', Colors.red),
              _buildMiniChip('Justificados', '${asistencia.justificados}', Colors.blue),
              _buildMiniChip('Vacaciones', '${asistencia.enVacacion}', Colors.teal),
              _buildMiniChip('Licencia', '${asistencia.enLicencia}', Colors.purple),
              _buildMiniChip('Sin Registro', '${asistencia.sinRegistro}', Colors.grey),
            ],
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
      _QuickAction(Icons.people, 'Empleados', '/empresa/rrhh/empleados'),
      _QuickAction(Icons.schedule, 'Turnos', '/empresa/rrhh/turnos'),
      _QuickAction(Icons.calendar_view_week, 'Horarios', '/empresa/rrhh/horarios'),
      _QuickAction(Icons.fingerprint, 'Asistencia', '/empresa/rrhh/asistencia'),
      _QuickAction(Icons.event_note, 'Incidencias', '/empresa/rrhh/incidencias'),
      _QuickAction(Icons.receipt_long, 'Planilla', '/empresa/rrhh/planilla'),
      _QuickAction(Icons.payments, 'Adelantos', '/empresa/rrhh/adelantos'),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, size: 24, color: AppColors.blue1),
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

  const _QuickAction(this.icon, this.label, this.route);
}
