import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
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
      body: BlocBuilder<TesoreriaCubit, TesoreriaState>(
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
      floatingActionButton: BlocBuilder<TesoreriaCubit, TesoreriaState>(
        builder: (context, state) {
          if (state is! TesoreriaLoaded) return const SizedBox();
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
                child: Text(
                  '${state.movimientos.items.length} de ${state.movimientos.total} movimientos',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final TesoreriaResumen resumen;

  const _HeaderCard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
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
                  color: AppColors.white, size: 22),
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
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      resumen.caja.codigo,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                child: _SaldoColumn(
                  label: 'Digital',
                  icon: Icons.phone_android_rounded,
                  monto: resumen.saldoDigital,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _money(resumen.saldoTotal),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
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
                fontSize: 12,
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
            fontSize: 18,
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

class _FiltrosBar extends StatelessWidget {
  final TesoreriaMovimientosFilter filter;
  final ValueChanged<TesoreriaMovimientosFilter> onChanged;

  const _FiltrosBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.blue1 : AppColors.textSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
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
        // Solo los depositos del barrido linkean a la auditoria de la
        // caja origen (cajaEspejoId esta en la metadata del INGRESO
        // espejo en la central). El resto no tiene destino natural.
        VoidCallback? onTap;
        if (g.kind == TesoreriaGroupKind.barridoCierre) {
          final cajaId =
              g.items.first.metadata?['cajaEspejoId'] as String?;
          if (cajaId != null) {
            onTap = () =>
                context.push('/empresa/caja/auditoria/$cajaId');
          }
        }
        return TesoreriaGroupCard(group: g, onTap: onTap);
      },
    );
  }
}
