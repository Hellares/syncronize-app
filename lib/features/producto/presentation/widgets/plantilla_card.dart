import 'package:flutter/material.dart';
import '../../domain/entities/atributo_plantilla.dart';

/// Tarjeta para mostrar una plantilla de atributos
class PlantillaCard extends StatelessWidget {
  final AtributoPlantilla plantilla;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlantillaCard({
    super.key,
    required this.plantilla,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  // Icono
                  if (plantilla.icono != null) ...[
                    Text(
                      plantilla.icono!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Nombre y badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plantilla.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (plantilla.esPredefinida)
                              Chip(
                                label: const Text('Sistema', style: TextStyle(fontSize: 11)),
                                backgroundColor: Colors.blue.shade100,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (plantilla.nombreCategoria != null)
                              Chip(
                                label: Text(
                                  plantilla.nombreCategoria!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.green.shade100,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Acciones
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              // Descripción
              if (plantilla.descripcion != null) ...[
                const SizedBox(height: 8),
                Text(
                  plantilla.descripcion!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Estadísticas
              Row(
                children: [
                  _buildStat(
                    icon: Icons.list,
                    label: '${plantilla.cantidadAtributos} atributos',
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    icon: Icons.check_circle,
                    label: '${plantilla.cantidadRequeridos} requeridos',
                    color: Colors.orange,
                  ),
                ],
              ),

              // Preview de tipos de atributos
              if (plantilla.hasAtributos) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: plantilla.resumenTipos.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForTipo(entry.key),
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color ?? Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  IconData _getIconForTipo(dynamic tipo) {
    final tipoStr = tipo.toString().split('.').last;
    switch (tipoStr) {
      case 'texto':
        return Icons.text_fields;
      case 'numero':
        return Icons.numbers;
      case 'select':
        return Icons.arrow_drop_down_circle;
      case 'boolean':
        return Icons.toggle_on;
      case 'fecha':
        return Icons.calendar_today;
      case 'color':
        return Icons.palette;
      default:
        return Icons.help_outline;
    }
  }
}
