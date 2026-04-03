import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../usuario/presentation/bloc/usuario_list/usuario_list_cubit.dart';
import '../../../usuario/presentation/bloc/usuario_list/usuario_list_state.dart';
import '../../domain/entities/dashboard_vendedor.dart';
import '../bloc/dashboard_vendedor_cubit.dart';
import '../bloc/dashboard_vendedor_state.dart';

class DashboardVendedorPage extends StatelessWidget {
  final String? vendedorId;
  const DashboardVendedorPage({super.key, this.vendedorId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<DashboardVendedorCubit>()..loadDashboard(vendedorId: vendedorId)),
        BlocProvider(create: (_) => locator<UsuarioListCubit>()),
      ],
      child: _DashboardVendedorView(vendedorId: vendedorId),
    );
  }
}

class _DashboardVendedorView extends StatefulWidget {
  final String? vendedorId;
  const _DashboardVendedorView({this.vendedorId});

  @override
  State<_DashboardVendedorView> createState() => _DashboardVendedorViewState();
}

class _DashboardVendedorViewState extends State<_DashboardVendedorView> {
  String? _selectedVendedorId;
  bool _canViewAll = false;

  @override
  void initState() {
    super.initState();
    _selectedVendedorId = widget.vendedorId;

    // Verificar permisos y cargar lista de vendedores si es admin
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      final permisos = empresaState.context.permissions;
      _canViewAll = permisos.canViewEmpleados;
      if (_canViewAll) {
        context.read<UsuarioListCubit>().loadUsuarios(empresaId: empresaState.context.empresa.id);
      }
    }
  }

  void _onVendedorChanged(String? vendedorId) {
    setState(() => _selectedVendedorId = vendedorId);
    context.read<DashboardVendedorCubit>().loadDashboard(vendedorId: vendedorId);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Dashboard Vendedor',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<DashboardVendedorCubit>().loadDashboard(vendedorId: _selectedVendedorId),
            ),
          ],
        ),
        body: Column(
          children: [
            // Selector de vendedor (solo admin)
            if (_canViewAll)
              BlocBuilder<UsuarioListCubit, UsuarioListState>(
                builder: (context, state) {
                  if (state is UsuarioListLoaded) {
                    final usuarios = state.usuarios;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: CustomDropdown<String?>(
                        label: 'Vendedor',
                        hintText: 'Yo (mi dashboard)',
                        value: _selectedVendedorId,
                        borderColor: AppColors.blue1,
                        dropdownStyle: DropdownStyle.searchable,
                        items: [
                          const DropdownItem(value: null, label: 'Yo (mi dashboard)'),
                          ...usuarios.map((u) => DropdownItem(
                            value: u.id,
                            label: '${u.nombres} ${u.apellidos}'.trim(),
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
                              child: Text(
                                (u.nombres.isNotEmpty ? u.nombres[0] : '?').toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.blue1),
                              ),
                            ),
                          )),
                        ],
                        onChanged: _onVendedorChanged,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            // Dashboard content
            Expanded(
              child: BlocBuilder<DashboardVendedorCubit, DashboardVendedorState>(
                builder: (context, state) {
                  if (state is DashboardVendedorLoading || state is DashboardVendedorInitial) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (state is DashboardVendedorError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<DashboardVendedorCubit>().loadDashboard(vendedorId: _selectedVendedorId),
                    );
                  }
                  if (state is DashboardVendedorLoaded) {
                    return _DashboardContent(data: state.data);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
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

class _DashboardContent extends StatelessWidget {
  final DashboardVendedor data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardVendedorCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _HeaderCard(vendedor: data.vendedor, ranking: data.ranking),
          const SizedBox(height: 16),
          _ResumenRow(resumen: data.resumen),
          const SizedBox(height: 16),
          _MetricasRow(resumen: data.resumen),
          if (data.creditos.cantidadPendientes > 0) ...[
            const SizedBox(height: 16),
            _CreditosCard(creditos: data.creditos),
          ],
          const SizedBox(height: 16),
          _VentasSemanaChart(ventas: data.ventasPorDia),
          const SizedBox(height: 16),
          _MetodosPagoChart(metodos: data.metodosPago),
          if (data.topProductos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TopList(
              title: 'Top 5 Productos',
              icon: Icons.inventory_2,
              items: data.topProductos,
              unitLabel: 'uds',
            ),
          ],
          if (data.topClientes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TopList(
              title: 'Top 5 Clientes',
              icon: Icons.people,
              items: data.topClientes,
              unitLabel: 'compras',
            ),
          ],
        ],
      ),
    );
  }
}

// ─── HEADER CARD ───────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final VendedorInfo vendedor;
  final RankingVendedor ranking;
  const _HeaderCard({required this.vendedor, required this.ranking});

  Color _rankingColor(int pos) {
    if (pos == 1) return const Color(0xFFFFD700);
    if (pos == 2) return const Color(0xFFC0C0C0);
    if (pos == 3) return const Color(0xFFCD7F32);
    return Colors.white70;
  }

  IconData _rankingIcon(int pos) {
    if (pos <= 3) return Icons.emoji_events;
    return Icons.leaderboard;
  }

  @override
  Widget build(BuildContext context) {
    final progress = ranking.porcentajeVsLider / 100;
    final rankColor = _rankingColor(ranking.posicion);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.4),
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
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  vendedor.nombre.isNotEmpty
                      ? vendedor.nombre[0].toUpperCase()
                      : 'V',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendedor.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (vendedor.email != null)
                      Text(
                        vendedor.email!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Ranking badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_rankingIcon(ranking.posicion),
                        color: rankColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '#${ranking.posicion} de ${ranking.totalVendedores}',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar vs leader
          Row(
            children: [
              Text(
                'vs Lider: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              Text(
                '${ranking.porcentajeVsLider.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'S/ ${_formatNumber(ranking.montoVendedor)} / S/ ${_formatNumber(ranking.montoLider)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RESUMEN ROW ───────────────────────────────────────────────────

class _ResumenRow extends StatelessWidget {
  final ResumenVendedor resumen;
  const _ResumenRow({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PeriodoCard(
            label: 'Hoy',
            monto: resumen.ventasHoyMonto,
            cantidad: resumen.ventasHoyCantidad,
            color: AppColors.green,
            icon: Icons.today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodoCard(
            label: 'Semana',
            monto: resumen.ventasSemanaMonto,
            cantidad: resumen.ventasSemanaCantidad,
            color: AppColors.blue2,
            icon: Icons.date_range,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodoCard(
            label: 'Mes',
            monto: resumen.ventasMesMonto,
            cantidad: resumen.ventasMesCantidad,
            color: const Color(0xFF7B1FA2),
            icon: Icons.calendar_month,
          ),
        ),
      ],
    );
  }
}

class _PeriodoCard extends StatelessWidget {
  final String label;
  final double monto;
  final int cantidad;
  final Color color;
  final IconData icon;

  const _PeriodoCard({
    required this.label,
    required this.monto,
    required this.cantidad,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      gradient: LinearGradient(
        colors: [Colors.white, color.withValues(alpha: 0.05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'S/ ${_formatNumber(monto)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$cantidad ventas',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── METRICAS ROW ──────────────────────────────────────────────────

class _MetricasRow extends StatelessWidget {
  final ResumenVendedor resumen;
  const _MetricasRow({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Ticket Prom.',
            value: 'S/ ${_formatNumber(resumen.ticketPromedio)}',
            icon: Icons.receipt_long,
            color: const Color(0xFF00897B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Cotizaciones',
            value:
                '${resumen.cotizacionesConvertidas} conv. / ${resumen.cotizacionesTotal} total',
            icon: Icons.description,
            color: AppColors.blue2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ConversionCard(
            tasaConversion: resumen.tasaConversion,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      gradient: LinearGradient(
        colors: [Colors.white, color.withValues(alpha: 0.05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  final double tasaConversion;
  const _ConversionCard({required this.tasaConversion});

  @override
  Widget build(BuildContext context) {
    final color = tasaConversion >= 50
        ? AppColors.green
        : tasaConversion >= 25
            ? AppColors.orange
            : AppColors.red;

    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      gradient: LinearGradient(
        colors: [Colors.white, color.withValues(alpha: 0.05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (tasaConversion / 100).clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${tasaConversion.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Conversion',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CREDITOS CARD ─────────────────────────────────────────────────

class _CreditosCard extends StatelessWidget {
  final CreditosVendedor creditos;
  const _CreditosCard({required this.creditos});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: Colors.orange.withValues(alpha: 0.3),
      gradient: LinearGradient(
        colors: [Colors.white, Colors.orange.withValues(alpha: 0.05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              const AppSubtitle('Creditos Pendientes', fontSize: 13),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CreditoItem(
                  label: 'Pendiente',
                  monto: creditos.totalPendiente,
                  cantidad: creditos.cantidadPendientes,
                  color: AppColors.orange,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.greyLight,
              ),
              Expanded(
                child: _CreditoItem(
                  label: 'Vencido',
                  monto: creditos.totalVencido,
                  cantidad: creditos.cantidadVencidos,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreditoItem extends StatelessWidget {
  final String label;
  final double monto;
  final int cantidad;
  final Color color;

  const _CreditoItem({
    required this.label,
    required this.monto,
    required this.cantidad,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'S/ ${_formatNumber(monto)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '($cantidad)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

// ─── VENTAS 7 DIAS CHART ──────────────────────────────────────────

class _VentasSemanaChart extends StatelessWidget {
  final List<VentaDia> ventas;
  const _VentasSemanaChart({required this.ventas});

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) return const SizedBox.shrink();

    final maxMonto = ventas.fold<double>(
      0,
      (prev, e) => e.monto > prev ? e.monto : prev,
    );

    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.2),
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFF5F9FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 18, color: AppColors.blue2),
              const SizedBox(width: 8),
              const AppSubtitle('Ventas ultimos 7 dias', fontSize: 13),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ventas.map((v) {
                final fraction =
                    maxMonto > 0 ? (v.monto / maxMonto).clamp(0.0, 1.0) : 0.0;
                final barHeight = 100.0 * fraction;
                final shortDate = _shortDate(v.fecha);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          v.cantidad.toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: barHeight.clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.blue2,
                                AppColors.blue2.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortDate,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String fecha) {
    // La fecha viene como "2026-04-02T05:00:00.000Z" (medianoche Peru en UTC)
    // Extraer solo la parte yyyy-MM-dd y formatear sin conversión timezone
    final dateOnly = fecha.contains('T') ? fecha.split('T').first : fecha;
    final parts = dateOnly.split('-');
    if (parts.length >= 3) {
      return '${parts[2]}/${parts[1]}'; // dd/MM
    }
    return dateOnly;
  }
}

// ─── METODOS DE PAGO ──────────────────────────────────────────────

class _MetodosPagoChart extends StatelessWidget {
  final Map<String, double> metodos;
  const _MetodosPagoChart({required this.metodos});

  static const _methodColors = <String, Color>{
    'EFECTIVO': Color(0xFF4CAF50),
    'TARJETA': Color(0xFF2196F3),
    'TRANSFERENCIA': Color(0xFF9C27B0),
    'YAPE': Color(0xFF7B1FA2),
    'PLIN': Color(0xFF00897B),
    'CREDITO': Color(0xFFFF9800),
  };

  @override
  Widget build(BuildContext context) {
    if (metodos.isEmpty) return const SizedBox.shrink();

    final maxVal = metodos.values.fold<double>(
      0,
      (prev, e) => e > prev ? e : prev,
    );

    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.2),
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFF5F9FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, size: 18, color: AppColors.blue2),
              const SizedBox(width: 8),
              const AppSubtitle('Metodos de Pago', fontSize: 13),
            ],
          ),
          const SizedBox(height: 12),
          ...metodos.entries.map((entry) {
            final fraction =
                maxVal > 0 ? (entry.value / maxVal).clamp(0.0, 1.0) : 0.0;
            final color = _methodColors[entry.key.toUpperCase()] ??
                AppColors.blue2;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 14,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'S/ ${_formatNumber(entry.value)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── TOP LIST ─────────────────────────────────────────────────────

class _TopList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<TopItem> items;
  final String unitLabel;

  const _TopList({
    required this.title,
    required this.icon,
    required this.items,
    required this.unitLabel,
  });

  Color _medalColor(int index) {
    if (index == 0) return const Color(0xFFFFD700);
    if (index == 1) return const Color(0xFFC0C0C0);
    if (index == 2) return const Color(0xFFCD7F32);
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(5).toList();

    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.2),
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFF5F9FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.blue2),
              const SizedBox(width: 8),
              AppSubtitle(title, fontSize: 13),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(displayItems.length, (i) {
            final item = displayItems[i];
            final medalColor = _medalColor(i);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: medalColor.withValues(alpha: i < 3 ? 0.15 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: medalColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nombre,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.cantidad} $unitLabel',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'S/ ${_formatNumber(item.monto)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue2,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────

String _formatNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(2);
}
