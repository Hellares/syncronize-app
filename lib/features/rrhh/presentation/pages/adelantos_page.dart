import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/adelanto.dart';
import '../../domain/entities/empleado.dart';
import '../bloc/adelanto/adelanto_cubit.dart';
import '../bloc/adelanto/adelanto_state.dart';
import '../bloc/empleado_list/empleado_list_cubit.dart';
import '../bloc/empleado_list/empleado_list_state.dart';

class AdelantosPage extends StatefulWidget {
  const AdelantosPage({super.key});

  @override
  State<AdelantosPage> createState() => _AdelantosPageState();
}

class _AdelantosPageState extends State<AdelantosPage> {
  late final AdelantoCubit _cubit;
  String? _selectedEstado;

  static const _estadoFilters = <String?, String>{
    null: 'Todos',
    'PENDIENTE_ADELANTO': 'Pendiente',
    'APROBADO_ADELANTO': 'Aprobado',
    'PAGADO_ADELANTO': 'Pagado',
    'DESCONTADO_ADELANTO': 'Descontado',
    'RECHAZADO_ADELANTO': 'Rechazado',
  };

  @override
  void initState() {
    super.initState();
    _cubit = locator<AdelantoCubit>();
    _cubit.loadAdelantos();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _applyFilter(String? estado) {
    setState(() => _selectedEstado = estado);
    final params = <String, dynamic>{};
    if (estado != null) params['estado'] = estado;
    _cubit.loadAdelantos(queryParams: params.isNotEmpty ? params : null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Adelantos',
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
              // Filter chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: _estadoFilters.entries.map((entry) {
                    final isSelected = _selectedEstado == entry.key;
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
                        onSelected: (_) => _applyFilter(entry.key),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // List
              Expanded(
                child: BlocConsumer<AdelantoCubit, AdelantoState>(
                  listener: (context, state) {
                    if (state is AdelantoActionSuccess) {
                      SnackBarHelper.showSuccess(context, state.message);
                    }
                    if (state is AdelantoError) {
                      SnackBarHelper.showError(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is AdelantoLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is AdelantoListLoaded) {
                      if (state.adelantos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 56,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin adelantos registrados',
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
                          itemCount: state.adelantos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildAdelantoCard(
                                context, state.adelantos[index]);
                          },
                        ),
                      );
                    }

                    if (state is AdelantoError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                            const SizedBox(height: 12),
                            Text(state.message,
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => _cubit.refresh(),
                              child: const Text('Reintentar'),
                            ),
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

  Widget _buildAdelantoCard(BuildContext context, Adelanto adelanto) {
    return GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: adelanto.estado.color.withValues(alpha: 0.1),
                child: const Icon(Icons.payments, size: 18, color: AppColors.blue1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adelanto.empleadoNombre ?? 'Empleado',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (adelanto.empleadoCodigo != null)
                      Text(
                        adelanto.empleadoCodigo!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Monto
              Text(
                'S/ ${adelanto.monto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Info row
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatDate(adelanto.fechaSolicitud),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              // Estado badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: adelanto.estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  adelanto.estado.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: adelanto.estado.color,
                  ),
                ),
              ),
            ],
          ),

          if (adelanto.motivo != null && adelanto.motivo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              adelanto.motivo!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (adelanto.motivoRechazo != null &&
              adelanto.motivoRechazo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Motivo: ${adelanto.motivoRechazo}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (adelanto.estaPendiente) ...[
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
                  onPressed: () => _showRejectDialog(context, adelanto),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aprobar', style: TextStyle(fontSize: 12)),
                  onPressed: () => _cubit.aprobar(adelanto.id),
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

          if (adelanto.estaAprobado) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payments, size: 16),
                label: const Text('Registrar Pago', style: TextStyle(fontSize: 12)),
                onPressed: () => _confirmPay(context, adelanto),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Adelanto adelanto) {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Adelanto'),
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
              _cubit.rechazar(adelanto.id, motivoCtrl.text.trim());
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _confirmPay(BuildContext context, Adelanto adelanto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Text(
          'Se registrara el pago de S/ ${adelanto.monto.toStringAsFixed(2)} para ${adelanto.empleadoNombre ?? 'el empleado'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _cubit.pagar(adelanto.id, {'metodoPago': 'TRANSFERENCIA'});
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final empleadoListCubit = locator<EmpleadoListCubit>();
    empleadoListCubit.loadEmpleados(estado: 'ACTIVO');

    Empleado? selectedEmpleado;
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return BlocProvider.value(
              value: empleadoListCubit,
              child: AlertDialog(
                title: const Text('Nuevo Adelanto'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Employee selector
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

                      // Monto
                      TextField(
                        controller: montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto (S/)',
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixText: 'S/ ',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // Motivo
                      TextField(
                        controller: motivoCtrl,
                        maxLines: 3,
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
                      final monto = double.tryParse(montoCtrl.text);
                      if (monto == null || monto <= 0) {
                        SnackBarHelper.showWarning(ctx, 'Ingrese un monto valido');
                        return;
                      }

                      Navigator.of(ctx).pop();
                      empleadoListCubit.close();

                      _cubit.crearAdelanto({
                        'empleadoId': selectedEmpleado!.id,
                        'monto': monto,
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
