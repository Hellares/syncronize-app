
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/map_location_picker.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../domain/entities/direccion_persona.dart';
import '../bloc/direccion_list/direccion_list_cubit.dart';
import '../bloc/direccion_list/direccion_list_state.dart';

class MisDireccionesPage extends StatelessWidget {
  const MisDireccionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<DireccionListCubit>()..loadDirecciones(),
      child: const _MisDireccionesView(),
    );
  }
}

class _MisDireccionesView extends StatelessWidget {
  const _MisDireccionesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Mis Direcciones',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: BlocBuilder<DireccionListCubit, DireccionListState>(
          builder: (context, state) {
            if (state is DireccionListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DireccionListError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<DireccionListCubit>().loadDirecciones(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is DireccionListLoaded) {
              if (state.direcciones.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No tienes direcciones guardadas',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Agrega una para mejorar tu experiencia',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<DireccionListCubit>().loadDirecciones(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.direcciones.length,
                  itemBuilder: (_, index) {
                    return _DireccionCard(direccion: state.direcciones[index]);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nueva dirección'),
        backgroundColor: AppColors.blue1,
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, {DireccionPersona? direccion}) {
    final isEditing = direccion != null;
    final etiquetaCtrl = TextEditingController(text: direccion?.etiqueta ?? '');
    final direccionCtrl = TextEditingController(text: direccion?.direccion ?? '');
    final referenciaCtrl = TextEditingController(text: direccion?.referencia ?? '');
    final distritoCtrl = TextEditingController(text: direccion?.distrito ?? '');
    final provinciaCtrl = TextEditingController(text: direccion?.provincia ?? '');
    final departamentoCtrl = TextEditingController(text: direccion?.departamento ?? '');

    String tipo = direccion?.tipo ?? 'ENVIO';
    Map<String, dynamic>? coordenadas = direccion?.coordenadas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Editar dirección' : 'Nueva dirección',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: etiquetaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Etiqueta',
                        hintText: 'Ej: Mi casa, Oficina',
                        prefixIcon: const Icon(Icons.label_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: const Icon(Icons.category, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ENVIO', child: Text('Envío')),
                        DropdownMenuItem(value: 'FISCAL', child: Text('Fiscal')),
                        DropdownMenuItem(value: 'TRABAJO', child: Text('Trabajo')),
                        DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                      ],
                      onChanged: (v) => setSheetState(() => tipo = v!),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: direccionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Dirección *',
                        prefixIcon: const Icon(Icons.location_on, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: referenciaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Referencia',
                        prefixIcon: const Icon(Icons.info_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: distritoCtrl,
                            decoration: InputDecoration(
                              labelText: 'Distrito',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: provinciaCtrl,
                            decoration: InputDecoration(
                              labelText: 'Provincia',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: departamentoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Departamento',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mapa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            coordenadas != null ? Icons.check_circle : Icons.map_outlined,
                            size: 18,
                            color: coordenadas != null ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              coordenadas != null ? 'Ubicación seleccionada' : 'Sin ubicación en mapa',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final lat = (coordenadas?['lat'] as num?)?.toDouble();
                              final lng = ((coordenadas?['lng'] ?? coordenadas?['lon']) as num?)?.toDouble();
                              final result = await Navigator.push<Map<String, dynamic>>(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => MapLocationPicker(initialLat: lat, initialLng: lng),
                                ),
                              );
                              if (result != null) {
                                setSheetState(() => coordenadas = result);
                              }
                            },
                            child: Text(coordenadas != null ? 'Cambiar' : 'Seleccionar',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: _SaveButton(
                        onSave: () async {
                          if (direccionCtrl.text.trim().isEmpty) {
                            throw Exception('La dirección es requerida');
                          }
                          final data = {
                            'tipo': tipo,
                            'etiqueta': etiquetaCtrl.text.trim().isEmpty ? null : etiquetaCtrl.text.trim(),
                            'direccion': direccionCtrl.text.trim(),
                            'referencia': referenciaCtrl.text.trim().isEmpty ? null : referenciaCtrl.text.trim(),
                            'distrito': distritoCtrl.text.trim().isEmpty ? null : distritoCtrl.text.trim(),
                            'provincia': provinciaCtrl.text.trim().isEmpty ? null : provinciaCtrl.text.trim(),
                            'departamento': departamentoCtrl.text.trim().isEmpty ? null : departamentoCtrl.text.trim(),
                            if (coordenadas != null) 'coordenadas': {
                              'lat': coordenadas!['lat'],
                              'lon': coordenadas!['lng'] ?? coordenadas!['lon'],
                            },
                          };
                          final cubit = context.read<DireccionListCubit>();
                          if (isEditing) {
                            await cubit.actualizar(direccion.id, data);
                          } else {
                            await cubit.crear(data);
                          }
                        },
                        onSuccess: () {
                          Navigator.pop(ctx);
                          SnackBarHelper.showSuccess(ctx, isEditing ? 'Dirección actualizada' : 'Dirección guardada');
                        },
                        onError: (msg) {
                          SnackBarHelper.showError(ctx, msg);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DireccionCard extends StatelessWidget {
  final DireccionPersona direccion;

  const _DireccionCard({required this.direccion});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: direccion.esPredeterminada ? Colors.green.shade300 : AppColors.blueborder,
      borderRadius: BorderRadius.circular(10),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_tipoIcon(direccion.tipo), size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  direccion.displayName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (direccion.esPredeterminada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Predeterminada',
                      style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600)),
                ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  if (!direccion.esPredeterminada)
                    const PopupMenuItem(value: 'predeterminada', child: Text('Marcar predeterminada')),
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (v) async {
                  final cubit = context.read<DireccionListCubit>();
                  if (v == 'predeterminada') {
                    cubit.marcarPredeterminada(direccion.id);
                  } else if (v == 'editar') {
                    // Buscar el widget padre para llamar _mostrarFormulario
                    final parentState = context.findAncestorWidgetOfExactType<_MisDireccionesView>();
                    if (parentState != null) {
                      parentState._mostrarFormulario(context, direccion: direccion);
                    }
                  } else if (v == 'eliminar') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar dirección'),
                        content: const Text('¿Estás seguro?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) cubit.eliminar(direccion.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(direccion.direccion, style: const TextStyle(fontSize: 14)),
          if (direccion.referencia != null && direccion.referencia!.isNotEmpty)
            Text(direccion.referencia!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(
            [direccion.distrito, direccion.provincia, direccion.departamento]
                .where((e) => e != null && e.isNotEmpty)
                .join(', '),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          if (direccion.tieneCoordenadas)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.map, size: 12, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text('Ubicación guardada',
                      style: TextStyle(fontSize: 11, color: Colors.green[600])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'ENVIO': return Icons.local_shipping;
      case 'FISCAL': return Icons.receipt_long;
      case 'TRABAJO': return Icons.work;
      default: return Icons.location_on;
    }
  }
}

class _SaveButton extends StatefulWidget {
  final Future<void> Function() onSave;
  final VoidCallback onSuccess;
  final void Function(String) onError;

  const _SaveButton({required this.onSave, required this.onSuccess, required this.onError});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _saving
          ? null
          : () async {
              setState(() => _saving = true);
              try {
                await widget.onSave();
                if (mounted) widget.onSuccess();
              } catch (e) {
                if (mounted) {
                  setState(() => _saving = false);
                  widget.onError(e.toString().replaceFirst('Exception: ', ''));
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(_saving ? 'Guardando...' : 'Guardar dirección'),
    );
  }
}
