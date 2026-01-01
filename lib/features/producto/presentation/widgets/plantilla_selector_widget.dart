import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';

/// Widget selector de plantillas para aplicar a productos/variantes
class PlantillaSelectorWidget extends StatelessWidget {
  final String? productoId;
  final String? varianteId;
  final VoidCallback? onPlantillaAplicada;

  const PlantillaSelectorWidget({
    super.key,
    this.productoId,
    this.varianteId,
    this.onPlantillaAplicada,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AtributoPlantillaCubit>()..loadPlantillas(),
      child: BlocConsumer<AtributoPlantillaCubit, AtributoPlantillaState>(
        listener: (context, state) {
          if (state is AtributoPlantillaAplicada) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            onPlantillaAplicada?.call();
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
          if (state is AtributoPlantillaLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is AtributoPlantillaAplicando) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text('Aplicando plantilla "${state.plantillaNombre}"...'),
                  ],
                ),
              ),
            );
          }

          if (state is AtributoPlantillaLoaded) {
            if (state.plantillas.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'No hay plantillas disponibles',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crea plantillas para aplicarlas rápidamente',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aplicar Plantilla',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona una plantilla para agregar automáticamente sus atributos',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.plantillas.map((plantilla) {
                    return _PlantillaChip(
                      plantilla: plantilla,
                      onTap: () => _aplicarPlantilla(context, plantilla),
                    );
                  }).toList(),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _aplicarPlantilla(BuildContext context, AtributoPlantilla plantilla) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Aplicar la plantilla "${plantilla.nombre}"?'),
            const SizedBox(height: 12),
            Text(
              'Se crearán ${plantilla.cantidadAtributos} campos de atributos que podrás llenar después.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AtributoPlantillaCubit>().aplicarPlantilla(
                    plantillaId: plantilla.id,
                    plantillaNombre: plantilla.nombre,
                    productoId: productoId,
                    varianteId: varianteId,
                  );
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}

/// Chip para mostrar una plantilla
class _PlantillaChip extends StatelessWidget {
  final AtributoPlantilla plantilla;
  final VoidCallback onTap;

  const _PlantillaChip({
    required this.plantilla,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plantilla.icono != null) ...[
              Text(plantilla.icono!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
            ],
            Text(
              plantilla.nombre,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${plantilla.cantidadAtributos}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
