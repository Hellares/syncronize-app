import 'package:flutter/material.dart';
import '../../domain/entities/unidad_medida.dart';

/// Card para mostrar una unidad de medida maestra disponible
class UnidadMaestraCard extends StatelessWidget {
  final UnidadMedidaMaestra maestra;
  final VoidCallback onActivar;
  final bool isActivada;

  const UnidadMaestraCard({
    super.key,
    required this.maestra,
    required this.onActivar,
    this.isActivada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActivada ? 0 : 2,
      color: isActivada ? Colors.grey.shade100 : null,
      child: ListTile(
        enabled: !isActivada,
        leading: _buildIcon(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                maestra.displayConCodigo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActivada ? Colors.grey : null,
                ),
              ),
            ),
            if (isActivada)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (maestra.descripcion != null)
              Text(
                maestra.descripcion!,
                style: TextStyle(
                  color: isActivada ? Colors.grey : null,
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(maestra.categoria.label, Colors.blue),
                if (maestra.esPopular)
                  _buildChip('Popular', Colors.amber),
              ],
            ),
          ],
        ),
        trailing: isActivada
            ? const Icon(Icons.check, color: Colors.green)
            : ElevatedButton.icon(
                onPressed: onActivar,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Activar'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
        isThreeLine: maestra.descripcion != null,
      ),
    );
  }

  Widget _buildIcon() {
    final color = isActivada ? Colors.grey : Colors.blue;

    IconData icon = Icons.straighten;
    switch (maestra.categoria) {
      case CategoriaUnidad.cantidad:
        icon = Icons.tag;
        break;
      case CategoriaUnidad.masa:
        icon = Icons.scale;
        break;
      case CategoriaUnidad.longitud:
        icon = Icons.straighten;
        break;
      case CategoriaUnidad.area:
        icon = Icons.crop_square;
        break;
      case CategoriaUnidad.volumen:
        icon = Icons.water_drop;
        break;
      case CategoriaUnidad.tiempo:
        icon = Icons.schedule;
        break;
      case CategoriaUnidad.servicio:
        icon = Icons.room_service;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
