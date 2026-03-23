import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/turno.dart';
import '../bloc/turno_list/turno_list_cubit.dart';
import '../bloc/turno_list/turno_list_state.dart';

class TurnosPage extends StatefulWidget {
  const TurnosPage({super.key});

  @override
  State<TurnosPage> createState() => _TurnosPageState();
}

class _TurnosPageState extends State<TurnosPage> {
  late final TurnoListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<TurnoListCubit>();
    _cubit.loadTurnos();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Turnos',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () => _showTurnoDialog(context, null),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GradientContainer(
          child: BlocConsumer<TurnoListCubit, TurnoListState>(
            listener: (context, state) {
              if (state is TurnoListActionSuccess) {
                SnackBarHelper.showSuccess(context, state.message);
              }
              if (state is TurnoListError) {
                SnackBarHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is TurnoListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is TurnoListError) {
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

              if (state is TurnoListLoaded) {
                if (state.turnos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin turnos registrados',
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
                  onRefresh: () async => await _cubit.loadTurnos(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.turnos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildTurnoCard(context, state.turnos[index]);
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

  Widget _buildTurnoCard(BuildContext context, Turno turno) {
    final turnoColor = turno.color != null
        ? Color(int.parse('0xFF${turno.color!.replaceAll('#', '')}'))
        : AppColors.blue1;

    return GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: turnoColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turno.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      turno.rangoHorario,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${turno.horasEfectivas}h efectivas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue1,
                      ),
                    ),
                  ],
                ),
                if (turno.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Por defecto',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppColors.blue1),
            onPressed: () => _showTurnoDialog(context, turno),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
            onPressed: () => _confirmDelete(context, turno),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _showTurnoDialog(BuildContext context, Turno? turno) {
    final isEditing = turno != null;
    final nombreController = TextEditingController(text: turno?.nombre ?? '');
    final horaInicioController = TextEditingController(text: turno?.horaInicio ?? '');
    final horaFinController = TextEditingController(text: turno?.horaFin ?? '');
    final almuerzoController = TextEditingController(
      text: turno?.duracionAlmuerzoMin.toString() ?? '60',
    );
    final colorController = TextEditingController(text: turno?.color ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Turno' : 'Nuevo Turno'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: horaInicioController,
                  decoration: const InputDecoration(
                    labelText: 'Hora Inicio (HH:mm)',
                    isDense: true,
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await _pickTime(context, horaInicioController.text);
                    if (time != null) {
                      horaInicioController.text = _formatTime(time);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: horaFinController,
                  decoration: const InputDecoration(
                    labelText: 'Hora Fin (HH:mm)',
                    isDense: true,
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await _pickTime(context, horaFinController.text);
                    if (time != null) {
                      horaFinController.text = _formatTime(time);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: almuerzoController,
                  decoration: const InputDecoration(
                    labelText: 'Almuerzo (minutos)',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color (hex, ej: #3B82F6)',
                    isDense: true,
                  ),
                ),
              ],
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
                final data = <String, dynamic>{
                  'nombre': nombreController.text.trim(),
                  'horaInicio': horaInicioController.text.trim(),
                  'horaFin': horaFinController.text.trim(),
                  'duracionAlmuerzoMin': int.tryParse(almuerzoController.text) ?? 60,
                };
                if (colorController.text.isNotEmpty) {
                  data['color'] = colorController.text.trim();
                }

                if (isEditing) {
                  _cubit.actualizarTurno(turno.id, data);
                } else {
                  _cubit.crearTurno(data);
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, String currentValue) async {
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    if (currentValue.isNotEmpty) {
      final parts = currentValue.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(BuildContext context, Turno turno) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Turno'),
        content: Text('Esta seguro de eliminar el turno "${turno.nombre}"?'),
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
              _cubit.eliminarTurno(turno.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
