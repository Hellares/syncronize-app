import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';

/// Tarjeta de plantilla de atributos con el lenguaje visual del app:
/// GradientContainer + shadow neumorphic + icono leading + chips compactos.
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
    final accentColor = plantilla.esPredefinida
        ? AppColors.blue1
        : Colors.deepPurple.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        shadowStyle: ShadowStyle.neumorphic,
        borderColor: AppColors.blueborder,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeadingIcon(accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plantilla.nombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (plantilla.descripcion != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              plantilla.descripcion!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildPopupMenu(),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (plantilla.esPredefinida)
                      _buildChip(
                        label: 'Sistema',
                        color: AppColors.blue1,
                        icon: Icons.shield_outlined,
                      )
                    else
                      _buildChip(
                        label: 'Personalizada',
                        color: Colors.deepPurple,
                        icon: Icons.star_outline,
                      ),
                    if (plantilla.nombreCategoria != null)
                      _buildChip(
                        label: plantilla.nombreCategoria!,
                        color: Colors.green.shade700,
                        icon: Icons.category_outlined,
                      ),
                    _buildChip(
                      label: '${plantilla.cantidadAtributos} atributos',
                      color: Colors.indigo.shade700,
                      icon: Icons.list_alt_outlined,
                    ),
                    if (plantilla.cantidadRequeridos > 0)
                      _buildChip(
                        label: '${plantilla.cantidadRequeridos} req.',
                        color: Colors.orange.shade700,
                        icon: Icons.priority_high,
                      ),
                  ],
                ),
                if (plantilla.hasAtributos) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: plantilla.resumenTipos.entries.map((entry) {
                      return _buildTipoChip(entry.key, entry.value);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(Color accentColor) {
    final icono = plantilla.icono;
    final esEmoji = icono != null && icono.isNotEmpty;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 0.6,
        ),
      ),
      alignment: Alignment.center,
      child: esEmoji
          ? Text(icono, style: const TextStyle(fontSize: 18))
          : Icon(Icons.dashboard_customize_outlined,
              color: accentColor, size: 18),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoChip(AtributoTipo tipo, int cantidad) {
    final color = Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.grey.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForTipo(tipo), size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '$cantidad',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    final hasActions = onEdit != null || onDelete != null;
    if (!hasActions) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade600),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    color: Colors.grey.shade700, size: 16),
                const SizedBox(width: 8),
                Text('Editar',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.delete_outline,
                    color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Text('Eliminar',
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade700)),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getIconForTipo(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.texto:
        return Icons.text_fields;
      case AtributoTipo.numero:
        return Icons.numbers;
      case AtributoTipo.select:
        return Icons.arrow_drop_down_circle_outlined;
      case AtributoTipo.boolean:
        return Icons.toggle_on_outlined;
      case AtributoTipo.color:
        return Icons.palette_outlined;
      case AtributoTipo.talla:
        return Icons.straighten;
      case AtributoTipo.material:
        return Icons.layers_outlined;
      case AtributoTipo.capacidad:
        return Icons.inventory_2_outlined;
      case AtributoTipo.multiSelect:
        return Icons.checklist;
    }
  }
}
