import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/incidencia.dart';
import '../../domain/entities/empleado.dart';
import '../bloc/incidencia/incidencia_cubit.dart';
import '../bloc/incidencia/incidencia_state.dart';
import '../bloc/empleado_list/empleado_list_cubit.dart';
import '../bloc/empleado_list/empleado_list_state.dart';

class IncidenciasPage extends StatefulWidget {
  const IncidenciasPage({super.key});

  @override
  State<IncidenciasPage> createState() => _IncidenciasPageState();
}

class _IncidenciasPageState extends State<IncidenciasPage> {
  late final IncidenciaCubit _cubit;
  String? _selectedTipo;
  String? _selectedEstado;

  static const _tipoFilters = <String?, String>{
    null: 'Todos',
    'VACACION': 'Vacacion',
    'LICENCIA_MEDICA': 'Lic. Medica',
    'PERMISO': 'Permiso',
    'DESCANSO_MEDICO': 'Desc. Medico',
    'OTRO': 'Otro',
  };

  static const _estadoFilters = <String?, String>{
    null: 'Todos',
    'PENDIENTE': 'Pendiente',
    'APROBADA': 'Aprobada',
    'RECHAZADA': 'Rechazada',
  };

  @override
  void initState() {
    super.initState();
    _cubit = locator<IncidenciaCubit>();
    _cubit.loadIncidencias();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _applyFilters() {
    final params = <String, dynamic>{};
    if (_selectedTipo != null) params['tipo'] = _selectedTipo!;
    if (_selectedEstado != null) params['estado'] = _selectedEstado!;
    _cubit.loadIncidencias(queryParams: params.isNotEmpty ? params : null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Incidencias',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () => _showCreateDialog(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GradientContainer(
          child: Column(
            children: [
              // Type filter
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: _tipoFilters.entries.map((entry) {
                    final isSelected = _selectedTipo == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.blue1,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        onSelected: (_) {
                          setState(() => _selectedTipo = entry.key);
                          _applyFilters();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Estado filter
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _estadoFilters.entries.map((entry) {
                    final isSelected = _selectedEstado == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.orange,
                        backgroundColor: Colors.white,
                        onSelected: (_) {
                          setState(() => _selectedEstado = entry.key);
                          _applyFilters();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),

              // List
              Expanded(
                child: BlocConsumer<IncidenciaCubit, IncidenciaState>(
                  listener: (context, state) {
                    if (state is IncidenciaActionSuccess) {
                      SnackBarHelper.showSuccess(context, state.message);
                    }
                    if (state is IncidenciaError) {
                      SnackBarHelper.showError(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is IncidenciaLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is IncidenciaListLoaded) {
                      if (state.incidencias.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 56,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin incidencias',
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
                        onRefresh: () async => await _cubit.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.incidencias.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildIncidenciaCard(
                                context, state.incidencias[index]);
                          },
                        ),
                      );
                    }

                    if (state is IncidenciaError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                            const SizedBox(height: 12),
                            Text(state.message,
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidenciaCard(BuildContext context, Incidencia incidencia) {
    return GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: incidencia.tipo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconForTipo(incidencia.tipo),
                  size: 18,
                  color: incidencia.tipo.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incidencia.empleadoNombre ?? 'Empleado',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      incidencia.tipo.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: incidencia.tipo.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Estado badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: incidencia.estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  incidencia.estado.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: incidencia.estado.color,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Date range
          Row(
            children: [
              const Icon(Icons.date_range, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${DateFormatter.formatDate(incidencia.fechaInicio)} - ${DateFormatter.formatDate(incidencia.fechaFin)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${incidencia.diasTotal} dia${incidencia.diasTotal > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),

          if (incidencia.motivo != null && incidencia.motivo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              incidencia.motivo!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Action buttons for PENDIENTE
          if (incidencia.estaPendiente) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.red),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(fontSize: 12, color: AppColors.red),
                  ),
                  onPressed: () =>
                      _showRejectDialog(context, incidencia),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aprobar', style: TextStyle(fontSize: 12)),
                  onPressed: () => _cubit.aprobar(incidencia.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForTipo(TipoIncidencia tipo) {
    switch (tipo) {
      case TipoIncidencia.vacacion:
        return Icons.beach_access;
      case TipoIncidencia.licenciaMedica:
        return Icons.local_hospital;
      case TipoIncidencia.permiso:
        return Icons.event_available;
      case TipoIncidencia.descansoMedico:
        return Icons.medical_services;
      case TipoIncidencia.licenciaPaternidad:
        return Icons.child_friendly;
      case TipoIncidencia.licenciaMaternidad:
        return Icons.pregnant_woman;
      case TipoIncidencia.otro:
        return Icons.more_horiz;
    }
  }

  void _showRejectDialog(BuildContext context, Incidencia incidencia) {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Incidencia'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _cubit.rechazar(incidencia.id, motivoCtrl.text.trim());
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final empleadoListCubit = locator<EmpleadoListCubit>();
    empleadoListCubit.loadEmpleados(estado: 'ACTIVO');

    Empleado? selectedEmpleado;
    TipoIncidencia selectedTipo = TipoIncidencia.vacacion;
    DateTime fechaInicio = DateTime.now();
    DateTime fechaFin = DateTime.now().add(const Duration(days: 1));
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return BlocProvider.value(
              value: empleadoListCubit,
              child: AlertDialog(
                title: const Text('Nueva Incidencia'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Empleado selector
                      BlocBuilder<EmpleadoListCubit, EmpleadoListState>(
                        builder: (context, state) {
                          if (state is EmpleadoListLoaded) {
                            return DropdownButtonFormField<Empleado>(
                              value: selectedEmpleado,
                              decoration: const InputDecoration(
                                labelText: 'Empleado',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              isExpanded: true,
                              items: state.empleados.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.nombreCompleto,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setDialogState(() => selectedEmpleado = v);
                              },
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Tipo
                      DropdownButtonFormField<TipoIncidencia>(
                        value: selectedTipo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: TipoIncidencia.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.label, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedTipo = v);
                        },
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: fechaInicio,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) {
                                  setDialogState(() => fechaInicio = d);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Desde',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(fechaInicio),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: fechaFin,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) {
                                  setDialogState(() => fechaFin = d);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Hasta',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(fechaFin),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Motivo
                      TextField(
                        controller: motivoCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Motivo',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      empleadoListCubit.close();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (selectedEmpleado == null) {
                        SnackBarHelper.showWarning(ctx, 'Seleccione un empleado');
                        return;
                      }
                      Navigator.of(ctx).pop();
                      empleadoListCubit.close();

                      _cubit.crearIncidencia({
                        'empleadoId': selectedEmpleado!.id,
                        'tipo': selectedTipo.apiValue,
                        'fechaInicio': fechaInicio.toIso8601String(),
                        'fechaFin': fechaFin.toIso8601String(),
                        'motivo': motivoCtrl.text.trim(),
                      });
                    },
                    child: const Text('Crear'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
