import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';

class LibroContablePage extends StatefulWidget {
  const LibroContablePage({super.key});

  @override
  State<LibroContablePage> createState() => _LibroContablePageState();
}

class _LibroContablePageState extends State<LibroContablePage> {
  List<dynamic> _movimientos = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
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

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dio = locator<DioClient>();
      final response = await dio.get(
        '/libro-contable',
        queryParameters: {
          'mes': _mesSeleccionado,
          'anio': _anioSeleccionado,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _movimientos = data['movimientos'] as List<dynamic>? ?? [];
          _resumen = data['resumen'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Libro Contable',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildMonthYearSelector(),
                    const SizedBox(height: 12),
                    if (_resumen != null) _buildResumenCard(),
                    const SizedBox(height: 12),
                    if (_movimientos.isEmpty)
                      _buildEmptyState()
                    else
                      ..._buildGroupedMovements(),
                  ],
                ),
              ),
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

  Widget _buildResumenCard() {
    final ingresos = double.tryParse(_resumen!['totalIngresos']?.toString() ?? '') ?? 0;
    final egresos = double.tryParse(_resumen!['totalEgresos']?.toString() ?? '') ?? 0;
    final saldo = double.tryParse(_resumen!['saldo']?.toString() ?? '') ?? 0;

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

  List<Widget> _buildGroupedMovements() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final m in _movimientos) {
      final mov = m as Map<String, dynamic>;
      final fechaRaw = mov['fecha']?.toString() ?? '';
      final fecha = DateTime.tryParse(fechaRaw);
      final key = fecha != null
          ? DateFormat('dd/MM/yyyy').format(fecha)
          : fechaRaw;

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
  final Map<String, dynamic> movimiento;
  const _MovimientoCard({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final tipo = movimiento['tipo']?.toString() ?? '';
    final descripcion = movimiento['descripcion']?.toString() ?? '';
    final categoria = movimiento['categoria']?.toString() ?? '';
    final referencia = movimiento['referencia']?.toString() ?? '';
    final monto = double.tryParse(movimiento['monto']?.toString() ?? '') ?? 0;
    final saldoAcumulado = double.tryParse(movimiento['saldoAcumulado']?.toString() ?? '') ?? 0;

    final isIngreso = tipo.toUpperCase() == 'INGRESO';
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
                    descripcion,
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
                      if (categoria.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoria,
                            style: const TextStyle(fontSize: 9, color: AppColors.blue1),
                          ),
                        ),
                      if (referencia.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            referencia,
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
                  '$signo S/ ${monto.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saldo: S/ ${saldoAcumulado.toStringAsFixed(2)}',
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
