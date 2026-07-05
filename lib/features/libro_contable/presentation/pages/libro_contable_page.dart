import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_filter_chip.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
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

  /// Sede seleccionada (null = toda la empresa). Filtro local a la pantalla.
  String? _sedeId;

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
          sedeId: _sedeId,
        );
  }

  void _seleccionarSede(String? sedeId) {
    if (_sedeId == sedeId) return;
    setState(() => _sedeId = sedeId);
    _load();
  }

  Future<void> _exportExcel(BuildContext context) async {
    await locator<ExportService>().exportAndShare(
      context: context,
      endpoint: '/reportes-financieros/export/libro-contable',
      queryParams: {
        'mes': _mesSeleccionado,
        'anio': _anioSeleccionado,
        if (_sedeId != null) 'sedeId': _sedeId,
      },
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
          _buildSedeSelector(),
          _buildMonthYearSelector(),
          const SizedBox(height: 12),
          _buildResumenCard(libro.resumen),
          const SizedBox(height: 12),
          if (libro.movimientos.isEmpty)
            _buildEmptyState()
          else
            _tablaAsientos(libro.movimientos),
        ],
      ),
    );
  }

  // --- SEDE (mismo control segmentado que Resumen Financiero) ---
  Widget _buildSedeSelector() {
    final sedes = context.watch<SedeActivaCubit>().state.operables;
    if (sedes.length < 2) return const SizedBox.shrink();

    final expandir = sedes.length + 1 <= 3;
    final items = [
      _tabSedeItem(
        label: 'Toda la empresa',
        icon: Icons.business,
        selected: _sedeId == null,
        expanded: expandir,
        onTap: () => _seleccionarSede(null),
      ),
      ...sedes.map((s) => _tabSedeItem(
            label: s.nombre,
            icon: Icons.store,
            selected: _sedeId == s.id,
            expanded: expandir,
            onTap: () => _seleccionarSede(s.id),
          )),
    ];

    final control = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );

    if (expandir) return control;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: control,
    );
  }

  Widget _tabSedeItem({
    required String label,
    required IconData icon,
    required bool selected,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    final item = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 7, horizontal: expanded ? 0 : 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14, color: selected ? AppColors.blue1 : Colors.grey.shade500),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.blue1 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? Expanded(child: item) : item;
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
                child: CustomFilterChip(
                  label: _meses[index],
                  selected: isSelected,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  onSelected: () {
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

    return SizedBox(
      width: 95,
      child: CustomDropdown<int>(
        value: _anioSeleccionado,
        borderColor: AppColors.blue1,
        items: years
            .map((y) => DropdownItem(value: y, label: '$y'))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _anioSeleccionado = val);
            _load();
          }
        },
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

  // ── Tabla estilo Excel del libro: Fecha | Concepto | Ingreso | Egreso |
  // Saldo acumulado (formato clásico de libro contable). ─────────────────

  static final _thStyle = TextStyle(
      fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700);
  static final _tdStyle =
      TextStyle(fontSize: 9.5, color: Colors.grey.shade700);
  static final _tdVerde = TextStyle(
      fontSize: 9.5, color: Colors.green.shade700, fontWeight: FontWeight.w600);
  static final _tdRojo = TextStyle(
      fontSize: 9.5, color: Colors.red.shade700, fontWeight: FontWeight.w600);
  static final _tdBold = TextStyle(
      fontSize: 9.5, color: Colors.grey.shade900, fontWeight: FontWeight.w700);
  static final _tdTiny = TextStyle(fontSize: 8, color: Colors.grey.shade500);

  Widget _celda(String text, TextStyle style,
      {TextAlign align = TextAlign.left, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Text(text,
          style: style,
          textAlign: align,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis),
    );
  }

  /// Etiqueta corta y legible de la categoría del asiento.
  String _labelCategoria(String? cat) {
    if (cat == null) return '';
    const labels = {
      'VENTA': 'Venta',
      'COMPRA': 'Compra',
      'PAGO_PRESTAMO': 'Pago préstamo',
      'GASTO_RECURRENTE_BANCO': 'Gasto recurrente (banco)',
    };
    if (labels.containsKey(cat)) return labels[cat]!;
    // Categorías de caja llegan como CAJA_<CATEGORIA>.
    return cat
        .replaceFirst('CAJA_', '')
        .replaceAll('_', ' ')
        .toLowerCase();
  }

  Widget _tablaAsientos(List<MovimientoContable> movimientos) {
    final fmtDia = DateFormat('dd/MM');
    final rows = <TableRow>[
      TableRow(
        decoration:
            BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07)),
        children: [
          _celda('Fecha', _thStyle),
          _celda('Concepto', _thStyle),
          _celda('Ingreso', _thStyle, align: TextAlign.right),
          _celda('Egreso', _thStyle, align: TextAlign.right),
          _celda('Saldo', _thStyle, align: TextAlign.right),
        ],
      ),
    ];

    for (var i = 0; i < movimientos.length; i++) {
      final m = movimientos[i];
      final esIngreso = m.tipo.toUpperCase() == 'INGRESO';
      rows.add(TableRow(
        decoration: BoxDecoration(
          color: i.isOdd ? Colors.grey.withValues(alpha: 0.04) : Colors.white,
        ),
        children: [
          _celda(m.fecha != null ? fmtDia.format(m.fecha!.toLocal()) : '—',
              _tdStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.descripcion,
                    style: _tdStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(_labelCategoria(m.categoria),
                    style: _tdTiny,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _celda(esIngreso ? m.monto.toStringAsFixed(2) : '',
              _tdVerde, align: TextAlign.right),
          _celda(esIngreso ? '' : m.monto.toStringAsFixed(2),
              _tdRojo, align: TextAlign.right),
          _celda(
              m.saldoAcumulado != null
                  ? m.saldoAcumulado!.toStringAsFixed(2)
                  : '—',
              (m.saldoAcumulado ?? 0) >= 0 ? _tdBold : _tdRojo,
              align: TextAlign.right),
        ],
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: Colors.white,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
          columnWidths: const {
            0: FlexColumnWidth(0.62),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(0.95),
            3: FlexColumnWidth(0.95),
            4: FlexColumnWidth(1.0),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
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
