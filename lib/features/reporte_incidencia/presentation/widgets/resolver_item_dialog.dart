import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/sedes_selector/sedes_selector_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';

class ResolverItemDialog extends StatefulWidget {
  final String reporteId;
  final String itemId;
  final String productoNombre;
  final Function(AccionIncidenciaProducto accion, String? observaciones, String? sedeDestinoId) onResolve;

  const ResolverItemDialog({
    super.key,
    required this.reporteId,
    required this.itemId,
    required this.productoNombre,
    required this.onResolve,
  });

  @override
  State<ResolverItemDialog> createState() => _ResolverItemDialogState();
}

class _ResolverItemDialogState extends State<ResolverItemDialog> {
  final _observacionesController = TextEditingController();
  AccionIncidenciaProducto _accion = AccionIncidenciaProducto.marcarDanado;
  String? _sedeDestinoId;

  @override
  void initState() {
    super.initState();
    // Cargar sedes al iniciar el dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final empresaState = context.read<EmpresaContextCubit>().state;
      if (empresaState is EmpresaContextLoaded) {
        context
            .read<SedesSelectorCubit>()
            .cargarSedes(empresaId: empresaState.context.empresa.id);
      }
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        borderRadius: BorderRadius.circular(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build_circle, color: AppColors.blue1, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle('RESOLVER INCIDENCIA'),
                        AppText(widget.productoNombre,overflow: TextOverflow.ellipsis,),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18,),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 18),
              CustomDropdownHelpers.standard<AccionIncidenciaProducto>(
                borderColor: AppColors.blue1,
                label: 'Acción a Tomar',
                items: AccionIncidenciaProducto.values.map((accion) {
                  return DropdownItem<AccionIncidenciaProducto>(
                    value: accion,
                    label: _getAccionLabel(accion),
                    leading: Icon(
                      _getAccionIcon(accion),
                      size: 16,
                      color: _getAccionColor(accion),
                    ),
                  );
                }).toList(),
                value: _accion,
                hintText: 'Seleccione una acción...',
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _accion = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_requiresSedeDestino(_accion)) ...[
                // const SizedBox(height: 16),
                BlocBuilder<SedesSelectorCubit, SedesSelectorState>(
                  builder: (context, state) {
                    if (state is SedesSelectorLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
          
                    if (state is SedesSelectorError) {
                      return Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
          
                    if (state is SedesSelectorLoaded) {
                      final items = state.sedes.map((sede) {
                        return DropdownItem<String>(
                          value: sede.id,
                          label: '${sede.nombre} ${sede.codigo != null ? '(${sede.codigo})' : ''}',
                          leading: const Icon(Icons.location_city, size: 20),
                        );
                      }).toList();
          
                      return CustomDropdownHelpers.searchable<String>(
                        borderColor: AppColors.blue1,
                        label: 'Sede Destino *',
                        items: items,
                        value: _sedeDestinoId,
                        hintText: 'Seleccione una sede...',
                        onChanged: (value) {
                          setState(() {
                            _sedeDestinoId = value;
                          });
                        },
                        validator: (value) {
                          if (_requiresSedeDestino(_accion) && value == null) {
                            return 'Debe seleccionar una sede destino';
                          }
                          return null;
                        },
                      );
                    }
          
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 10),
              ],
              CustomText(
                label: 'Observaciones',
                borderColor: AppColors.blue1,
                controller: _observacionesController,
                hintText: 'Agregue detalles sobre la acción tomada...',
                maxLines: 3,                
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const AppText('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FloatingButtonText(
                    width: 100,
                    height: 32,
                    onPressed: _submitForm,
                    icon: Icons.check_circle_outline,
                    label: 'Resolver',
                  ),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_requiresSedeDestino(_accion) && (_sedeDestinoId == null || _sedeDestinoId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar una sede destino'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final observaciones = _observacionesController.text.trim();
    widget.onResolve(
      _accion,
      observaciones.isEmpty ? null : observaciones,
      _sedeDestinoId,
    );
    Navigator.of(context).pop();
  }

  bool _requiresSedeDestino(AccionIncidenciaProducto accion) {
    return accion == AccionIncidenciaProducto.devolverSedePrincipal;
  }

  IconData _getAccionIcon(AccionIncidenciaProducto accion) {
    switch (accion) {
      case AccionIncidenciaProducto.marcarDanado:
        return Icons.broken_image;
      case AccionIncidenciaProducto.darDeBaja:
        return Icons.delete_forever;
      case AccionIncidenciaProducto.reparacionInterna:
        return Icons.build;
      case AccionIncidenciaProducto.devolverSedePrincipal:
        return Icons.keyboard_return;
      case AccionIncidenciaProducto.enviarGarantia:
        return Icons.verified_user;
      case AccionIncidenciaProducto.aceptarPerdida:
        return Icons.check;
      case AccionIncidenciaProducto.reportarRobo:
        return Icons.report;
      case AccionIncidenciaProducto.ajustarSistema:
        return Icons.settings;
      case AccionIncidenciaProducto.pendienteDecision:
        return Icons.pending;
    }
  }

  Color _getAccionColor(AccionIncidenciaProducto accion) {
    switch (accion) {
      case AccionIncidenciaProducto.marcarDanado:
        return Colors.orange;
      case AccionIncidenciaProducto.darDeBaja:
        return Colors.red;
      case AccionIncidenciaProducto.reparacionInterna:
        return Colors.blue;
      case AccionIncidenciaProducto.devolverSedePrincipal:
        return Colors.purple;
      case AccionIncidenciaProducto.enviarGarantia:
        return Colors.indigo;
      case AccionIncidenciaProducto.aceptarPerdida:
        return Colors.grey;
      case AccionIncidenciaProducto.reportarRobo:
        return Colors.deepOrange;
      case AccionIncidenciaProducto.ajustarSistema:
        return Colors.teal;
      case AccionIncidenciaProducto.pendienteDecision:
        return Colors.amber;
    }
  }

  String _getAccionLabel(AccionIncidenciaProducto accion) {
    switch (accion) {
      case AccionIncidenciaProducto.marcarDanado:
        return 'Marcar como Dañado';
      case AccionIncidenciaProducto.darDeBaja:
        return 'Dar de Baja';
      case AccionIncidenciaProducto.reparacionInterna:
        return 'Reparación Interna';
      case AccionIncidenciaProducto.devolverSedePrincipal:
        return 'Devolver a Sede Principal';
      case AccionIncidenciaProducto.enviarGarantia:
        return 'Enviar a Garantía';
      case AccionIncidenciaProducto.aceptarPerdida:
        return 'Aceptar Pérdida';
      case AccionIncidenciaProducto.reportarRobo:
        return 'Reportar Robo';
      case AccionIncidenciaProducto.ajustarSistema:
        return 'Ajustar Sistema';
      case AccionIncidenciaProducto.pendienteDecision:
        return 'Pendiente de Decisión';
    }
  }
}
