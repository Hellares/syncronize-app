import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/asistencia.dart';
import '../bloc/asistencia/asistencia_cubit.dart';
import '../bloc/asistencia/asistencia_state.dart';

class AsistenciaPage extends StatefulWidget {
  const AsistenciaPage({super.key});

  @override
  State<AsistenciaPage> createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends State<AsistenciaPage> {
  late final AsistenciaCubit _cubit;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cubit = locator<AsistenciaCubit>();
    _loadForDate();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _loadForDate() {
    _cubit.loadAsistencias(queryParams: {
      'fecha': DateFormat('yyyy-MM-dd').format(_selectedDate),
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Asistencia',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
              onPressed: () async {
                final result = await context.push('/empresa/rrhh/asistencia/registrar');
                if (result == true) _loadForDate();
              },
              tooltip: 'Registrar asistencia',
            ),
          ],
        ),
        body: GradientContainer(
          child: Column(
            children: [
              // Date selector
              InkWell(
                onTap: _pickDate,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.blue1),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE dd/MM/yyyy', 'es').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down, color: AppColors.blue1),
                    ],
                  ),
                ),
              ),

              // List
              Expanded(
                child: BlocConsumer<AsistenciaCubit, AsistenciaState>(
                  listener: (context, state) {
                    if (state is AsistenciaActionSuccess) {
                      SnackBarHelper.showSuccess(context, state.message);
                      _loadForDate();
                    }
                    if (state is AsistenciaError) {
                      SnackBarHelper.showError(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is AsistenciaLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is AsistenciaListLoaded) {
                      if (state.asistencias.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fingerprint,
                                size: 56,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin registros de asistencia',
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
                        onRefresh: () async => _loadForDate(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.asistencias.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _buildAsistenciaCard(state.asistencias[index]);
                          },
                        ),
                      );
                    }

                    if (state is AsistenciaError) {
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

  Widget _buildAsistenciaCard(Asistencia asistencia) {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Estado chip
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: asistencia.estado.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Employee info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asistencia.empleadoNombre ?? 'Empleado',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (asistencia.empleadoDni != null)
                  Text(
                    'DNI: ${asistencia.empleadoDni}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Time info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (asistencia.horaEntrada != null)
                Text(
                  'E: ${DateFormat('HH:mm').format(asistencia.horaEntrada!.toLocal())}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (asistencia.horaSalida != null)
                Text(
                  'S: ${DateFormat('HH:mm').format(asistencia.horaSalida!.toLocal())}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: asistencia.estado.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              asistencia.estado.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: asistencia.estado.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
