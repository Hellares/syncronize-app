import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/atributo_valor.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/atributo_plantilla.dart' as plantilla;
import '../bloc/variante_atributo/variante_atributo_cubit.dart';
import '../bloc/variante_atributo/variante_atributo_state.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';
import 'atributo_input_widget.dart';

/// Widget para gestionar atributos de una variante
class VarianteAtributosSection extends StatelessWidget {
  final List<ProductoAtributo> atributosDisponibles;
  final VoidCallback? onSaved;
  final bool showPlantillaButton;
  final String? empresaId;

  const VarianteAtributosSection({
    super.key,
    required this.atributosDisponibles,
    this.onSaved,
    this.showPlantillaButton = true,
    this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VarianteAtributoCubit, VarianteAtributoState>(
      listener: (context, state) {
        if (state is VarianteAtributoSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          if (onSaved != null) {
            onSaved!();
          }
        } else if (state is VarianteAtributoLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<VarianteAtributoCubit>().clearError();
        }
      },
      builder: (context, state) {
        if (state is VarianteAtributoLoading) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is VarianteAtributoLoaded || state is VarianteAtributoSaved) {
          final atributoValores = state is VarianteAtributoLoaded
              ? state.atributoValores
              : (state as VarianteAtributoSaved).atributoValores;
          final isLoading =
              state is VarianteAtributoLoaded ? state.isLoading : false;

          return GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.label_outline, size: 16),
                          const SizedBox(width: 8),
                          AppSubtitle('Atributos de la Variante')
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showPlantillaButton && empresaId != null)
                            TextButton.icon(
                              onPressed: isLoading ? null : () => _showPlantillaSelector(context),
                              icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.blue1,),
                              label: AppSubtitle('Plantilla')
                            ),
                          // if (atributoValores.isNotEmpty)

                          //   IconButton(onPressed: isLoading ? null : () => _showAddAtributoDialog(context),icon: const Icon(Icons.add, size: 18,color: AppColors.blue1),)
                        ],
                      ),
                    ],
                  ),
                  // const SizedBox(height: 10),
                  if (atributoValores.isEmpty) ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.label_off_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'No hay atributos asignados',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              if (showPlantillaButton && empresaId != null)
                                CustomButton(
                                  width: 200,
                                  backgroundColor: AppColors.blue1,
                                  iconColor: AppColors.white,
                                  text: 'Usar Plantilla',
                                  onPressed: () => _showPlantillaSelector(context),
                                  icon: const Icon(Icons.auto_awesome, size: 16,),
                                ),

                              // CustomButton(
                              //   width: 200,
                              //   backgroundColor: AppColors.blue1,
                              //   iconColor: AppColors.white,
                              //   text: 'Agregar Manualmente',
                              //   onPressed: () => _showAddAtributoDialog(context),
                              //   icon: Icon(Icons.add, size: 16,),
                              // )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...atributoValores.map((av) => _buildAtributoCard(context, av, isLoading)),
                  ],
                ],
              ),
            ),
          );
        }

        if (state is VarianteAtributoError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar atributos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(state.message),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAtributoCard(
    BuildContext context,
    AtributoValor atributoValor,
    bool isLoading,
  ) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      gradient: AppGradients.sinfondo,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        dense: true,
        leading: Icon(_getAtributoIcon(atributoValor.atributo.clave), size: 16,),
        title: Text(
          atributoValor.atributo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        ),
        subtitle: Text(atributoValor.valor),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: isLoading
                  ? null
                  : () => _showEditAtributoDialog(context, atributoValor),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: isLoading
                  ? null
                  : () => _confirmRemoveAtributo(context, atributoValor),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAtributoIcon(String clave) {
    switch (clave.toUpperCase()) {
      case 'COLOR':
        return Icons.palette;
      case 'TALLA':
        return Icons.straighten;
      case 'MATERIAL':
        return Icons.category;
      case 'CAPACIDAD':
        return Icons.storage;
      default:
        return Icons.label;
    }
  }

  // void _showAddAtributoDialog(BuildContext context) {
  //   final cubit = context.read<VarianteAtributoCubit>();
  //   final currentState = cubit.state;

  //   if (currentState is! VarianteAtributoLoaded) return;

  //   // Filtrar atributos que ya están asignados
  //   final atributosYaAsignados = currentState.atributoValores
  //       .map((av) => av.atributoId)
  //       .toSet();
  //   final atributosDisponiblesFiltrados = atributosDisponibles
  //       .where((a) => !atributosYaAsignados.contains(a.id))
  //       .toList();

  //   if (atributosDisponiblesFiltrados.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Todos los atributos disponibles ya han sido agregados'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   ProductoAtributo? selectedAtributo;
  //   final valorController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (dialogContext) => StatefulBuilder(
  //       builder: (context, setState) => AlertDialog(
  //         title: const Text('Agregar Atributo'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             DropdownButtonFormField<ProductoAtributo>(
  //               decoration: const InputDecoration(
  //                 labelText: 'Atributo',
  //                 border: OutlineInputBorder(),
  //               ),
  //               initialValue: selectedAtributo,
  //               items: atributosDisponiblesFiltrados.map((atributo) {
  //                 return DropdownMenuItem(
  //                   value: atributo,
  //                   child: Text(atributo.nombre),
  //                 );
  //               }).toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedAtributo = value;
  //                 });
  //               },
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: valorController,
  //               decoration: const InputDecoration(
  //                 labelText: 'Valor',
  //                 border: OutlineInputBorder(),
  //                 hintText: 'Ej: Rojo, M, Algodón',
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(dialogContext).pop(),
  //             child: const Text('Cancelar'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               if (selectedAtributo != null && valorController.text.isNotEmpty) {
  //                 cubit.addAtributo(
  //                   atributo: selectedAtributo!,
  //                   valor: valorController.text.trim(),
  //                 );
  //                 Navigator.of(dialogContext).pop();
  //               }
  //             },
  //             child: const Text('Agregar'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showEditAtributoDialog(BuildContext context, AtributoValor atributoValor) {
    final cubit = context.read<VarianteAtributoCubit>();
    final valorController = TextEditingController(text: atributoValor.valor);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar ${atributoValor.atributo.nombre}'),
        content: TextField(
          controller: valorController,
          decoration: const InputDecoration(
            labelText: 'Valor',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (valorController.text.isNotEmpty) {
                cubit.updateAtributo(
                  atributoValorId: atributoValor.id,
                  nuevoValor: valorController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveAtributo(BuildContext context, AtributoValor atributoValor) {
    final cubit = context.read<VarianteAtributoCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar el atributo "${atributoValor.atributo.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.removeAtributo(atributoValor.id);
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showPlantillaSelector(BuildContext context) {
    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => locator<AtributoPlantillaCubit>()..loadPlantillas(),
        child: BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
          builder: (builderContext, state) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seleccionar Plantilla',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Elige una plantilla para pre-llenar atributos',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: _buildPlantillaContent(builderContext, state, context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlantillaContent(
    BuildContext builderContext,
    AtributoPlantillaState state,
    BuildContext parentContext,
  ) {
    if (state is AtributoPlantillaLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AtributoPlantillaError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error al cargar plantillas'),
              const SizedBox(height: 8),
              Text(state.message),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  builderContext.read<AtributoPlantillaCubit>().loadPlantillas();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is AtributoPlantillaLoaded) {
      if (state.plantillas.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay plantillas disponibles'),
                SizedBox(height: 8),
                Text(
                  'Crea plantillas en la sección de configuración',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.plantillas.length,
        itemBuilder: (context, index) {
          final plantilla = state.plantillas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: plantilla.icono != null
                    ? Text(plantilla.icono!, style: const TextStyle(fontSize: 24))
                    : Icon(
                        Icons.list_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              title: Text(
                plantilla.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${plantilla.cantidadAtributos} atributos${plantilla.cantidadRequeridos > 0 ? " • ${plantilla.cantidadRequeridos} requeridos" : ""}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pop();
                _showPlantillaAtributosForm(parentContext, plantilla);
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showPlantillaAtributosForm(BuildContext context, plantilla.AtributoPlantilla plantillaSeleccionada) {
    final Map<String, String> valores = {};
    // Capturar el cubit ANTES de abrir el dialog
    final cubit = context.read<VarianteAtributoCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Completar Atributos',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plantilla: ${plantillaSeleccionada.nombre}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Completa los valores para cada atributo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...plantillaSeleccionada.atributos.map((plantillaAtributo) {
                        final productoAtributo = _convertirAtributoInfoAProductoAtributo(
                          plantillaAtributo.atributo,
                          plantillaAtributo.valoresActuales,
                          plantillaAtributo.orden,
                          plantillaAtributo.esRequerido,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: AtributoInputWidget(
                            atributo: productoAtributo,
                            valorActual: valores[plantillaAtributo.atributoId],
                            onChanged: (valor) {
                              setState(() {
                                valores[plantillaAtributo.atributoId] = valor;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Validar campos requeridos
                            final atributosRequeridos = plantillaSeleccionada.atributos
                                .where((pa) => pa.esRequerido)
                                .toList();

                            for (var plantillaAtributo in atributosRequeridos) {
                              final valor = valores[plantillaAtributo.atributoId];
                              if (valor == null || valor.isEmpty) {
                                ScaffoldMessenger.of(builderContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'El atributo "${plantillaAtributo.atributo.nombre}" es requerido',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                            }

                            // Convertir a formato para el cubit
                            final atributosFormato = plantillaSeleccionada.atributos.map((pa) {
                              return {
                                'atributoId': pa.atributoId,
                                'valor': valores[pa.atributoId] ?? '',
                                'atributo': {
                                  'id': pa.atributo.id,
                                  'nombre': pa.atributo.nombre,
                                  'clave': pa.atributo.clave,
                                  'tipo': pa.atributo.tipo,
                                  'unidad': pa.atributo.unidad,
                                },
                              };
                            }).toList();

                            // Aplicar al cubit (usando el cubit capturado antes del dialog)
                            cubit.initializeFromPlantilla(atributosFormato);

                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(builderContext).showSnackBar(
                              const SnackBar(
                                content: Text('Atributos aplicados desde plantilla'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ProductoAtributo _convertirAtributoInfoAProductoAtributo(
    plantilla.PlantillaAtributoInfo atributoInfo,
    List<String> valores,
    int orden,
    bool requerido,
  ) {
    return ProductoAtributo(
      id: atributoInfo.id,
      empresaId: empresaId ?? '',
      categoriaId: null,
      nombre: atributoInfo.nombre,
      clave: atributoInfo.clave,
      tipo: atributoInfo.tipoEnum,
      requerido: requerido,
      descripcion: atributoInfo.descripcion,
      unidad: atributoInfo.unidad,
      valores: valores,
      orden: orden,
      mostrarEnListado: true,
      usarParaFiltros: true,
      mostrarEnMarketplace: true,
      isActive: true,
      creadoEn: DateTime.now(),
      actualizadoEn: DateTime.now(),
    );
  }
}
