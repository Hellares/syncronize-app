import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/crear_reporte_incidencia/crear_reporte_incidencia_cubit.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/sedes_selector/sedes_selector_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

class CrearReporteIncidenciaPage extends StatefulWidget {
  const CrearReporteIncidenciaPage({super.key});

  @override
  State<CrearReporteIncidenciaPage> createState() =>
      _CrearReporteIncidenciaPageState();
}

class _CrearReporteIncidenciaPageState
    extends State<CrearReporteIncidenciaPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _sedeId;
  TipoReporteIncidencia _tipoReporte =
      TipoReporteIncidencia.incidenciaPuntual;
  DateTime _fechaIncidente = DateTime.now();
  String? _supervisorId;

  @override
  void initState() {
    super.initState();
    // Cargar sedes al iniciar la página
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
    _tituloController.dispose();
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reporte de Incidencia'),
      ),
      body: BlocConsumer<CrearReporteIncidenciaCubit,
          CrearReporteIncidenciaState>(
          listener: (context, state) {
            if (state is CrearReporteIncidenciaSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(state.reporte);
            } else if (state is CrearReporteIncidenciaError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is CrearReporteIncidenciaLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildFormFields(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submitForm,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(isLoading ? 'Creando...' : 'Crear Reporte'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
    
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete la información del reporte. Después podrá agregar los productos afectados.',
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _tituloController,
          decoration: const InputDecoration(
            labelText: 'Título *',
            hintText: 'Ej: Productos dañados en almacén',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El título es requerido';
            }
            return null;
          },
        ),
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
                'Error al cargar sedes: ${state.message}',
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
                label: 'Sede *',
                items: items,
                value: _sedeId,
                hintText: 'Seleccione la sede donde ocurrió el incidente...',
                onChanged: (value) {
                  setState(() {
                    _sedeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Debe seleccionar una sede';
                  }
                  return null;
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TipoReporteIncidencia>(
          initialValue: _tipoReporte,
          decoration: const InputDecoration(
            labelText: 'Tipo de Reporte *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: TipoReporteIncidencia.values.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Text(_getTipoReporteLabel(tipo)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _tipoReporte = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: const Text('Fecha del Incidente *'),
          subtitle: Text(_formatDate(_fechaIncidente)),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fechaIncidente,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _fechaIncidente = picked;
              });
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción General',
            hintText: 'Describa el contexto del incidente...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          decoration: const InputDecoration(
            labelText: 'Observaciones Finales',
            hintText: 'Observaciones adicionales...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text(
          'Nota: Podrá agregar productos afectados después de crear el reporte.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_sedeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar una sede'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<CrearReporteIncidenciaCubit>().crearReporte(
            sedeId: _sedeId!,
            titulo: _tituloController.text.trim(),
            descripcionGeneral: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            tipoReporte: _tipoReporte,
            fechaIncidente: _fechaIncidente,
            supervisorId: _supervisorId,
            observacionesFinales: _observacionesController.text.trim().isEmpty
                ? null
                : _observacionesController.text.trim(),
          );
    }
  }

  String _getTipoReporteLabel(TipoReporteIncidencia tipo) {
    switch (tipo) {
      case TipoReporteIncidencia.inventarioCompleto:
        return 'Inventario Completo';
      case TipoReporteIncidencia.incidenciaPuntual:
        return 'Incidencia Puntual';
      case TipoReporteIncidencia.revisionRutinaria:
        return 'Revisión Rutinaria';
      case TipoReporteIncidencia.eventoEspecifico:
        return 'Evento Específico';
      case TipoReporteIncidencia.auditoria:
        return 'Auditoría';
      case TipoReporteIncidencia.otro:
        return 'Otro';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
