import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/meta_financiera.dart';
import '../bloc/meta_financiera_cubit.dart';
import '../bloc/meta_financiera_state.dart';

class MetasFinancierasPage extends StatelessWidget {
  const MetasFinancierasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<MetaFinancieraCubit>()..loadMetas(),
      child: const _MetasFinancierasView(),
    );
  }
}

class _MetasFinancierasView extends StatelessWidget {
  const _MetasFinancierasView();

  static const Map<String, Color> _tipoColors = {
    'VENTAS': Color(0xFF1976D2),
    'INGRESOS': Color(0xFF388E3C),
    'AHORRO': Color(0xFF7B1FA2),
    'REDUCCION_GASTOS': Color(0xFFE65100),
  };

  static const Map<String, String> _tipoLabels = {
    'VENTAS': 'Ventas',
    'INGRESOS': 'Ingresos',
    'AHORRO': 'Ahorro',
    'REDUCCION_GASTOS': 'Reduccion Gastos',
  };


  void _showCreateDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    String tipoSeleccionado = 'VENTAS';
    DateTime fechaInicio = DateTime.now();
    DateTime fechaFin = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Nueva Meta Financiera',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.blue3),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo de meta', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _tipoLabels.entries.map((entry) {
                        final isSelected = tipoSeleccionado == entry.key;
                        final color = _tipoColors[entry.key] ?? AppColors.blue1;
                        return ChoiceChip(
                          label: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: color.withValues(alpha: 0.08),
                          side: BorderSide(color: isSelected ? color : color.withValues(alpha: 0.3)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setDialogState(() => tipoSeleccionado = entry.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la meta',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto meta (S/)',
                        labelStyle: const TextStyle(fontSize: 12),
                        prefixText: 'S/ ',
                        prefixStyle: const TextStyle(fontSize: 13, color: AppColors.blue3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Text('Periodo', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: 'Inicio',
                            date: fechaInicio,
                            onPicked: (d) => setDialogState(() => fechaInicio = d),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                        ),
                        Expanded(
                          child: _DatePickerField(
                            label: 'Fin',
                            date: fechaFin,
                            onPicked: (d) => setDialogState(() => fechaFin = d),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
                CustomButton(
                  text: 'Crear Meta',
                  backgroundColor: AppColors.blue1,
                  textColor: Colors.white,
                  height: 34,
                  width: 100,
                  fontSize: 11,
                  onPressed: () {
                    final nombre = nombreCtrl.text.trim();
                    final monto = double.tryParse(montoCtrl.text.trim()) ?? 0;
                    if (nombre.isEmpty || monto <= 0) return;
                    Navigator.pop(ctx);
                    context.read<MetaFinancieraCubit>().crearMeta(
                      tipo: tipoSeleccionado,
                      nombre: nombre,
                      montoMeta: monto,
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Metas Financieras',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocBuilder<MetaFinancieraCubit, MetaFinancieraState>(
          builder: (context, state) {
            if (state is MetaFinancieraLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MetaFinancieraError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              );
            }
            if (state is MetaFinancieraLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<MetaFinancieraCubit>().loadMetas(),
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildResumenCards(state.metas),
                    const SizedBox(height: 12),
                    if (state.metas.isEmpty)
                      _buildEmptyState()
                    else
                      ...state.metas.map((m) => _MetaCard(meta: m)),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue1,
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildResumenCards(List<MetaFinanciera> metas) {
    final cumplidas = metas.where((m) => m.porcentaje >= 100).length;
    final pendientes = metas.length - cumplidas;

    return Row(
      children: [
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.greenBorder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, size: 24, color: AppColors.green),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$cumplidas',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  Text(
                    'Cumplidas',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pending_actions, size: 24, color: AppColors.orange),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$pendientes',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  Text(
                    'Pendientes',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No tienes metas financieras',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Crea tu primera meta para empezar a hacer seguimiento',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final MetaFinanciera meta;
  const _MetaCard({required this.meta});

  static const Map<String, Color> _tipoColors = {
    'VENTAS': Color(0xFF1976D2),
    'INGRESOS': Color(0xFF388E3C),
    'AHORRO': Color(0xFF7B1FA2),
    'REDUCCION_GASTOS': Color(0xFFE65100),
  };

  static const Map<String, String> _tipoLabels = {
    'VENTAS': 'Ventas',
    'INGRESOS': 'Ingresos',
    'AHORRO': 'Ahorro',
    'REDUCCION_GASTOS': 'Reduccion Gastos',
  };

  static const Map<String, IconData> _tipoIcons = {
    'VENTAS': Icons.point_of_sale,
    'INGRESOS': Icons.trending_up,
    'AHORRO': Icons.savings,
    'REDUCCION_GASTOS': Icons.trending_down,
  };

  @override
  Widget build(BuildContext context) {
    final tipoColor = _tipoColors[meta.tipo] ?? AppColors.blue1;
    final tipoLabel = _tipoLabels[meta.tipo] ?? meta.tipo;
    final tipoIcon = _tipoIcons[meta.tipo] ?? Icons.flag;

    final now = DateTime.now();
    final isCumplida = meta.cumplida;
    final isVencida = meta.fechaFin != null && meta.fechaFin!.isBefore(now) && !isCumplida;
    final isCerca = meta.porcentaje >= 75 && meta.porcentaje < 100;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isCumplida) {
      statusColor = AppColors.green;
      statusIcon = Icons.check_circle;
      statusLabel = 'Cumplida';
    } else if (isVencida) {
      statusColor = AppColors.red;
      statusIcon = Icons.cancel;
      statusLabel = 'Vencida';
    } else if (isCerca) {
      statusColor = AppColors.orange;
      statusIcon = Icons.warning_amber;
      statusLabel = 'Cerca';
    } else {
      statusColor = AppColors.blue1;
      statusIcon = Icons.pending;
      statusLabel = 'En progreso';
    }

    final progressColor = isCumplida
        ? AppColors.green
        : isVencida
            ? AppColors.red
            : tipoColor;

    final diferencia = meta.diferencia ?? 0;

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: isCumplida
          ? AppColors.greenBorder
          : isVencida
              ? Colors.red.shade300
              : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tipoIcon, size: 18, color: tipoColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tipoColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tipoLabel,
                          style: TextStyle(fontSize: 9, color: tipoColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (meta.porcentaje / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'S/ ${meta.montoActual.toStringAsFixed(2)} / S/ ${meta.montoMeta.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                Text(
                  '${meta.porcentaje.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            if (diferencia != 0) ...[
              const SizedBox(height: 4),
              Text(
                isCumplida
                    ? 'Superada por S/ ${diferencia.abs().toStringAsFixed(2)}'
                    : 'Faltan S/ ${diferencia.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isCumplida ? AppColors.green : Colors.grey.shade500,
                ),
              ),
            ],
            if (meta.fechaInicio != null && meta.fechaFin != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.date_range, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormatter.formatDate(meta.fechaInicio!)} - ${DateFormatter.formatDate(meta.fechaFin!)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  if (isVencida) ...[
                    const Spacer(),
                    Text(
                      'Finalizada',
                      style: TextStyle(fontSize: 9, color: AppColors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            const SizedBox(height: 2),
            Text(
              DateFormatter.formatDate(date),
              style: const TextStyle(fontSize: 12, color: AppColors.blue3),
            ),
          ],
        ),
      ),
    );
  }
}
