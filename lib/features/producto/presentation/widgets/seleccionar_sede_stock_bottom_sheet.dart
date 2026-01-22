import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../domain/entities/stock_por_sede_info.dart';

/// Bottom sheet para seleccionar una sede cuando hay múltiples con stock
class SeleccionarSedeStockBottomSheet extends StatelessWidget {
  final List<StockPorSedeInfo> stocksPorSede;
  final String productoNombre;
  final Function(StockPorSedeInfo) onSedeSelected;

  const SeleccionarSedeStockBottomSheet({
    super.key,
    required this.stocksPorSede,
    required this.productoNombre,
    required this.onSedeSelected,
  });

  static Future<StockPorSedeInfo?> show({
    required BuildContext context,
    required List<StockPorSedeInfo> stocksPorSede,
    required String productoNombre,
  }) {
    return showModalBottomSheet<StockPorSedeInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SeleccionarSedeStockBottomSheet(
        stocksPorSede: stocksPorSede,
        productoNombre: productoNombre,
        onSedeSelected: (sede) => Navigator.pop(context, sede),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bluechip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: AppColors.blue1,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSubtitle('SELECCIONE UNA SEDE', fontSize: 12),
                          const SizedBox(height: 4),
                          Text(
                            productoNombre,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Este producto tiene stock en ${stocksPorSede.length} sedes. Seleccione una para ajustar:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de sedes
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: stocksPorSede.length,
              itemBuilder: (context, index) {
                final stockSede = stocksPorSede[index];
                final isLowStock = stockSede.cantidad <= 10; // Simple threshold
                final isCritical = stockSede.cantidad == 0;

                Color statusColor;
                if (isCritical) {
                  statusColor = Colors.red;
                } else if (isLowStock) {
                  statusColor = Colors.orange;
                } else {
                  statusColor = Colors.green;
                }

                return GradientContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  shadowStyle: ShadowStyle.neumorphic,
                  borderColor: AppColors.blueborder,
                  child: InkWell(
                    onTap: () => onSedeSelected(stockSede),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        // Icono de sede
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bluechip,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: AppColors.blue1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info de la sede
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stockSede.sedeNombre,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Código: ${stockSede.sedeCodigo}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badge de stock
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCritical
                                    ? Icons.remove_circle_outline
                                    : isLowStock
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${stockSede.cantidad}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
