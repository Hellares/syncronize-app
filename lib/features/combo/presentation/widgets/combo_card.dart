import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/combo.dart';

/// Card para mostrar un combo con el lenguaje visual del app:
/// GradientContainer + shadow neumorphic + chips compactos +
/// icono leading con fondo coloreado.
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
    final stockOk = combo.stockDisponible > 0 && combo.tieneStockSuficiente;
    final stockColor = stockOk
        ? Colors.green.shade700
        : (combo.stockDisponible > 0
            ? Colors.orange.shade700
            : Colors.red.shade700);

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
                    _buildLeadingIcon(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            combo.nombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (combo.descripcion != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              combo.descripcion!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          _buildPriceRow(),
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
                    _buildChip(
                      label: 'Stock ${combo.stockDisponible}',
                      color: stockColor,
                      icon: Icons.inventory_2_outlined,
                    ),
                    _buildChip(
                      label: '${combo.componentes.length} items',
                      color: AppColors.blue1,
                      icon: Icons.view_list_outlined,
                    ),
                    _buildChip(
                      label: _getTipoPrecioLabel(combo.tipoPrecioCombo),
                      color: Colors.indigo.shade700,
                      icon: Icons.sell_outlined,
                    ),
                    if (combo.descuentoPorcentaje != null &&
                        combo.descuentoPorcentaje! > 0)
                      _buildChip(
                        label: '-${combo.descuentoPorcentaje!.toStringAsFixed(0)}%',
                        color: Colors.orange.shade700,
                        icon: Icons.discount_outlined,
                      ),
                    if (combo.ofertaActiva == true)
                      _buildChip(
                        label: 'EN OFERTA',
                        color: Colors.green.shade700,
                        icon: Icons.local_fire_department_outlined,
                      ),
                    if (combo.tieneProblemasStock)
                      _buildChip(
                        label: 'Sin stock parcial',
                        color: Colors.red.shade700,
                        icon: Icons.warning_amber_outlined,
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

  Widget _buildLeadingIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.3),
          width: 0.6,
        ),
      ),
      child: Icon(Icons.inventory_2_outlined,
          color: AppColors.blue1, size: 18),
    );
  }

  Widget _buildPriceRow() {
    final hasOferta =
        combo.ofertaActiva == true && combo.precioOferta != null;

    if (hasOferta) {
      final precioRegular = combo.precioSinOferta ?? combo.precioCalculado;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'S/ ${precioRegular.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'S/ ${combo.precioOferta!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
        ],
      );
    }

    return Text(
      'S/ ${combo.precioFinal.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.blue1,
      ),
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

  Widget _buildPopupMenu() {
    final hasActions = onEdit != null || onManageComponents != null;
    if (!hasActions) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade600),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      onSelected: (value) {
        if (value == 'componentes') onManageComponents?.call();
        if (value == 'editar') onEdit?.call();
      },
      itemBuilder: (context) => [
        if (onManageComponents != null)
          PopupMenuItem(
            value: 'componentes',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.view_list_outlined,
                    color: AppColors.blue1, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Componentes',
                  style: TextStyle(fontSize: 12, color: AppColors.blue1),
                ),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem(
            value: 'editar',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    color: Colors.grey.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Editar',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
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
        return 'C/ Descuento';
    }
  }
}
