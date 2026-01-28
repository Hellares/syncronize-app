import 'package:flutter/material.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';

class ReporteHeaderCard extends StatelessWidget {
  final ReporteIncidencia reporte;

  const ReporteHeaderCard({
    super.key,
    required this.reporte,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reporte.titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${reporte.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEstadoBadge(reporte.estado),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem(
                  Icons.inventory_2,
                  'Productos',
                  reporte.totalProductosAfectados.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.numbers,
                  'Cantidad Total',
                  reporte.totalCantidadAfectada.toString(),
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.warning,
                  'Dañados',
                  reporte.totalDanados.toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Creado: ${_formatDate(reporte.creadoEn)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Actualizado: ${_formatDate(reporte.actualizadoEn)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoReporteIncidencia estado) {
    Color color;
    IconData icon;
    String label;

    switch (estado) {
      case EstadoReporteIncidencia.borrador:
        color = Colors.grey;
        icon = Icons.edit;
        label = 'Borrador';
        break;
      case EstadoReporteIncidencia.enviado:
        color = Colors.blue;
        icon = Icons.send;
        label = 'Enviado';
        break;
      case EstadoReporteIncidencia.enRevision:
        color = Colors.orange;
        icon = Icons.rate_review;
        label = 'En Revisión';
        break;
      case EstadoReporteIncidencia.aprobado:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Aprobado';
        break;
      case EstadoReporteIncidencia.enProceso:
        color = Colors.purple;
        icon = Icons.autorenew;
        label = 'En Proceso';
        break;
      case EstadoReporteIncidencia.resuelto:
        color = Colors.teal;
        icon = Icons.done_all;
        label = 'Resuelto';
        break;
      case EstadoReporteIncidencia.rechazado:
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Rechazado';
        break;
      case EstadoReporteIncidencia.cancelado:
        color = Colors.brown;
        icon = Icons.block;
        label = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
