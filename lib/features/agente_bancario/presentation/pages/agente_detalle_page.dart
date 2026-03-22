import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/agente_bancario.dart';
import '../bloc/agente_bancario_cubit.dart';
import '../bloc/agente_bancario_state.dart';
import '../widgets/registrar_operacion_dialog.dart';

class AgenteDetallePage extends StatelessWidget {
  final String agenteId;
  const AgenteDetallePage({super.key, required this.agenteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AgenteBancarioCubit>()..loadDetalle(agenteId),
      child: _AgenteDetalleView(agenteId: agenteId),
    );
  }
}

class _AgenteDetalleView extends StatelessWidget {
  final String agenteId;
  const _AgenteDetalleView({required this.agenteId});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Detalle Agente',
          backgroundColor: Colors.teal,
          foregroundColor: AppColors.white,
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
                onRetry: () => context
                    .read<AgenteBancarioCubit>()
                    .loadDetalle(agenteId),
              );
            }
            if (state is AgenteBancarioDetalleLoaded) {
              return _DetalleContent(
                agente: state.agente,
                operaciones: state.operaciones,
                agenteId: agenteId,
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

class _DetalleContent extends StatelessWidget {
  final AgenteBancario agente;
  final List<OperacionAgente> operaciones;
  final String agenteId;

  const _DetalleContent({
    required this.agente,
    required this.operaciones,
    required this.agenteId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<AgenteBancarioCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                _InfoCard(agente: agente),
                const SizedBox(height: 12),
                _DaySummaryRow(agente: agente),
                const SizedBox(height: 16),
                _OperacionesSection(
                  operaciones: operaciones,
                  agenteId: agenteId,
                ),
              ],
            ),
          ),
        ),
        _ActionButtons(agente: agente, agenteId: agenteId),
      ],
    );
  }
}

