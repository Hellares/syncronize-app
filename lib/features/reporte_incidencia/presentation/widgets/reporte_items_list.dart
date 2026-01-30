import 'package:flutter/material.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';

class ReporteItemsList extends StatelessWidget {
  final List<ReporteIncidenciaItem> items;
  final EstadoReporteIncidencia reporteEstado;
  final Function(String)? onDeleteItem;
  final Function(String)? onResolveItem;

  const ReporteItemsList({
    super.key,
    required this.items,
    required this.reporteEstado,
    this.onDeleteItem,
    this.onResolveItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(context, item);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ReporteIncidenciaItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        item.nombreProducto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.codigoProducto != null)
                        Text(
                          'SKU: ${item.codigoProducto}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildTipoBadge(item.tipo),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  Icons.inventory,
                  'Cantidad: ${item.cantidadAfectada}',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                if (item.accionTomada != null)
                  _buildAccionChip(item.accionTomada!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Descripción:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              item.descripcion,
              style: const TextStyle(fontSize: 12),
            ),
            if (item.observaciones != null) ...[
              const SizedBox(height: 4),
              Text(
                'Observaciones:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                item.observaciones!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (item.sedeDestinoNombre != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Enviado a: ${item.sedeDestinoNombre}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ],
            if (reporteEstado == EstadoReporteIncidencia.borrador ||
                (reporteEstado == EstadoReporteIncidencia.aprobado &&
                    item.accionTomada == null)) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (reporteEstado == EstadoReporteIncidencia.borrador &&
                      onDeleteItem != null)
                    TextButton.icon(
                      onPressed: () => onDeleteItem!(item.id),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  if (reporteEstado == EstadoReporteIncidencia.aprobado &&
                      item.accionTomada == null &&
                      onResolveItem != null)
                    TextButton.icon(
                      onPressed: () => onResolveItem!(item.id),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Resolver'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipoBadge(TipoIncidenciaProducto tipo) {
    Color color;
    IconData icon;
    String label;

    switch (tipo) {
      case TipoIncidenciaProducto.danado:
        color = Colors.red;
        icon = Icons.broken_image;
        label = 'Dañado';
        break;
      case TipoIncidenciaProducto.perdido:
        color = Colors.orange;
        icon = Icons.search_off;
        label = 'Perdido';
        break;
      case TipoIncidenciaProducto.robo:
        color = Colors.purple;
        icon = Icons.warning;
        label = 'Robo';
        break;
      case TipoIncidenciaProducto.caducado:
        color = Colors.brown;
        icon = Icons.event_busy;
        label = 'Caducado';
        break;
      case TipoIncidenciaProducto.defectoFabrica:
        color = Colors.indigo;
        icon = Icons.build;
        label = 'Defecto';
        break;
      case TipoIncidenciaProducto.malAlmacenamiento:
        color = Colors.teal;
        icon = Icons.storage;
        label = 'Mal Almacenamiento';
        break;
      case TipoIncidenciaProducto.accidente:
        color = Colors.pink;
        icon = Icons.local_hospital;
        label = 'Accidente';
        break;
      case TipoIncidenciaProducto.diferenciaInventario:
        color = Colors.cyan;
        icon = Icons.difference;
        label = 'Diferencia';
        break;
      case TipoIncidenciaProducto.otro:
        color = Colors.grey;
        icon = Icons.more_horiz;
        label = 'Otro';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionChip(AccionIncidenciaProducto accion) {
    Color color = Colors.green;
    IconData icon = Icons.check_circle;
    String label;

    switch (accion) {
      case AccionIncidenciaProducto.marcarDanado:
        label = 'Marcado como Dañado';
        break;
      case AccionIncidenciaProducto.darDeBaja:
        label = 'Dado de Baja';
        color = Colors.red;
        icon = Icons.delete_forever;
        break;
      case AccionIncidenciaProducto.reparacionInterna:
        label = 'En Reparación';
        color = Colors.blue;
        icon = Icons.build;
        break;
      case AccionIncidenciaProducto.devolverSedePrincipal:
        label = 'Devuelto a Sede Principal';
        color = Colors.orange;
        icon = Icons.keyboard_return;
        break;
      case AccionIncidenciaProducto.enviarGarantia:
        label = 'Enviado a Garantía';
        color = Colors.purple;
        icon = Icons.verified_user;
        break;
      case AccionIncidenciaProducto.aceptarPerdida:
        label = 'Pérdida Aceptada';
        color = Colors.grey;
        icon = Icons.check;
        break;
      case AccionIncidenciaProducto.reportarRobo:
        label = 'Robo Reportado';
        color = Colors.deepOrange;
        icon = Icons.report;
        break;
      case AccionIncidenciaProducto.ajustarSistema:
        label = 'Sistema Ajustado';
        color = Colors.teal;
        icon = Icons.settings;
        break;
      case AccionIncidenciaProducto.pendienteDecision:
        label = 'Pendiente';
        color = Colors.amber;
        icon = Icons.pending;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }
}
