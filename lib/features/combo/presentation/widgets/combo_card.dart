
import 'package:flutter/material.dart';
import '../../domain/entities/combo.dart';

class ComboCard extends StatelessWidget {
  final Combo combo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onManageComponents;

  const ComboCard({
    super.key,
    required this.combo,
    this.onTap,
    this.onEdit,
    this.onManageComponents,
  });

  @override
  Widget build(BuildContext context) {
    final stockColor = combo.stockDisponible > 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combo.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (combo.descripcion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            combo.descripcion!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    icon: Icons.attach_money,
                    label: '\$${combo.precioFinal.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  _buildInfoChip(
                    icon: Icons.inventory,
                    label: 'Stock: ${combo.stockDisponible}',
                    color: stockColor,
                  ),
                  _buildInfoChip(
                    icon: Icons.view_list,
                    label: '${combo.componentes.length} items',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(
                      _getTipoPrecioLabel(combo.tipoPrecioCombo),
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (combo.descuentoPorcentaje != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '-${combo.descuentoPorcentaje}%',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.orange.shade100,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
              if (onEdit != null || onManageComponents != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onManageComponents != null)
                      TextButton.icon(
                        onPressed: onManageComponents,
                        icon: const Icon(Icons.view_list, size: 18),
                        label: const Text('Componentes'),
                      ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getTipoPrecioLabel(TipoPrecioCombo tipo) {
    switch (tipo) {
      case TipoPrecioCombo.fijo:
        return 'Precio Fijo';
      case TipoPrecioCombo.calculado:
        return 'Calculado';
      case TipoPrecioCombo.calculadoConDescuento:
        return 'Con Descuento';
    }
  }
}
