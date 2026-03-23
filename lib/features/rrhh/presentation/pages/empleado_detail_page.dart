import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/empleado.dart';
import '../bloc/empleado_detail/empleado_detail_cubit.dart';
import '../bloc/empleado_detail/empleado_detail_state.dart';
import '../bloc/empleado_form/empleado_form_cubit.dart';
import '../bloc/empleado_form/empleado_form_state.dart';

class EmpleadoDetailPage extends StatefulWidget {
  final String empleadoId;

  const EmpleadoDetailPage({super.key, required this.empleadoId});

  @override
  State<EmpleadoDetailPage> createState() => _EmpleadoDetailPageState();
}

class _EmpleadoDetailPageState extends State<EmpleadoDetailPage> {
  late final EmpleadoDetailCubit _detailCubit;
  late final EmpleadoFormCubit _formCubit;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _detailCubit = locator<EmpleadoDetailCubit>();
    _formCubit = locator<EmpleadoFormCubit>();
    _detailCubit.loadEmpleado(widget.empleadoId);
  }

  @override
  void dispose() {
    _detailCubit.close();
    _formCubit.close();
    super.dispose();
  }

  Empleado? _extractEmpleado(EmpleadoDetailState state) {
    if (state is EmpleadoDetailLoaded) return state.empleado;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _detailCubit),
        BlocProvider.value(value: _formCubit),
      ],
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && _hasChanges) {
            // Parent will check result
          }
        },
        child: BlocListener<EmpleadoFormCubit, EmpleadoFormState>(
          listener: (context, formState) {
            if (formState is EmpleadoFormSuccess) {
              _hasChanges = true;
              SnackBarHelper.showSuccess(context, 'Empleado cesado exitosamente');
              _detailCubit.refresh(widget.empleadoId);
            } else if (formState is EmpleadoFormError) {
              SnackBarHelper.showError(context, formState.message);
            }
          },
          child: BlocBuilder<EmpleadoDetailCubit, EmpleadoDetailState>(
            builder: (context, state) {
              return Scaffold(
                appBar: SmartAppBar(
                  title: 'Detalle Empleado',
                  backgroundColor: AppColors.blue1,
                  foregroundColor: AppColors.white,
                ),
                body: _buildBody(context, state),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmpleadoDetailState state) {
    if (state is EmpleadoDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is EmpleadoDetailError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _detailCubit.loadEmpleado(widget.empleadoId),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final empleado = _extractEmpleado(state);
    if (empleado == null) return const SizedBox.shrink();

    return GradientContainer(
      child: RefreshIndicator(
        onRefresh: () async {
          await _detailCubit.refresh(widget.empleadoId);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(empleado),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Datos Personales',
              icon: Icons.person,
              children: [
                _buildInfoRow('Nombres', empleado.nombres ?? '-'),
                _buildInfoRow('Apellidos', empleado.apellidos ?? '-'),
                _buildInfoRow('DNI', empleado.dni ?? '-'),
                _buildInfoRow('Email', empleado.email ?? '-'),
                _buildInfoRow('Telefono', empleado.telefono ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Contrato',
              icon: Icons.description,
              children: [
                _buildInfoRow('Tipo Contrato', empleado.tipoContrato.label),
                _buildInfoRow('Fecha Ingreso', DateFormatter.formatDate(empleado.fechaIngreso)),
                if (empleado.fechaCese != null)
                  _buildInfoRow('Fecha Cese', DateFormatter.formatDate(empleado.fechaCese!)),
                _buildInfoRow('Cargo', empleado.cargo ?? '-'),
                _buildInfoRow('Departamento', empleado.departamento ?? '-'),
                _buildInfoRow('Sede', empleado.sedeNombre ?? empleado.sedeId),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Remuneracion',
              icon: Icons.attach_money,
              children: [
                _buildInfoRow(
                  'Salario Base',
                  '${empleado.moneda} ${empleado.salarioBase.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Datos Bancarios',
              icon: Icons.account_balance,
              children: [
                _buildInfoRow('Banco', empleado.banco ?? '-'),
                _buildInfoRow('N. Cuenta', empleado.numeroCuenta ?? '-'),
                _buildInfoRow('CCI', empleado.cci ?? '-'),
              ],
            ),
            const SizedBox(height: 24),
            if (!empleado.estaCesado) ...[
              CustomButton(
                text: 'Editar Empleado',
                backgroundColor: AppColors.blue1,
                onPressed: () async {
                  final result = await context.push(
                    '/empresa/rrhh/empleados/${empleado.id}/editar',
                    extra: empleado,
                  );
                  if (result == true) {
                    _hasChanges = true;
                    _detailCubit.refresh(widget.empleadoId);
                  }
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Cesar Empleado',
                isOutlined: true,
                borderColor: AppColors.red,
                textColor: AppColors.red,
                onPressed: () => _confirmCesar(context, empleado),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Empleado empleado) {
    return GradientContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: empleado.estado.color.withValues(alpha: 0.1),
            child: Text(
              empleado.iniciales,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: empleado.estado.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            empleado.nombreCompleto,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            empleado.codigo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.blue1,
            ),
          ),
          if (empleado.cargo != null) ...[
            const SizedBox(height: 2),
            Text(
              empleado.cargo!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: empleado.estado.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              empleado.estado.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: empleado.estado.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.blue1),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCesar(BuildContext context, Empleado empleado) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cesar Empleado'),
        content: Text(
          'Esta seguro de cesar a ${empleado.nombreCompleto}? Esta accion cambiara su estado a Cesado.',
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
              _formCubit.actualizarEmpleado(empleado.id, {
                'estado': 'CESADO',
                'fechaCese': DateTime.now().toIso8601String(),
              });
            },
            child: const Text('Cesar'),
          ),
        ],
      ),
    );
  }
}
