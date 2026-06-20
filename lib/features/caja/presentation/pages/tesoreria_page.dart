import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/tesoreria.dart';
import '../bloc/tesoreria_cubit.dart';
import '../bloc/tesoreria_state.dart';
import '../utils/tesoreria_grouping.dart';
import '../widgets/ajuste_tesoreria_dialog.dart';
import '../widgets/tesoreria_group_card.dart';

String _money(double v) => 'S/ ${v.toStringAsFixed(2)}';

/// Pantalla de Caja Central (Tesoreria) de una sede.
///
/// Muestra el saldo (efectivo + digital separados), los movimientos paginados
/// con filtros, y permite crear ajustes manuales (admin/gerente). Acumula:
///   - Barrido al cerrar cajas operativas (categoria DEPOSITO_TESORERIA).
///   - Egresos por reverso de cajas cerradas (REVERSO_CAJA_CERRADA).
///   - Ajustes manuales del admin (AJUSTE_TESORERIA).
class TesoreriaPage extends StatelessWidget {
  final String sedeId;

  const TesoreriaPage({super.key, required this.sedeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<TesoreriaCubit>()..load(sedeId),
      child: const _TesoreriaView(),
    );
  }
}

class _TesoreriaView extends StatelessWidget {
  const _TesoreriaView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: SmartAppBar(
        title: 'Tesorería',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        actions: [
          BlocBuilder<TesoreriaCubit, TesoreriaState>(
            builder: (context, state) {
              if (state is! TesoreriaLoaded) return const SizedBox();
              return IconButton(
                tooltip: 'Refrescar',
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<TesoreriaCubit>().refresh(),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TesoreriaCubit, TesoreriaState>(
        listenWhen: (prev, curr) =>
            curr is TesoreriaLoaded && curr.errorMessage != null,
        listener: (context, state) {
          final msg = (state as TesoreriaLoaded).errorMessage;
          if (msg == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.red,
            ));
        },
        builder: (context, state) {
          if (state is TesoreriaLoading || state is TesoreriaInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TesoreriaError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      onPressed: () =>
                          context.read<TesoreriaCubit>().refresh(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is TesoreriaLoaded) {
            return _Loaded(state: state);
          }
          return const SizedBox();
        },
      ),
      // El backend exige MANAGE_CAJA para crear ajustes: sin el permiso
      // el FAB se oculta (antes se mostraba y recién fallaba el submit).
      floatingActionButton: BlocBuilder<TesoreriaCubit, TesoreriaState>(
        builder: (context, state) {
          if (state is! TesoreriaLoaded) return const SizedBox();
          final empresaState = context.watch<EmpresaContextCubit>().state;
          final puedeAjustar = empresaState is EmpresaContextLoaded &&
              ((empresaState.context.primaryRole?.isAdminRole ?? false) ||
                  empresaState.context.permissions.canManageCaja);
          if (!puedeAjustar) return const SizedBox();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Ajuste manual'),
            onPressed: () async {
              final cubit = context.read<TesoreriaCubit>();
              await showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: const AjusteTesoreriaDialog(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final TesoreriaLoaded state;

  const _Loaded({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TesoreriaCubit>().refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Scroll infinito: pide la siguiente página al acercarse al
          // final. El cubit ya ignora llamadas repetidas (loadingMore).
          if (state.hasMore &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
            context.read<TesoreriaCubit>().loadMore();
          }
          return false;
        },
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeaderCard(resumen: state.resumen)),
          SliverToBoxAdapter(
            child: _FiltrosBar(
              filter: state.filter,
              onChanged: (f) =>
                  context.read<TesoreriaCubit>().applyFilter(f),
            ),
          ),
          if (state.refreshingMovimientos)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.blue1,
              ),
            ),
          if (state.movimientos.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No hay movimientos con los filtros actuales.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            _GroupedList(items: state.movimientos.items),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: state.loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        state.hasMore
                            ? '${state.movimientos.items.length} de ${state.movimientos.total} movimientos · desliza para cargar más'
                            : '${state.movimientos.items.length} de ${state.movimientos.total} movimientos',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatefulWidget {
  final TesoreriaResumen resumen;

  const _HeaderCard({required this.resumen});

  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<_HeaderCard> {
  Map<String, dynamic>? _porMoneda;
  Map<String, dynamic> _porMetodo = {};

  @override
  void initState() {
    super.initState();
    _cargarConsolidado();
  }

  Future<void> _cargarConsolidado() async {
    try {
      final res = await locator<DioClient>().get('/caja/tesoreria-consolidado');
      if (!mounted) return;
      setState(() {
        _porMoneda = (res.data['bancosPorMoneda'] as Map<String, dynamic>?) ?? {};
        _porMetodo = (res.data['recaudadoPorMetodo'] as Map<String, dynamic>?) ?? {};
      });
    } catch (_) {/* deja el total solo-efectivo */}
  }

  @override
  Widget build(BuildContext context) {
    final resumen = widget.resumen;
    final digitalPen = (_porMoneda?['PEN'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue1, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue1.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resumen.sede.nombre,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      resumen.caja.codigo,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SaldoColumn(
                  label: 'Efectivo',
                  icon: Icons.money_rounded,
                  monto: resumen.saldoEfectivo,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: AppColors.white.withValues(alpha: 0.30),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/empresa/tesoreria-consolidado'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_android_rounded, color: AppColors.white.withValues(alpha: 0.85), size: 16),
                            const SizedBox(width: 4),
                            Text('Cobros digitales',
                                style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_money(digitalPen),
                                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            const Icon(Icons.chevron_right, color: AppColors.white, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _TotalConBancos(
              saldoEfectivo: resumen.saldoEfectivo,
              porMoneda: _porMoneda,
              porMetodo: _porMetodo,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Ingresos',
                  monto: resumen.totalIngresos,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Egresos',
                  monto: resumen.totalEgresos,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Movs.',
                  monto: resumen.totalMovimientos.toDouble(),
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Total informativo de tesorería = efectivo (bóveda) + lo que está en los
/// bancos (los cobros digitales). Trae el total de bancos del consolidado.
class _TotalConBancos extends StatefulWidget {
  final double saldoEfectivo;
  final Map<String, dynamic>? porMoneda;
  final Map<String, dynamic> porMetodo;
  const _TotalConBancos({
    required this.saldoEfectivo,
    required this.porMoneda,
    required this.porMetodo,
  });

  @override
  State<_TotalConBancos> createState() => _TotalConBancosState();
}

class _TotalConBancosState extends State<_TotalConBancos> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final pen = (widget.porMoneda?['PEN'] as num?)?.toDouble() ?? 0;
    final usd = (widget.porMoneda?['USD'] as num?)?.toDouble() ?? 0;
    final totalPen = widget.saldoEfectivo + pen;
    final metodos = widget.porMetodo.entries
        .where((e) => ((e.value as num?)?.toDouble() ?? 0).abs() > 0.001)
        .toList()
      ..sort((a, b) => ((b.value as num).toDouble()).compareTo((a.value as num).toDouble()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total (efectivo + bancos)',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 10)),
            Text(_money(totalPen),
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        if (widget.porMoneda != null) ...[
          // const SizedBox(height: 3),
          Text(
            '${_money(widget.saldoEfectivo)} efectivo  +  ${_money(pen)} en bancos',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 10.5),
          ),
          if (usd != 0)
            Text('+ \$ ${usd.toStringAsFixed(2)} en cuentas USD',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 9)),
        ],
        // Flechita expandible: desglose de medios digitales → bancos (chips).
        if (metodos.isNotEmpty) ...[
          // const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(_expandido ? Icons.keyboard_arrow_down : Icons.chevron_right,
                      color: AppColors.white.withValues(alpha: 0.9), size: 16),
                  const SizedBox(width: 2),
                  Text('Medios digitales → bancos',
                      style: TextStyle(color: AppColors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: metodos
                  .map((e) => _chipMetodo(_labelMetodo(e.key), (e.value as num).toDouble()))
                  .toList(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _chipMetodo(String label, double monto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.30)),
      ),
      child: Text('$label  ${_money(monto)}',
          style: const TextStyle(color: AppColors.white, fontSize: 9.5, fontWeight: FontWeight.w600)),
    );
  }

  String _labelMetodo(String m) {
    switch (m.toUpperCase()) {
      case 'YAPE':
        return 'Yape';
      case 'PLIN':
        return 'Plin';
      case 'TARJETA':
        return 'Tarjeta';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'EFECTIVO':
        return 'Efectivo';
      default:
        return m;
    }
  }
}

class _SaldoColumn extends StatelessWidget {
  final String label;
  final IconData icon;
  final double monto;

  const _SaldoColumn({
    required this.label,
    required this.icon,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white.withValues(alpha: 0.85), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _money(monto),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double monto;
  final bool isCount;

  const _MiniStat({
    required this.label,
    required this.monto,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.80),
              fontSize: 10,
            ),
          ),
          Text(
            isCount ? monto.toInt().toString() : _money(monto),

            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosBar extends StatefulWidget {
  final TesoreriaMovimientosFilter filter;
  final ValueChanged<TesoreriaMovimientosFilter> onChanged;

  const _FiltrosBar({required this.filter, required this.onChanged});

  @override
  State<_FiltrosBar> createState() => _FiltrosBarState();
}

class _FiltrosBarState extends State<_FiltrosBar> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  TesoreriaMovimientosFilter get filter => widget.filter;
  ValueChanged<TesoreriaMovimientosFilter> get onChanged => widget.onChanged;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = filter.q ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final q = value.trim();
      if (q == (filter.q ?? '')) return;
      onChanged(q.isEmpty
          ? filter.copyWith(clearQ: true)
          : filter.copyWith(q: q));
    });
  }

  Future<void> _pickRangoFechas() async {
    final now = DateTime.now();
    DateTimeRange? initial;
    if (filter.fechaDesde != null && filter.fechaHasta != null) {
      final d = DateTime.tryParse(filter.fechaDesde!)?.toLocal();
      final h = DateTime.tryParse(filter.fechaHasta!)?.toLocal();
      if (d != null && h != null && !h.isBefore(d)) {
        initial = DateTimeRange(start: d, end: h);
      }
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.blue1),
        ),
        child: child!,
      ),
    );
    if (range == null) return;
    // startOfDay/endOfDay en hora LOCAL → UTC ISO (gotcha timezone:
    // DateTime.utc con componentes locales corre el rango por el offset).
    onChanged(filter.copyWith(
      fechaDesde:
          DateFormatter.toUtcIso(DateFormatter.startOfDay(range.start)),
      fechaHasta: DateFormatter.toUtcIso(DateFormatter.endOfDay(range.end)),
    ));
  }

  String _fechaChipLabel() {
    if (filter.fechaDesde == null) return 'Fechas';
    String dm(String iso) {
      final d = DateTime.tryParse(iso)?.toLocal();
      if (d == null) return '—';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }

    return '${dm(filter.fechaDesde!)} – ${dm(filter.fechaHasta ?? filter.fechaDesde!)}';
  }

  @override
  Widget build(BuildContext context) {
    final fechasActivas = filter.fechaDesde != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            controller: _searchCtrl,
            borderColor: AppColors.blue1,
            label: 'Buscar en descripción',
            onChanged: _onSearchChanged,
            prefixIcon: Icon(Icons.search),
          ),
          const SizedBox(height: 10),
          Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _FechaChip(
            label: _fechaChipLabel(),
            selected: fechasActivas,
            onTap: _pickRangoFechas,
            onClear: fechasActivas
                ? () => onChanged(filter.copyWith(
                      clearFechaDesde: true,
                      clearFechaHasta: true,
                    ))
                : null,
          ),
          _Chip(
            label: 'Todos',
            selected: filter.tipo == null,
            onTap: () => onChanged(filter.copyWith(clearTipo: true)),
          ),
          _Chip(
            label: 'Ingresos',
            selected: filter.tipo == TipoMovimientoCaja.ingreso,
            onTap: () =>
                onChanged(filter.copyWith(tipo: TipoMovimientoCaja.ingreso)),
          ),
          _Chip(
            label: 'Egresos',
            selected: filter.tipo == TipoMovimientoCaja.egreso,
            onTap: () =>
                onChanged(filter.copyWith(tipo: TipoMovimientoCaja.egreso)),
          ),
          _Chip(
            label: 'Solo ajustes',
            selected:
                filter.categoria == CategoriaMovimientoCaja.ajusteTesoreria,
            onTap: () => onChanged(
              filter.categoria == CategoriaMovimientoCaja.ajusteTesoreria
                  ? filter.copyWith(clearCategoria: true)
                  : filter.copyWith(
                      categoria: CategoriaMovimientoCaja.ajusteTesoreria,
                    ),
            ),
          ),
          _Chip(
            label: 'Solo reversos',
            selected:
                filter.categoria == CategoriaMovimientoCaja.reversoCajaCerrada,
            onTap: () => onChanged(
              filter.categoria == CategoriaMovimientoCaja.reversoCajaCerrada
                  ? filter.copyWith(clearCategoria: true)
                  : filter.copyWith(
                      categoria: CategoriaMovimientoCaja.reversoCajaCerrada,
                    ),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip de rango de fechas: tap abre el picker, la X limpia el filtro.
class _FechaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FechaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.blue1 : AppColors.textSecondary,
            width: 0.6
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 12,
              color: selected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.blue1 : AppColors.textSecondary,
            width: 0.6
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<MovimientoCaja> items;

  const _GroupedList({required this.items});

  @override
  Widget build(BuildContext context) {
    final grupos = groupTesoreriaMovimientos(items);
    return SliverList.separated(
      itemCount: grupos.length,
      separatorBuilder: (_, i) => grupos[i].isGrouped
          ? const SizedBox(height: 2)
          : const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, i) {
        final g = grupos[i];
        // Wire-up de navegacion segun tipo de grupo:
        //  - barridoCierre  → auditoria de la caja origen (cajaEspejoId
        //    esta en metadata del INGRESO espejo en la central).
        //  - reversoCajaCerrada → detalle de la venta o devolucion que
        //    se anulo (compras no tienen pantalla de detalle por id aun).
        //  - resto (ajustes manuales, etc.) → sin destino.
        VoidCallback? onTap;
        if (g.kind == TesoreriaGroupKind.cicloCaja) {
          // El cajaEspejoId está en el metadata del depósito si existe,
          // sino en cajaAperturaId del retiro.
          String? cajaId;
          for (final m in g.items) {
            cajaId = (m.metadata?['cajaEspejoId'] ??
                m.metadata?['cajaAperturaId']) as String?;
            if (cajaId != null) break;
          }
          if (cajaId != null) {
            onTap = () =>
                context.push('/empresa/caja/auditoria/$cajaId');
          }
        } else if (g.kind == TesoreriaGroupKind.barridoCierre) {
          final cajaId =
              g.items.first.metadata?['cajaEspejoId'] as String?;
          if (cajaId != null) {
            onTap = () =>
                context.push('/empresa/caja/auditoria/$cajaId');
          }
        } else if (g.kind == TesoreriaGroupKind.reversoCajaCerrada) {
          final first = g.items.first;
          if (first.ventaId != null) {
            onTap = () => context.push('/empresa/ventas/${first.ventaId}');
          } else if (first.devolucionId != null) {
            onTap = () =>
                context.push('/empresa/devoluciones/${first.devolucionId}');
          }
          // Compras: no hay pantalla de detalle por id en GoRouter aun.
        }
        return TesoreriaGroupCard(group: g, onTap: onTap);
      },
    );
  }
}
