import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/libro_contable.dart';
import '../bloc/libro_contable_cubit.dart';
import '../bloc/libro_contable_state.dart';

class LibroContablePage extends StatelessWidget {
  const LibroContablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<LibroContableCubit>(),
      child: const _LibroContableView(),
    );
  }
}

class _LibroContableView extends StatefulWidget {
  const _LibroContableView();

  @override
  State<_LibroContableView> createState() => _LibroContableViewState();
}

class _LibroContableViewState extends State<_LibroContableView> {
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;

  final List<String> _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<LibroContableCubit>().loadLibro(
          mes: _mesSeleccionado,
          anio: _anioSeleccionado,
        );
  }

  Future<void> _exportExcel(BuildContext context) async {
    await locator<ExportService>().exportAndShare(
      context: context,
      endpoint: '/reportes-financieros/export/libro-contable',
      queryParams: {'mes': _mesSeleccionado, 'anio': _anioSeleccionado},
      fileName: 'libro_contable_${_mesSeleccionado}_$_anioSeleccionado.xlsx',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Libro Contable',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Exportar Excel',
            onPressed: () => _exportExcel(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocBuilder<LibroContableCubit, LibroContableState>(
          builder: (context, state) {
            if (state is LibroContableLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LibroContableError) {
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
            if (state is LibroContableLoaded) {
              return _buildContent(state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(LibroContableLoaded state) {
    final libro = state.libro;

    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildMonthYearSelector(),
          const SizedBox(height: 12),
          _buildResumenCard(libro.resumen),
          const SizedBox(height: 12),
          if (libro.movimientos.isEmpty)
            _buildEmptyState()
          else
            ..._buildGroupedMovements(libro.movimientos),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppSubtitle('Periodo:', fontSize: 13),
            const Spacer(),
            _buildYearSelector(),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              final mes = index + 1;
              final isSelected = mes == _mesSeleccionado;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    _meses[index],
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() => _mesSeleccionado = mes);
                    _load();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 2 + i);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.blueborder),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _anioSeleccionado,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: AppColors.blue3),
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.blue1),
          items: years.map((y) => DropdownMenuItem(
            value: y,
            child: Text('$y'),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _anioSeleccionado = val);
              _load();
            }
          },
        ),
      ),
    );
  }

  Widget _buildResumenCard(ResumenContable resumen) {
    final ingresos = resumen.totalIngresos;
    final egresos = resumen.totalEgresos;
    final saldo = resumen.saldoFinal;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Ingresos',
                    monto: ingresos,
                    color: AppColors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryItem(
                    label: 'Egresos',
                    monto: egresos,
                    color: AppColors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (saldo >= 0 ? AppColors.blue1 : AppColors.red).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppSubtitle('Saldo del periodo', fontSize: 13),
                  AppSubtitle(
                    'S/ ${saldo.toStringAsFixed(2)}',
                    fontSize: 16,
                    color: saldo >= 0 ? AppColors.blue1 : AppColors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedMovements(List<MovimientoContable> movimientos) {
    final Map<String, List<MovimientoContable>> grouped = {};

    for (final mov in movimientos) {
      final key = mov.fecha != null
          ? DateFormatter.formatDate(mov.fecha!)
          : '';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(mov);
    }

    final widgets = <Widget>[];
    grouped.forEach((fecha, movs) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                fecha,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
        ),
      );

      for (final mov in movs) {
        widgets.add(_MovimientoCard(movimiento: mov));
      }
    });

    return widgets;
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No hay movimientos en este periodo',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.monto,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'S/ ${monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final MovimientoContable movimiento;
  const _MovimientoCard({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final isIngreso = movimiento.tipo.toUpperCase() == 'INGRESO';
    final color = isIngreso ? AppColors.green : AppColors.red;
    final icon = isIngreso ? Icons.arrow_upward : Icons.arrow_downward;
    final signo = isIngreso ? '+' : '-';

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 6),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimiento.descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (movimiento.categoria != null && movimiento.categoria!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            movimiento.categoria!,
                            style: const TextStyle(fontSize: 9, color: AppColors.blue1),
                          ),
                        ),
                      if (movimiento.referencia != null && movimiento.referencia!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            movimiento.referencia!,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$signo S/ ${movimiento.monto.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                if (movimiento.saldoAcumulado != null)
                  Text(
                    'Saldo: S/ ${movimiento.saldoAcumulado!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
