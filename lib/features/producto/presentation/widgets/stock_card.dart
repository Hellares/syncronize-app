import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/producto_stock.dart';

/// Widget para mostrar una tarjeta de stock de producto
class StockCard extends StatelessWidget {
  final ProductoStock stock;
  final VoidCallback? onTap;
  final VoidCallback? onAjustar;
  final VoidCallback? onHistorial;

  const StockCard({
    super.key,
    required this.stock,
    this.onTap,
    this.onAjustar,
    this.onHistorial,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderRadius: BorderRadius.circular(8),
        shadowStyle: ShadowStyle.glow,
        borderColor: _getBorderColor(),
        borderWidth: 1.2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con nombre del producto
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stock.nombreProducto,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStockBadge(),
                  ],
                ),

                const SizedBox(height: 8),

                // FILA 1: Stock físico y disponible para venta (principales)
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.inventory_2,
                        label: 'Físico Total',
                        value: stock.stockActual.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.shopping_cart,
                        label: 'Disponible',
                        value: stock.stockDisponibleVenta.toString(),
                        color: _getStockColor(),
                      ),
                    ),
                  ],
                ),

                // FILA 2: Reservas y mermas (solo si hay incidencias)
                if (stock.tieneIncidencias) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (stock.tieneStockReservado)
                        _buildInfoChipCompact(
                          icon: Icons.sync_alt,
                          label: 'Transfer.',
                          value: stock.stockReservado.toString(),
                          color: Colors.orange,
                        ),
                      if (stock.tieneStockReservadoVenta)
                        _buildInfoChipCompact(
                          icon: Icons.bookmark,
                          label: 'Apartado',
                          value: stock.stockReservadoVenta.toString(),
                          color: Colors.purple,
                        ),
                      if (stock.tieneStockDanado)
                        _buildInfoChipCompact(
                          icon: Icons.broken_image,
                          label: 'Dañado',
                          value: stock.stockDanado.toString(),
                          color: Colors.red,
                        ),
                      if (stock.tieneStockEnGarantia)
                        _buildInfoChipCompact(
                          icon: Icons.build_circle,
                          label: 'Garantía',
                          value: stock.stockEnGarantia.toString(),
                          color: Colors.amber,
                        ),
                    ],
                  ),
                ],

                // FILA 3: Mínimo y Máximo (configuración)
                if (stock.stockMinimo != null || stock.stockMaximo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (stock.stockMinimo != null)
                        Expanded(
                          child: _buildInfoChip(
                            icon: Icons.warning_amber,
                            label: 'Mínimo',
                            value: stock.stockMinimo.toString(),
                            color: Colors.orange.shade700,
                          ),
                        ),
                      if (stock.stockMinimo != null && stock.stockMaximo != null)
                        const SizedBox(width: 8),
                      if (stock.stockMaximo != null)
                        Expanded(
                          child: _buildInfoChip(
                            icon: Icons.trending_up,
                            label: 'Máximo',
                            value: stock.stockMaximo.toString(),
                            color: Colors.blue.shade700,
                          ),
                        ),
                      if ((stock.stockMinimo == null) != (stock.stockMaximo == null))
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ],

                // Ubicación
                if (stock.ubicacion != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stock.ubicacion!,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],

                // Sede (si está disponible)
                if (stock.sede != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        stock.sede!.nombre,
                        // color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],

                // Botones de acción
                if (onAjustar != null || onHistorial != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onHistorial != null) ...[
                        TextButton.icon(
                          onPressed: onHistorial,
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Historial'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (onAjustar != null)
                        ElevatedButton.icon(
                          onPressed: onAjustar,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Ajustar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge() {
    if (stock.esCritico) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('SIN STOCK', ),
          ],
        ),
      );
    }

    if (stock.esBajoMinimo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('BAJO', ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text('OK', ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  /// Chip compacto para mostrar reservas y mermas (formato horizontal)
  Widget _buildInfoChipCompact({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (stock.esCritico) return Colors.red;
    if (stock.esBajoMinimo) return Colors.orange;
    return AppColors.blueborder;
  }

  Color _getStockColor() {
    if (stock.esCritico) return Colors.red;
    if (stock.esBajoMinimo) return Colors.orange;
    return Colors.green;
  }
}
