import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/horario_plantilla.dart';
import '../../domain/entities/turno.dart';
import '../bloc/horario_list/horario_list_cubit.dart';
import '../bloc/horario_list/horario_list_state.dart';
import '../bloc/turno_list/turno_list_cubit.dart';
import '../bloc/turno_list/turno_list_state.dart';

class HorarioPlantillaPage extends StatefulWidget {
  const HorarioPlantillaPage({super.key});

  @override
  State<HorarioPlantillaPage> createState() => _HorarioPlantillaPageState();
}

class _HorarioPlantillaPageState extends State<HorarioPlantillaPage> {
  late final HorarioListCubit _horarioCubit;
  late final TurnoListCubit _turnoCubit;
  HorarioPlantilla? _selectedHorario;

  @override
  void initState() {
    super.initState();
    _horarioCubit = locator<HorarioListCubit>();
    _turnoCubit = locator<TurnoListCubit>();
    _horarioCubit.loadHorarios();
    _turnoCubit.loadTurnos();
  }

  @override
  void dispose() {
    _horarioCubit.close();
    _turnoCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _horarioCubit),
        BlocProvider.value(value: _turnoCubit),
      ],
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Horarios',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () => _showCreateEditDialog(context, null),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GradientContainer(
          child: BlocConsumer<HorarioListCubit, HorarioListState>(
            listener: (context, state) {
              if (state is HorarioListActionSuccess) {
                SnackBarHelper.showSuccess(context, state.message);
              }
              if (state is HorarioListError) {
                SnackBarHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is HorarioListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is HorarioListLoaded) {
                if (state.horarios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_view_week,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin plantillas de horario',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => await _horarioCubit.loadHorarios(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // List of templates
                      ...state.horarios.map((h) => _buildHorarioCard(context, h)),

                      // Detail view of selected
                      if (_selectedHorario != null) ...[
                        const SizedBox(height: 20),
                        _buildDayGrid(_selectedHorario!),
                      ],
                    ],
                  ),
                );
              }

              if (state is HorarioListError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
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

  Widget _buildHorarioCard(BuildContext context, HorarioPlantilla horario) {
    final isSelected = _selectedHorario?.id == horario.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedHorario = isSelected ? null : horario;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: GradientContainer(
          padding: const EdgeInsets.all(14),
          borderColor: isSelected ? AppColors.blue1 : AppColors.white,
          borderWidth: isSelected ? 1.5 : 0.5,
          child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      horario.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (horario.descripcion != null &&
                        horario.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        horario.descripcion!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMiniChip(
                          '${horario.diasLaborales} laborales',
                          AppColors.blue1,
                        ),
                        const SizedBox(width: 6),
                        _buildMiniChip(
                          '${horario.diasDescanso} descanso',
                          Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: AppColors.blue1),
                onPressed: () => _showCreateEditDialog(context, horario),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
                onPressed: () => _confirmDelete(context, horario),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDayGrid(HorarioPlantilla horario) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle: ${horario.nombre}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.blue3,
            ),
          ),
          const Divider(height: 20),
          ...DiaSemana.values.map((dia) {
            final diaConfig = horario.dias.cast<HorarioPlantillaDia?>().firstWhere(
                  (d) => d!.diaSemana == dia,
                  orElse: () => null,
                );

            final isDescanso = diaConfig == null || diaConfig.esDescanso;
            final horarioLabel = diaConfig?.horarioLabel ?? 'Sin asignar';
            final turnoNombre = diaConfig?.turno?.nombre;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      dia.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDescanso
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDescanso
                            ? Colors.grey.withValues(alpha: 0.08)
                            : AppColors.blue1.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDescanso ? Icons.weekend : Icons.access_time,
                            size: 16,
                            color: isDescanso ? Colors.grey : AppColors.blue1,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (turnoNombre != null)
                                  Text(
                                    turnoNombre,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                Text(
                                  horarioLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDescanso
                                        ? Colors.grey
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  void _showCreateEditDialog(BuildContext context, HorarioPlantilla? horario) {
    final isEditing = horario != null;
    final nombreCtrl = TextEditingController(text: horario?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: horario?.descripcion ?? '');

    // Day-turno assignments
    final Map<DiaSemana, String?> dayTurnos = {};
    final Map<DiaSemana, bool> dayDescanso = {};

    for (final dia in DiaSemana.values) {
      final existing = horario?.dias.cast<HorarioPlantillaDia?>().firstWhere(
            (d) => d!.diaSemana == dia,
            orElse: () => null,
          );
      dayTurnos[dia] = existing?.turnoId;
      dayDescanso[dia] = existing?.esDescanso ?? (dia == DiaSemana.domingo);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Horario' : 'Nuevo Horario'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descripcionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Asignacion por dia',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Get turnos from cubit state
                      BlocBuilder<TurnoListCubit, TurnoListState>(
                        builder: (context, turnoState) {
                          final turnos = turnoState is TurnoListLoaded
                              ? turnoState.turnos
                              : <Turno>[];

                          return Column(
                            children: DiaSemana.values.map((dia) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        dia.abreviatura,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: dayDescanso[dia] ?? false,
                                      onChanged: (v) {
                                        setDialogState(() {
                                          dayDescanso[dia] = v ?? false;
                                          if (v == true) {
                                            dayTurnos[dia] = null;
                                          }
                                        });
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const Text('Desc.', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 8),
                                    if (!(dayDescanso[dia] ?? false))
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: dayTurnos[dia],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            border: OutlineInputBorder(),
                                          ),
                                          isExpanded: true,
                                          hint: const Text('Turno', style: TextStyle(fontSize: 11)),
                                          items: turnos.map((t) {
                                            return DropdownMenuItem(
                                              value: t.id,
                                              child: Text(
                                                '${t.nombre} (${t.rangoHorario})',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) {
                                            setDialogState(() {
                                              dayTurnos[dia] = v;
                                            });
                                          },
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      )
                                    else
                                      const Expanded(
                                        child: Text(
                                          'Descanso',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final dias = <Map<String, dynamic>>[];
                    for (final dia in DiaSemana.values) {
                      dias.add({
                        'diaSemana': dia.apiValue,
                        'esDescanso': dayDescanso[dia] ?? false,
                        if (dayTurnos[dia] != null) 'turnoId': dayTurnos[dia],
                      });
                    }

                    final data = <String, dynamic>{
                      'nombre': nombreCtrl.text.trim(),
                      'descripcion': descripcionCtrl.text.trim(),
                      'dias': dias,
                    };

                    if (isEditing) {
                      _horarioCubit.actualizarHorario(horario.id, data);
                    } else {
                      _horarioCubit.crearHorario(data);
                    }
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, HorarioPlantilla horario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Horario'),
        content: Text('Esta seguro de eliminar la plantilla "${horario.nombre}"?'),
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
              if (_selectedHorario?.id == horario.id) {
                setState(() => _selectedHorario = null);
              }
              _horarioCubit.eliminarHorario(horario.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
