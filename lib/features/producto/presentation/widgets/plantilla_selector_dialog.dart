import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';

/// Dialog para seleccionar y aplicar una plantilla de atributos predefinida
class PlantillaSelectorDialog extends StatefulWidget {
  final String empresaId;
  final String? categoriaId;
  final VoidCallback? onPlantillaAplicada;

  const PlantillaSelectorDialog({
    super.key,
    required this.empresaId,
    this.categoriaId,
    this.onPlantillaAplicada,
  });

  @override
  State<PlantillaSelectorDialog> createState() =>
      _PlantillaSelectorDialogState();
}

class _PlantillaSelectorDialogState extends State<PlantillaSelectorDialog> {
  String? _plantillaSeleccionada;
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.categoriaId;
    // Cargar plantillas disponibles
    context.read<AtributoPlantillaCubit>().loadPlantillas();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AtributoPlantillaCubit, AtributoPlantillaState>(
      listener: (context, state) {
        if (state is AtributoPlantillaAplicada) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPlantillaAplicada?.call();
          Navigator.of(context).pop();
        } else if (state is AtributoPlantillaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.dashboard_customize, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plantillas de Atributos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Selecciona una plantilla para aplicar atributos predefinidos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
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
                const SizedBox(height: 24),

                // Selector de categoría
                _buildCategoriaSelector(),
                const SizedBox(height: 16),

                // Content
                if (state is AtributoPlantillaLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is AtributoPlantillaAplicando)
                  _buildProgresoAplicacion(state)
                else if (state is AtributoPlantillaLoaded)
                  Flexible(
                    child: _buildPlantillasList(state),
                  ),

                const SizedBox(height: 24),

                // Actions
                if (state is! AtributoPlantillaAplicando)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _plantillaSeleccionada != null
                            ? _aplicarPlantilla
                            : null,
                        child: const Text('Aplicar Plantilla'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlantillasList(AtributoPlantillaLoaded state) {
    final plantillas = state.plantillas;

    if (plantillas.isEmpty) {
      return const Center(
        child: Text('No hay plantillas disponibles'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: plantillas.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final plantilla = plantillas[index];
        return _buildPlantillaCard(
          plantilla: plantilla,
          isSelected: _plantillaSeleccionada == plantilla.id,
          onTap: () {
            setState(() {
              _plantillaSeleccionada = plantilla.id;
            });
          },
        );
      },
    );
  }

  Widget _buildPlantillaCard({
    required AtributoPlantilla plantilla,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Iconos por tipo de plantilla
    final iconos = {
      'Motherboard': Icons.developer_board,
      'Procesador': Icons.memory,
      'Memoria RAM': Icons.storage,
      'Tarjeta Gráfica': Icons.videogame_asset,
    };

    final icon = iconos[plantilla.nombre] ?? Icons.inventory_2;

    // Estadísticas de la plantilla
    final requeridos = plantilla.atributos.where((a) => a.esRequerido).length;
    final opcionales = plantilla.atributos.length - requeridos;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plantilla.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plantilla.atributos.length} atributos ($requeridos requeridos, $opcionales opcionales)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: plantilla.atributos
                        .take(5)
                        .map((a) => Chip(
                              label: Text(
                                a.atributo.nombre,
                                style: const TextStyle(fontSize: 11),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  if (plantilla.atributos.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${plantilla.atributos.length - 5} más',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgresoAplicacion(AtributoPlantillaAplicando state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Aplicando plantilla "${state.plantillaNombre}"...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const LinearProgressIndicator(
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        const Text(
          'Creando atributos...',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _aplicarPlantilla() async {
    if (_plantillaSeleccionada == null) return;

    // Obtener la plantilla seleccionada
    final cubit = context.read<AtributoPlantillaCubit>();
    final state = cubit.state;
    AtributoPlantilla? plantilla;
    if (state is AtributoPlantillaLoaded) {
      for (var p in state.plantillas) {
        if (p.id == _plantillaSeleccionada) {
          plantilla = p;
          break;
        }
      }
    }
    if (plantilla == null) return;

    // Aplicar plantilla usando el método existente del cubit
    cubit.aplicarPlantilla(
      plantillaId: plantilla.id,
      plantillaNombre: plantilla.nombre,
      productoId: null,
      varianteId: null,
    );
  }

  Widget _buildCategoriaSelector() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        if (state is CategoriasEmpresaLoaded) {
          final categorias = state.categorias;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Categoría de destino',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona la categoría donde se aplicarán los atributos de la plantilla',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria.id,
                      child: Text(categoria.nombreDisplay),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSeleccionada = value;
                    });
                  },
                  hint: const Text('Selecciona una categoría'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
