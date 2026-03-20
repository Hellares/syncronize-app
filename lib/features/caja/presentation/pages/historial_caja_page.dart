import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/caja.dart';
import '../bloc/caja_historial_cubit.dart';
import '../bloc/caja_historial_state.dart';

class HistorialCajaPage extends StatefulWidget {
  const HistorialCajaPage({super.key});

  @override
  State<HistorialCajaPage> createState() => _HistorialCajaPageState();
}

class _HistorialCajaPageState extends State<HistorialCajaPage> {
  late final CajaHistorialCubit _historialCubit;
  String? _selectedSedeId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _historialCubit = locator<CajaHistorialCubit>();
    _historialCubit.loadHistorial();
  }

  @override
  void dispose() {
    _historialCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return BlocProvider.value(
      value: _historialCubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Historial de Cajas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showFilterSheet(context, sedes),
            ),
          ],
        ),
        body: GradientContainer(
          child: BlocBuilder<CajaHistorialCubit, CajaHistorialState>(
            builder: (context, state) {
              if (state is CajaHistorialLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CajaHistorialError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.red),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (state is CajaHistorialLoaded) {
                if (state.cajas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale_rounded,
                          size: 56,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin historial de cajas',
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
                    await _historialCubit.reload();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.cajas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCajaHistorialCard(state.cajas[index]);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCajaHistorialCard(Caja caja) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      caja.codigo,
                      fontSize: 15,
                      color: AppColors.blue3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caja.sedeNombre ?? 'Sede',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: caja.estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  caja.estado.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: caja.estado.color,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Info rows
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.person_rounded,
                  'Cajero',
                  caja.usuarioNombre ?? '-',
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.attach_money_rounded,
                  'Apertura',
                  currencyFormat.format(caja.montoApertura),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.play_arrow_rounded,
                  'Abierta',
                  DateFormatter.formatDateTime(caja.fechaApertura),
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.stop_rounded,
                  'Cerrada',
                  caja.fechaCierre != null
                      ? DateFormatter.formatDateTime(caja.fechaCierre!)
                      : '-',
                ),
              ),
            ],
          ),
          // Observaciones
          if (caja.observaciones != null &&
              caja.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caja.observaciones!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, List<dynamic> sedes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle(
                    'Filtros',
                    fontSize: 18,
                    color: AppColors.blue3,
                  ),
                  const SizedBox(height: 16),
                  // Sede filter
                  DropdownButtonFormField<String>(
                    value: _selectedSedeId,
                    decoration: InputDecoration(
                      labelText: 'Sede',
                      prefixIcon: const Icon(Icons.store_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Todas',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      ...sedes.map(
                        (sede) => DropdownMenuItem<String>(
                          value: sede.id,
                          child: Text(
                            sede.nombre,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _selectedSedeId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date range picker
                  InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                      );
                      if (range != null) {
                        setSheetState(() => _dateRange = range);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Rango de Fechas',
                        prefixIcon: const Icon(Icons.date_range_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _dateRange != null
                            ? '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'
                            : 'Seleccionar fechas',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dateRange != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedSedeId = null;
                              _dateRange = null;
                            });
                            setState(() {});
                            _historialCubit.loadHistorial();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: () {
                            setState(() {});
                            _historialCubit.loadHistorial(
                              sedeId: _selectedSedeId,
                              fechaDesde: _dateRange?.start
                                  .toIso8601String(),
                              fechaHasta: _dateRange?.end
                                  .toIso8601String(),
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
