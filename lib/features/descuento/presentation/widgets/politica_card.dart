import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/popup_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/politica_descuento.dart';

class PoliticaCard extends StatelessWidget {
  final PoliticaDescuento politica;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAssignUsers;
  final VoidCallback? onAssignProducts;
  final VoidCallback? onViewHistory;

  const PoliticaCard({
    super.key,
    required this.politica,
    this.onEdit,
    this.onDelete,
    this.onAssignUsers,
    this.onAssignProducts,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.glow,
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 5,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 80,
                      ), // Espacio para chip y menú
                      child: AppSubtitle(politica.nombre, fontSize: 12),
                    ),
                    if (politica.descripcion != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 40,
                        ), // Espacio solo para menú
                        child: Text(
                          politica.descripcion!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.blueGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InfoChip(
                      icon: Icons.category,
                      text: _getTipoDescuentoLabel(politica.tipoDescuento),
                      textColor: _getTipoDescuentoColor(politica.tipoDescuento),
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      icon: Icons.discount,
                      text: _getDescuentoValue(),
                      textColor: AppColors.blue1,
                    ),
                  ],
                ),
                if (politica.fechaInicio != null ||
                    politica.fechaFin != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      AppSubtitle(
                        _getDateRange(),
                        fontSize: 10,
                        color: AppColors.blueGrey,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 8),
                _buildActionButtons(),
              ],
            ),
          ),
          Positioned(top: 8, right: 40, child: _buildStatusChip()),
          Positioned(top: 5, right: 0, child: _buildMenu()),
        ],
      ),
    );
  }

  Widget _buildMenu() {
  return CustomActionMenu(
    yNudge: 22,
    menuWidth: 100,
    borderRadius: 8,
    itemHeight: 30,
    items: [
      ActionMenuItem(
        type: ActionMenuType.edit,
        label: 'Editar',
        icon: Icons.edit_outlined,
        color: AppColors.blue1,
        // onTap: () => onEdit?.call(),
      ),
      ActionMenuItem(
        type: ActionMenuType.delete,
        label: 'Eliminar',
        icon: Icons.delete_outline,
        color: Colors.red,
        requireConfirm: true,
        confirmTitle: 'Eliminar',
        confirmMessage: '¿Seguro que deseas eliminar este registro?',
        confirmOkText: 'Eliminar',
        confirmCancelText: 'Cancelar',
        // onTap: () => onDelete?.call(),
      ),
    ],
    onSelected: (ActionMenuType value){
      if( value == ActionMenuType.edit && onEdit != null){
        onEdit!();
      }else if(value == ActionMenuType.delete && onDelete != null){
        onDelete!();
      }
    },
  );
}

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onAssignUsers != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.people_outline,
              label: 'Usuarios',
              onTap: onAssignUsers!,
              color: AppColors.blue1,
            ),
          ),
        if (onAssignUsers != null && onAssignProducts != null)
          const SizedBox(width: 8),
        if (onAssignProducts != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.inventory_2_outlined,
              label: 'Productos',
              onTap: onAssignProducts!,
              color: Colors.purple,
            ),
          ),
        if ((onAssignUsers != null || onAssignProducts != null) &&
            onViewHistory != null)
          const SizedBox(width: 8),
        if (onViewHistory != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.history,
              label: 'Historial',
              onTap: onViewHistory!,
              color: Colors.orange,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            // const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: politica.isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        politica.isActive ? 'Activa' : 'Inactiva',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: politica.isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  String _getTipoDescuentoLabel(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.trabajador:
        return 'Trabajador';
      case TipoDescuento.familiarTrabajador:
        return 'Familiar';
      case TipoDescuento.vip:
        return 'VIP';
      case TipoDescuento.promocional:
        return 'Promocional';
      case TipoDescuento.lealtad:
        return 'Lealtad';
      case TipoDescuento.cumpleanios:
        return 'Cumpleaños';
    }
  }

  Color _getTipoDescuentoColor(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.trabajador:
        return Colors.blue;
      case TipoDescuento.familiarTrabajador:
        return Colors.purple;
      case TipoDescuento.vip:
        return Colors.amber;
      case TipoDescuento.promocional:
        return Colors.green;
      case TipoDescuento.lealtad:
        return Colors.pink;
      case TipoDescuento.cumpleanios:
        return Colors.orange;
    }
  }

  String _getDescuentoValue() {
    if (politica.tipoCalculo == TipoCalculoDescuento.porcentaje) {
      return '${politica.valorDescuento.toStringAsFixed(0)}%';
    } else {
      return 'S/. ${politica.valorDescuento.toStringAsFixed(2)}';
    }
  }

  String _getDateRange() {
    if (politica.fechaInicio != null && politica.fechaFin != null) {
      return '${_formatDate(politica.fechaInicio!)} - ${_formatDate(politica.fechaFin!)}';
    } else if (politica.fechaInicio != null) {
      return 'Desde ${_formatDate(politica.fechaInicio!)}';
    } else if (politica.fechaFin != null) {
      return 'Hasta ${_formatDate(politica.fechaFin!)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
