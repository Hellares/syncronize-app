import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/movimiento_stock.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/usecases/get_historial_movimientos_usecase.dart';

/// Bottom sheet para mostrar el historial de movimientos de un stock
class HistorialMovimientosBottomSheet extends StatelessWidget {
  final ProductoStock stock;

  const HistorialMovimientosBottomSheet({
    super.key,
    required this.stock,
  });

  static void show(BuildContext context, ProductoStock stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistorialMovimientosBottomSheet(stock: stock),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const AppSubtitle('Historial de Movimientos'),
                const SizedBox(height: 4),
                Text(
                  stock.nombreProducto,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (stock.sede != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.store,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        stock.sede!.nombre,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Lista de movimientos
          Expanded(
            child: FutureBuilder<Resource<List<MovimientoStock>>>(
              future: locator<GetHistorialMovimientosUseCase>()(
                stockId: stock.id,
                limit: 100,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final result = snapshot.data!;

                if (result is Error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            (result as Error).message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final movimientos = (result as Success).data;

                if (movimientos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay movimientos registrados',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: movimientos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movimiento = movimientos[index];
                    return _MovimientoTile(movimiento: movimiento);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  final MovimientoStock movimiento;

  const _MovimientoTile({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final isEntrada = movimiento.esEntrada;
    final color = isEntrada ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.tipo.descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (movimiento.motivo != null)
                  Text(
                    movimiento.motivo!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormatter.formatDateTime(movimiento.creadoEn),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (movimiento.numeroDocumento != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${movimiento.numeroDocumento}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${movimiento.cantidadAnterior} → ${movimiento.cantidadNueva}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Cantidad
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${movimiento.cantidad > 0 ? '+' : ''}${movimiento.cantidad}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              Text(
                'unidades',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
