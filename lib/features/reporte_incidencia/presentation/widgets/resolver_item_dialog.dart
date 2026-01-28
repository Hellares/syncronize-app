import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/sedes_selector/sedes_selector_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_circle, color: Theme.of(context).primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resolver Incidencia',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.productoNombre,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Acción a Tomar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccionIncidenciaProducto>(
                  initialValue: _accion,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                  ),
                  items: AccionIncidenciaProducto.values.map((accion) {
                    return DropdownMenuItem(
                      value: accion,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getAccionIcon(accion), size: 20, color: _getAccionColor(accion)),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              _getAccionLabel(accion),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Observaciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(
                    hintText: 'Agregue detalles sobre la acción tomada...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
