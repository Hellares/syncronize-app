import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/popup_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/politica_descuento.dart';

class PoliticaCard extends StatelessWidget {
  final PoliticaDescuento politica;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAssignUsers;
  final VoidCallback? onAssignClients;
  final VoidCallback? onAssignProducts;
  final VoidCallback? onViewHistory;

  const PoliticaCard({
    super.key,
    required this.politica,
    this.onEdit,
    this.onDelete,
    this.onAssignUsers,
    this.onAssignClients,
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
                      child: AppSubtitle(politica.nombre, fontSize: 10),
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
                            fontSize: 8,
                            color: AppColors.blueGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InfoChip(
                      icon: Icons.category,
                      iconSize: 12,
                      text: _getTipoDescuentoLabel(politica.tipoDescuento),
                      textColor: _getTipoDescuentoColor(politica.tipoDescuento),
                      fontSize: 8,
                      borderRadius: 6,
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      icon: Icons.discount,
                      iconSize: 12,
                      text: _getDescuentoValue(),
                      textColor: AppColors.blue1,
                      fontSize: 8,
                      borderRadius: 6,
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
                const SizedBox(height: 6),
                _buildAlcanceRow(),
                const SizedBox(height: 6),
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
        // Sin requireConfirm: la confirmación la maneja onDelete con
        // StyledDialog (el confirm interno del menú tiene los botones
        // comentados → diálogo sin acciones).
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
        if (onAssignUsers != null && onAssignClients != null)
          const SizedBox(width: 8),
        if (onAssignClients != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.workspace_premium_outlined,
              label: 'Clientes',
              onTap: onAssignClients!,
              color: Colors.amber.shade800,
            ),
          ),
        if ((onAssignUsers != null || onAssignClients != null) &&
            onAssignProducts != null)
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
            Icon(icon, size: 14, color: color),
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

  /// Indicador de alcance de productos: "Aplica a todos los productos" si
  /// aplicarATodos, o "Productos seleccionados (N)" según lo asignado.
  Widget _buildAlcanceRow() {
    final esTodos = politica.aplicarATodos;
    final p = politica.productoIdsAplicables.length;
    final c = politica.categoriaIdsAplicables.length;
    final color = esTodos ? Colors.green.shade700 : AppColors.blue1;

    String texto;
    if (esTodos) {
      texto = 'Aplica a todos los productos';
    } else if (p == 0 && c == 0) {
      texto = 'Sin productos seleccionados';
    } else {
      final partes = <String>[];
      if (p > 0) partes.add('$p producto${p == 1 ? '' : 's'}');
      if (c > 0) partes.add('$c categoría${c == 1 ? '' : 's'}');
      texto = 'Productos seleccionados (${partes.join(' · ')})';
    }

    return Row(
      children: [
        Icon(
          esTodos ? Icons.select_all : Icons.inventory_2_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: AppSubtitle(texto, fontSize: 9, color: color, font: AppFont.amazonEmberMediumItalic),
        ),
      ],
    );
  }

  String _getDescuentoValue() {
    switch (politica.tipoCalculo) {
      case TipoCalculoDescuento.porcentaje:
        return '${politica.valorDescuento.toStringAsFixed(0)}%';
      case TipoCalculoDescuento.montoFijo:
        return 'S/. ${politica.valorDescuento.toStringAsFixed(2)}';
      case TipoCalculoDescuento.precioCosto:
        final m = politica.markupSobreCosto ?? 0;
        return m > 0 ? 'Costo +${m.toStringAsFixed(0)}%' : 'Precio costo';
      case TipoCalculoDescuento.precioMayorDesdeUnidad:
        return 'Mayor x1';
    }
  }

  String _getDateRange() {
    if (politica.fechaInicio != null && politica.fechaFin != null) {
      return '${DateFormatter.formatDate(politica.fechaInicio!)} - ${DateFormatter.formatDate(politica.fechaFin!)}';
    } else if (politica.fechaInicio != null) {
      return 'Desde ${DateFormatter.formatDate(politica.fechaInicio!)}';
    } else if (politica.fechaFin != null) {
      return 'Hasta ${DateFormatter.formatDate(politica.fechaFin!)}';
    }
    return '';
  }
}
