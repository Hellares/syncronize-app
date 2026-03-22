import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/agente_bancario.dart';
import '../bloc/agente_bancario_cubit.dart';
import '../bloc/agente_bancario_state.dart';
import '../widgets/crear_agente_dialog.dart';

class AgentesBancariosPage extends StatelessWidget {
  const AgentesBancariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AgenteBancarioCubit>()..loadResumen(),
      child: const _AgentesBancariosView(),
    );
  }
}

class _AgentesBancariosView extends StatelessWidget {
  const _AgentesBancariosView();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Agentes Bancarios',
          backgroundColor: Colors.teal,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.teal,
          onPressed: () {
            final empresaState = context.read<EmpresaContextCubit>().state;
            String sedeId = '';
            if (empresaState is EmpresaContextLoaded) {
              sedeId = empresaState.context.sedePrincipal?.id ??
                       (empresaState.context.sedes.isNotEmpty ? empresaState.context.sedes.first.id : '');
            }
            CrearAgenteDialog.show(
              context,
              onConfirm: (data) {
                context.read<AgenteBancarioCubit>().crearAgente(sedeId, data);
              },
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocBuilder<AgenteBancarioCubit, AgenteBancarioState>(
          builder: (context, state) {
            if (state is AgenteBancarioLoading ||
                state is AgenteBancarioInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (state is AgenteBancarioError) {
              return _ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<AgenteBancarioCubit>().loadResumen(),
              );
            }
            if (state is AgenteBancarioLoaded) {
              return _LoadedContent(
                resumen: state.resumen,
                agentes: state.agentes,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  final ResumenAgentes resumen;
  final List<AgenteBancario> agentes;
  const _LoadedContent({required this.resumen, required this.agentes});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<AgenteBancarioCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        children: [
          _ResumenCard(resumen: resumen),
          const SizedBox(height: 12),
          _OperacionesHoyRow(resumen: resumen),
          const SizedBox(height: 16),
          if (agentes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay agentes bancarios registrados.\nPresiona + para crear uno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            )
          else
            ...agentes.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AgenteCard(agente: a),
                )),
        ],
      ),
    );
  }
}

// ── RESUMEN CARD ───────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final ResumenAgentes resumen;
  const _ResumenCard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF009688)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Resumen General',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${resumen.agentesActivos}/${resumen.totalAgentes} activos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResumenItem(
                  label: 'Fondo Total',
                  value: 'S/ ${_formatNumber(resumen.fondoTotalAsignado)}',
                ),
              ),
              Expanded(
                child: _ResumenItem(
                  label: 'Saldo Actual',
                  value: 'S/ ${_formatNumber(resumen.saldoTotalActual)}',
                ),
              ),
              Expanded(
                child: _ResumenItem(
                  label: 'Comisiones Hoy',
                  value: 'S/ ${_formatNumber(resumen.comisionesHoy)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String value;
  const _ResumenItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ── OPERACIONES HOY ROW ────────────────────────────────────────────

class _OperacionesHoyRow extends StatelessWidget {
  final ResumenAgentes resumen;
  const _OperacionesHoyRow({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.green.withValues(alpha: 0.3),
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.green.withValues(alpha: 0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward,
                        size: 14, color: AppColors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Depositos Hoy',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'S/ ${_formatNumber(resumen.depositosHoyMonto)}',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${resumen.depositosHoyCant} ops',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.red.withValues(alpha: 0.3),
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.red.withValues(alpha: 0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward, size: 14, color: AppColors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Retiros Hoy',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'S/ ${_formatNumber(resumen.retirosHoyMonto)}',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${resumen.retirosHoyCant} ops',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── AGENTE CARD ────────────────────────────────────────────────────

class _AgenteCard extends StatelessWidget {
  final AgenteBancario agente;
  const _AgenteCard({required this.agente});

  @override
  Widget build(BuildContext context) {
    final progressColor = agente.fondoBajo
        ? AppColors.red
        : agente.porcentajeFondoUsado > 60
            ? AppColors.orange
            : Colors.teal;

    return GestureDetector(
      onTap: () => context.push('/empresa/agentes-bancarios/${agente.id}'),
      child: GradientContainer(
        borderColor: Colors.teal.withValues(alpha: 0.2),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF0FAFA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance,
                      color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agente.banco,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (agente.codigoAgente != null)
                        Text(
                          'Cod: ${agente.codigoAgente}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: agente.estaActivo
                        ? AppColors.green.withValues(alpha: 0.1)
                        : AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    agente.estado,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: agente.estaActivo ? AppColors.green : AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Row(
              children: [
                Text(
                  'Saldo: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'S/ ${_formatNumber(agente.saldoActual)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Fondo: S/ ${_formatNumber(agente.fondoAsignado)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: agente.fondoAsignado > 0
                    ? (agente.saldoActual / agente.fondoAsignado)
                        .clamp(0.0, 1.0)
                    : 0,
                minHeight: 6,
                backgroundColor: progressColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            if (agente.fondoBajo) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 12, color: AppColors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Fondo bajo',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Mini stats
            Row(
              children: [
                _MiniStat(
                  icon: Icons.arrow_downward,
                  color: AppColors.green,
                  label: '${agente.depositosHoyCant}',
                  value: 'S/ ${_formatNumber(agente.depositosHoyMonto)}',
                ),
                const SizedBox(width: 16),
                _MiniStat(
                  icon: Icons.arrow_upward,
                  color: AppColors.red,
                  label: '${agente.retirosHoyCant}',
                  value: 'S/ ${_formatNumber(agente.retirosHoyMonto)}',
                ),
                const Spacer(),
                Text(
                  'Com: S/ ${_formatNumber(agente.comisionesHoy)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          '$label  ',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── HELPERS ────────────────────────────────────────────────────────

String _formatNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(2);
}
