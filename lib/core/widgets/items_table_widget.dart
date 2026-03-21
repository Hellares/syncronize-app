import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Item genérico para la tabla de productos/items
class ItemTableRow {
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;

  const ItemTableRow({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });
}

/// Widget reutilizable tipo tabla/grilla para mostrar lista de items (productos, servicios, etc.)
///
/// Uso:
/// ```dart
/// ItemsTableWidget(
///   items: myItems.map((i) => ItemTableRow(
///     descripcion: i.descripcion,
///     cantidad: i.cantidad,
///     precioUnitario: i.precioUnitario,
///     subtotal: i.subtotal,
///   )).toList(),
///   onRemove: (index) => setState(() => myItems.removeAt(index)),
/// )
/// ```
class ItemsTableWidget extends StatelessWidget {
  final List<ItemTableRow> items;
  final void Function(int index)? onRemove;
  final bool showFooter;

  const ItemsTableWidget({
    super.key,
    required this.items,
    this.onRemove,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final showRemove = onRemove != null;
    final subtotal = items.fold(0.0, (sum, i) => sum + i.subtotal);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.blue1.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600]))),
                SizedBox(width: 35, child: Text('Cant.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600]))),
                SizedBox(width: 60, child: Text('P. Unit.', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600]))),
                SizedBox(width: 65, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600]))),
                if (showRemove) const SizedBox(width: 28),
              ],
            ),
          ),
          // Rows
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isEven = i % 2 == 0;
            return Container(
              color: isEven ? Colors.white : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.descripcion,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 35,
                    child: Text(
                      item.cantidad % 1 == 0 ? item.cantidad.toInt().toString() : item.cantidad.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  SizedBox(width: 60, child: Text(item.precioUnitario.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                  SizedBox(width: 65, child: Text(item.subtotal.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  if (showRemove)
                    SizedBox(
                      width: 28,
                      child: GestureDetector(
                        onTap: () => onRemove!(i),
                        child: Icon(Icons.close, size: 15, color: Colors.red[300]),
                      ),
                    ),
                ],
              ),
            );
          }),
          // Footer
          if (showFooter)
            Container(
              color: AppColors.blue1.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text('${items.length} item${items.length != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600]))),
                  const SizedBox(width: 35),
                  const SizedBox(width: 60),
                  SizedBox(width: 65, child: Text(subtotal.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1))),
                  if (showRemove) const SizedBox(width: 28),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
