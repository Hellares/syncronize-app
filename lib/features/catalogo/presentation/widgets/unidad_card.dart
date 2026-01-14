import 'package:flutter/material.dart';
import '../../domain/entities/unidad_medida.dart';

/// Card para mostrar una unidad de medida activa de la empresa
class UnidadCard extends StatelessWidget {
  final EmpresaUnidadMedida unidad;
  final VoidCallback onDesactivar;

  const UnidadCard({
    super.key,
    required this.unidad,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final isPersonalizada = unidad.esPersonalizada;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: _buildIcon(),
        title: Text(
          unidad.displayConCodigo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unidad.descripcion != null) Text(unidad.descripcion!),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (isPersonalizada)
                  _buildChip('Personalizada', Colors.purple),
                if (unidad.categoria != null)
                  _buildChip(unidad.categoria!.label, Colors.blue),
                if (unidad.orden != null)
                  _buildChip('Orden: ${unidad.orden}', Colors.green),
                if (!unidad.isVisible)
                  _buildChip('Oculta', Colors.grey),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'desactivar') {
              onDesactivar();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'desactivar',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Desactivar'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildIcon() {
    final color = unidad.esPersonalizada
        ? Colors.purple // Personalizada
        : Colors.blue; // Maestra

    IconData icon = Icons.straighten;
    if (unidad.categoria != null) {
      switch (unidad.categoria!) {
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