// ── INFO CARD ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final AgenteBancario agente;
  const _InfoCard({required this.agente});

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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  agente.banco,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: agente.estaActivo
                        ? Colors.greenAccent.withValues(alpha: 0.5)
                        : Colors.redAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  agente.estado,
                  style: TextStyle(
                    color: agente.estaActivo
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow('Codigo', agente.codigoAgente ?? '-'),
          _InfoRow('Sede', agente.sedeNombre ?? '-'),
          _InfoRow('Responsable', agente.responsableNombre ?? '-'),
          const Divider(color: Colors.white24, height: 20),
          Row(
            children: [
              Expanded(
                child: _WhiteMetric(
                  label: 'Fondo',
                  value: 'S/ ${_formatNumber(agente.fondoAsignado)}',
                ),
              ),
              Expanded(
                child: _WhiteMetric(
                  label: 'Saldo',
                  value: 'S/ ${_formatNumber(agente.saldoActual)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _WhiteMetric(
                  label: 'Com. Deposito',
                  value: '${agente.comisionDeposito}%',
                ),
              ),
              Expanded(
                child: _WhiteMetric(
                  label: 'Com. Retiro',
                  value: '${agente.comisionRetiro}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Saldo progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: agente.fondoAsignado > 0
                  ? (agente.saldoActual / agente.fondoAsignado).clamp(0.0, 1.0)
                  : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                agente.fondoBajo ? Colors.redAccent : Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteMetric extends StatelessWidget {
  final String label;
  final String value;
  const _WhiteMetric({required this.label, required this.value});

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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── DAY SUMMARY ROW ───────────────────────────────────────────────

class _DaySummaryRow extends StatelessWidget {
  final AgenteBancario agente;
  const _DaySummaryRow({required this.agente});

  @override
  Widget build(BuildContext context) {
    final neto = agente.depositosHoyMonto - agente.retirosHoyMonto;

    return Row(
      children: [
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.green.withValues(alpha: 0.3),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.green.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Icon(Icons.arrow_downward, size: 16, color: AppColors.green),
                const SizedBox(height: 4),
                Text(
                  'S/ ${_formatNumber(agente.depositosHoyMonto)}',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${agente.depositosHoyCant} dep.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.red.withValues(alpha: 0.3),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.red.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Icon(Icons.arrow_upward, size: 16, color: AppColors.red),
                const SizedBox(height: 4),
                Text(
                  'S/ ${_formatNumber(agente.retirosHoyMonto)}',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${agente.retirosHoyCant} ret.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.blue2.withValues(alpha: 0.3),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.blue2.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Icon(Icons.swap_vert, size: 16, color: AppColors.blue2),
                const SizedBox(height: 4),
                Text(
                  'S/ ${_formatNumber(neto)}',
                  style: TextStyle(
                    color: AppColors.blue2,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Neto',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GradientContainer(
            borderColor: Colors.teal.withValues(alpha: 0.3),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.teal.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Icon(Icons.monetization_on,
                    size: 16, color: Colors.teal),
                const SizedBox(height: 4),
                Text(
                  'S/ ${_formatNumber(agente.comisionesHoy)}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Comisiones',
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

// ── OPERACIONES SECTION ───────────────────────────────────────────

class _OperacionesSection extends StatelessWidget {
  final List<OperacionAgente> operaciones;
  final String agenteId;
  const _OperacionesSection({
    required this.operaciones,
    required this.agenteId,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.2),
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFF5F9FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: AppColors.blue2),
              SizedBox(width: 8),
              AppSubtitle('Historial de Operaciones', fontSize: 13),
            ],
          ),
          const SizedBox(height: 12),
          if (operaciones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Sin operaciones registradas',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...operaciones.map((op) => _OperacionTile(
                  operacion: op,
                  agenteId: agenteId,
                )),
        ],
      ),
    );
  }
}

class _OperacionTile extends StatelessWidget {
  final OperacionAgente operacion;
  final String agenteId;
  const _OperacionTile({required this.operacion, required this.agenteId});

  @override
  Widget build(BuildContext context) {
    final isDeposito = operacion.tipo == 'DEPOSITO';
    final color = isDeposito ? AppColors.green : AppColors.red;
    final dateStr = DateFormat('dd/MM HH:mm').format(operacion.fechaOperacion);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: operacion.anulado
            ? Colors.grey.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: operacion.anulado
              ? Colors.grey.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDeposito ? Icons.arrow_downward : Icons.arrow_upward,
            size: 18,
            color: operacion.anulado ? Colors.grey : color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operacion.nombreCliente ?? operacion.tipo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: operacion.anulado ? Colors.grey : null,
                    decoration: operacion.anulado
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (operacion.documentoCliente != null)
                  Text(
                    'DNI: ${operacion.documentoCliente}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      decoration: operacion.anulado
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposito ? '+' : '-'} S/ ${operacion.monto.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: operacion.anulado ? Colors.grey : color,
                  decoration:
                      operacion.anulado ? TextDecoration.lineThrough : null,
                ),
              ),
              if (operacion.comision > 0)
                Text(
                  'Com: S/ ${operacion.comision.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.teal.withValues(alpha: 0.7),
                  ),
                ),
              if (operacion.anulado)
                const Text(
                  'ANULADO',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (!operacion.anulado) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showAnularDialog(context),
              child: Icon(
                Icons.cancel_outlined,
                size: 18,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnularDialog(BuildContext context) {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anular Operacion', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo de anulacion *',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) return;
              context.read<AgenteBancarioCubit>().anularOperacion(
                    agenteId,
                    operacion.id,
                    motivoController.text.trim(),
                  );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }
}

// ── ACTION BUTTONS ────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AgenteBancario agente;
  final String agenteId;
  const _ActionButtons({required this.agente, required this.agenteId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  RegistrarOperacionDialog.show(
                    context,
                    tipo: 'DEPOSITO',
                    comisionPorcentaje: agente.comisionDeposito,
                    onConfirm: (data) {
                      context
                          .read<AgenteBancarioCubit>()
                          .registrarOperacion(agenteId, data);
                    },
                  );
                },
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: const Text('Deposito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  RegistrarOperacionDialog.show(
                    context,
                    tipo: 'RETIRO',
                    comisionPorcentaje: agente.comisionRetiro,
                    onConfirm: (data) {
                      context
                          .read<AgenteBancarioCubit>()
                          .registrarOperacion(agenteId, data);
                    },
                  );
                },
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Retiro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
