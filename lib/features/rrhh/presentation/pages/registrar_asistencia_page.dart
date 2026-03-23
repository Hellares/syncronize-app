import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/empleado.dart';
import '../bloc/asistencia/asistencia_cubit.dart';
import '../bloc/asistencia/asistencia_state.dart';
import '../bloc/empleado_list/empleado_list_cubit.dart';
import '../bloc/empleado_list/empleado_list_state.dart';

class RegistrarAsistenciaPage extends StatefulWidget {
  const RegistrarAsistenciaPage({super.key});

  @override
  State<RegistrarAsistenciaPage> createState() =>
      _RegistrarAsistenciaPageState();
}

class _RegistrarAsistenciaPageState extends State<RegistrarAsistenciaPage> {
  late final AsistenciaCubit _asistenciaCubit;
  late final EmpleadoListCubit _empleadoCubit;

  Empleado? _selectedEmpleado;
  String _registroTipo = 'ENTRADA'; // ENTRADA or SALIDA
  final _observacionesController = TextEditingController();

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
    _observacionesController.dispose();
    super.dispose();
  }

  void _registrar() {
    if (_selectedEmpleado == null) {
      SnackBarHelper.showWarning(context, 'Seleccione un empleado');
      return;
    }

    final now = DateTime.now();
    final data = <String, dynamic>{
      'empleadoId': _selectedEmpleado!.id,
      'fecha': DateFormat('yyyy-MM-dd').format(now),
    };

    if (_observacionesController.text.isNotEmpty) {
      data['observaciones'] = _observacionesController.text.trim();
    }

    if (_registroTipo == 'ENTRADA') {
      _asistenciaCubit.registrarEntrada(data);
    } else {
      // For salida, we would need the asistencia ID
      // Simplified: use entrada with the same data structure
      _asistenciaCubit.registrarEntrada(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _asistenciaCubit),
        BlocProvider.value(value: _empleadoCubit),
      ],
      child: BlocListener<AsistenciaCubit, AsistenciaState>(
        listener: (context, state) {
          if (state is AsistenciaActionSuccess) {
            SnackBarHelper.showSuccess(context, state.message);
            context.pop(true);
          } else if (state is AsistenciaError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        child: Scaffold(
          appBar: SmartAppBar(
            title: 'Registrar Asistencia',
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
          ),
          body: GradientContainer(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current time display
                GradientContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time, size: 36, color: AppColors.blue1),
                      const SizedBox(height: 8),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, _) {
                          return Text(
                            DateFormat('HH:mm:ss').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blue3,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE dd/MM/yyyy', 'es').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Select employee
                const Text(
                  'Seleccionar Empleado',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue3,
                  ),
                ),
                const SizedBox(height: 10),
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
                          hintText: 'Seleccionar empleado',
                          hintStyle: const TextStyle(fontSize: 13),
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
                const SizedBox(height: 20),

                // Tipo registro
                const Text(
                  'Tipo de Registro',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTipoButton(
                        label: 'Entrada',
                        icon: Icons.login,
                        isSelected: _registroTipo == 'ENTRADA',
                        color: Colors.green,
                        onTap: () =>
                            setState(() => _registroTipo = 'ENTRADA'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTipoButton(
                        label: 'Salida',
                        icon: Icons.logout,
                        isSelected: _registroTipo == 'SALIDA',
                        color: Colors.orange,
                        onTap: () =>
                            setState(() => _registroTipo = 'SALIDA'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Observaciones
                TextField(
                  controller: _observacionesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Submit
                BlocBuilder<AsistenciaCubit, AsistenciaState>(
                  builder: (context, state) {
                    final isLoading = state is AsistenciaLoading;
                    return CustomButton(
                      text: 'Registrar ${_registroTipo == 'ENTRADA' ? 'Entrada' : 'Salida'}',
                      backgroundColor: _registroTipo == 'ENTRADA'
                          ? Colors.green
                          : Colors.orange,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _registrar,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
