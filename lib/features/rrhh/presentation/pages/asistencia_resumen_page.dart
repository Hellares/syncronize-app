import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

import '../../domain/entities/asistencia.dart';
import '../../domain/entities/empleado.dart';
import '../bloc/asistencia/asistencia_cubit.dart';
import '../bloc/asistencia/asistencia_state.dart';
import '../bloc/empleado_list/empleado_list_cubit.dart';
import '../bloc/empleado_list/empleado_list_state.dart';

class AsistenciaResumenPage extends StatefulWidget {
  const AsistenciaResumenPage({super.key});

  @override
  State<AsistenciaResumenPage> createState() => _AsistenciaResumenPageState();
}

class _AsistenciaResumenPageState extends State<AsistenciaResumenPage> {
  late final AsistenciaCubit _asistenciaCubit;
  late final EmpleadoListCubit _empleadoCubit;

  Empleado? _selectedEmpleado;
  int _selectedMes = DateTime.now().month;
  int _selectedAnio = DateTime.now().year;

  static const _meses = <int, String>{
    1: 'Enero',
    2: 'Febrero',
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembre',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre',
  };

  @override
  void initState() {
    super.initState();
    _asistenciaCubit = locator<AsistenciaCubit>();
    _empleadoCubit = locator<EmpleadoListCubit>();
    _empleadoCubit.loadEmpleados(estado: 'ACTIVO');
  }

  @override
  void dispose() {
    _asistenciaCubit.close();
    _empleadoCubit.close();
    super.dispose();
  }

  void _loadResumen() {
    if (_selectedEmpleado == null) return;
    _asistenciaCubit.loadResumenMensual(
      _selectedEmpleado!.id,
      _selectedMes,
      _selectedAnio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _asistenciaCubit),
        BlocProvider.value(value: _empleadoCubit),
      ],
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Resumen Asistencia',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientContainer(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Employee selector
              BlocBuilder<EmpleadoListCubit, EmpleadoListState>(
                builder: (context, state) {
                  if (state is EmpleadoListLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is EmpleadoListLoaded) {
                    return DropdownButtonFormField<Empleado>(
                      value: _selectedEmpleado,
                      decoration: InputDecoration(
                        labelText: 'Empleado',
                        prefixIcon: const Icon(Icons.person, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      isExpanded: true,
                      items: state.empleados.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.nombreCompleto} (${e.codigo})',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedEmpleado = v);
                        _loadResumen();
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 14),

              // Month/Year selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMes,
                      decoration: InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      items: _meses.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedMes = v);
                          _loadResumen();
                        }
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedAnio,
                      decoration: InputDecoration(
                        labelText: 'Anio',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      items: List.generate(5, (i) => DateTime.now().year - i)
                          .map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedAnio = v);
                          _loadResumen();
                        }
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Resumen
              BlocBuilder<AsistenciaCubit, AsistenciaState>(
                builder: (context, state) {
                  if (state is AsistenciaLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is AsistenciaResumenLoaded) {
                    return _buildResumenCards(state.resumen);
                  }

                  if (state is AsistenciaError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (_selectedEmpleado == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 56,
                              color: AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Seleccione un empleado para ver el resumen',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCards(AsistenciaResumen resumen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attendance percentage
        GradientContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Porcentaje de Asistencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue3,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: resumen.porcentajeAsistencia / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        resumen.porcentajeAsistencia >= 90
                            ? Colors.green
                            : resumen.porcentajeAsistencia >= 75
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    Text(
                      '${resumen.porcentajeAsistencia.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            _buildStatCard('Presente', '${resumen.diasPresente}', Colors.green),
            _buildStatCard('Tardanzas', '${resumen.diasTardanza}', Colors.orange),
            _buildStatCard('Faltas', '${resumen.diasFalta}', Colors.red),
            _buildStatCard('Justificados', '${resumen.diasJustificado}', Colors.blue),
            _buildStatCard('Vacaciones', '${resumen.diasVacacion}', Colors.teal),
            _buildStatCard('Licencias', '${resumen.diasLicencia}', Colors.purple),
            _buildStatCard('Descanso', '${resumen.diasDescanso}', Colors.grey),
            _buildStatCard('Feriados', '${resumen.diasFeriado}', Colors.indigo),
          ],
        ),
        const SizedBox(height: 16),

        // Hours summary
        GradientContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de Horas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue3,
                ),
              ),
              const Divider(height: 20),
              _buildHoursRow(
                'Total Horas Trabajadas',
                '${resumen.totalHorasTrabajadas.toStringAsFixed(1)}h',
                AppColors.blue1,
              ),
              const SizedBox(height: 8),
              _buildHoursRow(
                'Horas Extra',
                '${resumen.totalHorasExtra.toStringAsFixed(1)}h',
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
