import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/caja_movimientos_cubit.dart';
import 'movimientos_caja_page.dart';
import '../../domain/entities/caja_monitor.dart';
import '../bloc/caja_monitor_cubit.dart';
import '../bloc/caja_monitor_state.dart';

class CajaMonitorPage extends StatefulWidget {
  const CajaMonitorPage({super.key});

  @override
  State<CajaMonitorPage> createState() => _CajaMonitorPageState();
}

class _CajaMonitorPageState extends State<CajaMonitorPage> {
  late final CajaMonitorCubit _monitorCubit;

  @override
  void initState() {
    super.initState();
    _monitorCubit = locator<CajaMonitorCubit>();
    _monitorCubit.loadMonitor();
  }

  @override
  void dispose() {
    _monitorCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _monitorCubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Monitor de Cajas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _monitorCubit.loadMonitor(),
            ),
          ],
        ),
        body: GradientBackground(
          style: GradientStyle.minimal,
          child: BlocBuilder<CajaMonitorCubit, CajaMonitorState>(
            builder: (context, state) {
              if (state is CajaMonitorLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CajaMonitorError) {
                return _buildErrorState(state.message);
              }

              if (state is CajaMonitorLoaded) {
                return _buildLoadedContent(state.data);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _monitorCubit.loadMonitor(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(CajaMonitorData data) {
    if (data.cajas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay cajas abiertas',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _monitorCubit.loadMonitor();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResumenCard(data.resumen),
          if (data.cajas.length > 1) ...[
            const SizedBox(height: 12),
            _buildRankingCajeros(data.cajas),
          ],
          const SizedBox(height: 16),
          ...data.cajas.map((caja) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => locator<CajaMovimientosCubit>()..loadMovimientos(caja.id),
                        child: MovimientosCajaPage(cajaId: caja.id),
                      ),
                    ),
                  ),
                  child: _buildCajaCard(caja),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildResumenCard(CajaMonitorResumen resumen) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return GradientContainer(
      borderColor: AppColors.bluechip,
      shadowStyle: ShadowStyle.glow,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniMetric(
              label: 'Cajas Abiertas',
              value: resumen.totalCajasAbiertas.toString(),
              color: AppColors.blue2,
            ),
          ),
          Expanded(
            child: _buildMiniMetric(
              label: 'Total Ingresos',
              value: currencyFormat.format(resumen.totalIngresos),
              color: AppColors.green,
            ),
          ),
          Expanded(
            child: _buildMiniMetric(
              label: 'Total Egresos',
              value: currencyFormat.format(resumen.totalEgresos),
              color: AppColors.red,
            ),
          ),
          Expanded(
            child: _buildMiniMetric(
              label: 'Saldo Total',
              value: currencyFormat.format(resumen.totalSaldo),
              color: AppColors.blue1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCajeros(List<CajaMonitorItem> cajas) {
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);
    final sorted = List<CajaMonitorItem>.from(cajas)
      ..sort((a, b) => b.totalIngresos.compareTo(a.totalIngresos));

    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              const AppSubtitle('Ranking Cajeros', fontSize: 13),
            ],
          ),
          const SizedBox(height: 10),
          ...sorted.asMap().entries.map((entry) {
            final pos = entry.key;
            final caja = entry.value;
            final esLider = pos == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: esLider ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${pos + 1}',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: esLider ? Colors.amber[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (esLider) ...[
                    Icon(Icons.emoji_events, size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      caja.usuarioNombre.isNotEmpty ? caja.usuarioNombre : caja.codigo,
                      style: TextStyle(fontSize: 11, fontWeight: esLider ? FontWeight.w700 : FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    currencyFormat.format(caja.totalIngresos),
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: esLider ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${caja.totalMovimientos} mov',
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCajaCard(CajaMonitorItem caja) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );
    final duracion = caja.tiempoAbierta;
    final duracionText = _formatDuration(duracion);
    final showWarning = duracion.inHours >= 12;

    return GradientContainer(
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: codigo + sede badge + tiempo abierta
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSubtitle(
                  caja.codigo,
                  fontSize: 13,
                  color: AppColors.blue3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  caja.sedeNombre,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: showWarning ? Colors.orange : AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                duracionText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: showWarning ? Colors.orange : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cajero
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  caja.usuarioNombre.isNotEmpty ? caja.usuarioNombre : '-',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Metrics row: Ingresos, Egresos, Saldo
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  label: 'Ingresos',
                  value: currencyFormat.format(caja.totalIngresos),
                  color: AppColors.green,
                ),
              ),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Egresos',
                  value: currencyFormat.format(caja.totalEgresos),
                  color: AppColors.red,
                ),
              ),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Saldo',
                  value: currencyFormat.format(caja.saldoActual),
                  color: AppColors.blue2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer: movimientos + ultimo movimiento + inactividad
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${caja.totalMovimientos} mov.',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              if (caja.ultimoMovimiento != null) ...[
                const SizedBox(width: 6),
                const Text('|', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildUltimoMovimientoText(caja.ultimoMovimiento!),
                    style: TextStyle(
                      fontSize: 11,
                      color: caja.ultimoMovimiento!.tipo == 'INGRESO'
                          ? AppColors.green
                          : AppColors.red,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
          // Tiempo sin actividad
          if (caja.ultimoMovimiento != null) ...[
            const SizedBox(height: 6),
            Builder(builder: (_) {
              final sinActividad = DateTime.now().difference(caja.ultimoMovimiento!.fechaMovimiento);
              final esInactiva = sinActividad.inMinutes > 60;
              if (!esInactiva) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (sinActividad.inHours >= 4 ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_empty, size: 12,
                        color: sinActividad.inHours >= 4 ? Colors.red[700] : Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Sin actividad: ${_formatDuration(sinActividad)}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: sinActividad.inHours >= 4 ? Colors.red[700] : Colors.orange[700]),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Promedio por movimiento
          if (caja.totalMovimientos > 0 && caja.totalIngresos > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.trending_up, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Promedio: ${currencyFormat.format(caja.totalIngresos / caja.totalMovimientos)} / mov',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ],

          // Warning if open > 12h
          if (showWarning) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Abierta hace mas de 12h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildUltimoMovimientoText(UltimoMovimiento mov) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );
    final timeAgo = _formatTimeAgo(DateTime.now().difference(mov.fechaMovimiento));
    return '${mov.tipo} ${currencyFormat.format(mov.monto)} - $timeAgo';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return '${duration.inDays}d ${hours}h';
    }
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours}h ${minutes}min';
    }
    return '${duration.inMinutes}min';
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inDays > 0) {
      return 'hace ${duration.inDays}d';
    }
    if (duration.inHours > 0) {
      return 'hace ${duration.inHours}h';
    }
    if (duration.inMinutes > 0) {
      return 'hace ${duration.inMinutes}min';
    }
    return 'hace un momento';
  }
}
