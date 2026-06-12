import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
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
                          if (atributoValores.isNotEmpty)
                            IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _showAddAtributoDialog(context),
                              icon: const Icon(Icons.add,
                                  size: 18, color: AppColors.blue1),
                            ),
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

                              if (atributosDisponibles.isNotEmpty)
                                CustomButton(
                                  width: 200,
                                  backgroundColor: AppColors.white,
                                  borderColor: AppColors.blue1,
                                  textColor: AppColors.blue1,
                                  iconColor: AppColors.blue1,
                                  text: 'Agregar Manualmente',
                                  onPressed: () => _showAddAtributoDialog(context),
                                  icon: const Icon(Icons.add,
                                      size: 16, color: AppColors.blue1),
                                ),
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

  /// Dialog para asignar un atributo individual a la variante, eligiendo de
  /// los `ProductoAtributo` configurados de la empresa. El valor se ingresa
  /// con `AtributoInputWidget` (dropdown de valores predefinidos para
  /// SELECT/COLOR/TALLA/etc.), evitando typos que romperían el agrupado del
  /// selector de variantes.
  void _showAddAtributoDialog(BuildContext context) {
    final cubit = context.read<VarianteAtributoCubit>();
    final currentState = cubit.state;
    if (currentState is! VarianteAtributoLoaded) return;

    // Filtrar atributos que ya están asignados a esta variante.
    final atributosYaAsignados =
        currentState.atributoValores.map((av) => av.atributoId).toSet();
    final disponiblesFiltrados = atributosDisponibles
        .where((a) => !atributosYaAsignados.contains(a.id))
        .toList();

    if (disponiblesFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los atributos disponibles ya fueron agregados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ProductoAtributo? selectedAtributo;
    String valor = '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final puedeAgregar =
              selectedAtributo != null && valor.trim().isNotEmpty;
          return StyledDialog(
            accentColor: AppColors.blue1,
            icon: Icons.label_outline,
            titulo: 'Agregar atributo',
            content: [
              CustomDropdown<ProductoAtributo>(
                value: selectedAtributo,
                label: 'Atributo',
                hintText: 'Seleccionar atributo',
                borderColor: AppColors.blue1,
                items: disponiblesFiltrados
                    .map((atributo) => DropdownItem(
                          value: atributo,
                          label: atributo.nombre,
                        ))
                    .toList(),
                onChanged: (value) => setStateDialog(() {
                  selectedAtributo = value;
                  valor = '';
                }),
              ),
              if (selectedAtributo != null) ...[
                const SizedBox(height: 16),
                AtributoInputWidget(
                  key: ValueKey(selectedAtributo!.id),
                  atributo: selectedAtributo!,
                  valorActual: valor,
                  onChanged: (v) => setStateDialog(() => valor = v),
                ),
              ],
            ],
            actions: [
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  backgroundColor: AppColors.white,
                  borderColor: Colors.grey.shade400,
                  textColor: Colors.grey.shade700,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Agregar',
                  backgroundColor: AppColors.blue1,
                  enabled: puedeAgregar,
                  icon: Icon(Icons.add,
                      size: 16,
                      color:
                          puedeAgregar ? Colors.white : Colors.grey.shade600),
                  onPressed: () {
                    cubit.addAtributo(
                      atributo: selectedAtributo!,
                      valor: valor.trim(),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAtributoDialog(BuildContext context, AtributoValor atributoValor) {
    final cubit = context.read<VarianteAtributoCubit>();
    // Buscar el ProductoAtributo para ofrecer el dropdown de valores
    // predefinidos (consistente con el dialog de agregar).
    ProductoAtributo? productoAtributo;
    for (final a in atributosDisponibles) {
      if (a.id == atributoValor.atributoId) {
        productoAtributo = a;
        break;
      }
    }
    final valorController = TextEditingController(text: atributoValor.valor);
    final valorFocusNode = FocusNode();
    String valor = atributoValor.valor;

    // Preservar el autofocus que tenía el TextField original.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (valorFocusNode.canRequestFocus) valorFocusNode.requestFocus();
    });

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return StyledDialog(
            accentColor: AppColors.blue1,
            icon: Icons.edit_outlined,
            titulo: 'Editar ${atributoValor.atributo.nombre}',
            content: [
              if (productoAtributo != null)
                AtributoInputWidget(
                  atributo: productoAtributo,
                  valorActual: valor,
                  onChanged: (v) => setStateDialog(() => valor = v),
                )
              else
                CustomText(
                  controller: valorController,
                  label: 'Valor',
                  focusNode: valorFocusNode,
                  onChanged: (v) => setStateDialog(() => valor = v),
                ),
            ],
            actions: [
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  backgroundColor: AppColors.white,
                  borderColor: Colors.grey.shade400,
                  textColor: Colors.grey.shade700,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Guardar',
                  backgroundColor: AppColors.blue1,
                  enabled: valor.trim().isNotEmpty,
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  onPressed: () {
                    cubit.updateAtributo(
                      atributoValorId: atributoValor.id,
                      nuevoValor: valor.trim(),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveAtributo(BuildContext context, AtributoValor atributoValor) {
    final cubit = context.read<VarianteAtributoCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => StyledDialog(
        accentColor: Colors.red.shade600,
        icon: Icons.delete_outline,
        titulo: 'Eliminar atributo',
        content: [
          Text(
            '¿Eliminar el atributo "${atributoValor.atributo.nombre}" de esta variante?',
            style: const TextStyle(fontSize: 13),
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              backgroundColor: AppColors.white,
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Eliminar',
              backgroundColor: Colors.red.shade600,
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: Colors.white),
              onPressed: () {
                cubit.removeAtributo(atributoValor.id);
                Navigator.of(dialogContext).pop();
              },
            ),
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
            return StyledDialog(
              accentColor: AppColors.blue1,
              icon: Icons.auto_awesome,
              titulo: 'Seleccionar plantilla',
              content: [
                Text(
                  'Elige una plantilla para pre-llenar los atributos',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.maxFinite,
                  height: 360,
                  child: _buildPlantillaContent(builderContext, state, context),
                ),
              ],
              actions: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    backgroundColor: AppColors.white,
                    borderColor: Colors.grey.shade400,
                    textColor: Colors.grey.shade700,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
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
        builder: (builderContext, setState) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.auto_awesome,
          titulo: 'Completar atributos',
          content: [
            Text(
              'Plantilla: ${plantillaSeleccionada.nombre}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.maxFinite,
              height: 320,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...plantillaSeleccionada.atributos.map((plantillaAtributo) {
                    final productoAtributo =
                        _convertirAtributoInfoAProductoAtributo(
                      plantillaAtributo.atributo,
                      plantillaAtributo.valoresActuales,
                      plantillaAtributo.orden,
                      plantillaAtributo.esRequerido,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
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
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                backgroundColor: AppColors.white,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Aplicar',
                backgroundColor: AppColors.blue1,
                iconColor: AppColors.white,
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                onPressed: () {
                  final campoFaltante = cubit.initializeFromPlantilla(
                    plantillaAtributos: plantillaSeleccionada.atributos,
                    valores: valores,
                  );

                  if (campoFaltante != null) {
                    ScaffoldMessenger.of(builderContext).showSnackBar(
                      SnackBar(
                        content:
                            Text('El atributo "$campoFaltante" es requerido'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(builderContext).showSnackBar(
                    const SnackBar(
                      content: Text('Atributos aplicados desde plantilla'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
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
    return ProductoAtributo.fromPlantillaInfo(
      atributoId: atributoInfo.id,
      nombre: atributoInfo.nombre,
      clave: atributoInfo.clave,
      tipo: atributoInfo.tipoEnum,
      requerido: requerido,
      descripcion: atributoInfo.descripcion,
      unidad: atributoInfo.unidad,
      valores: valores,
      orden: orden,
      empresaId: empresaId ?? '',
    );
  }
}
