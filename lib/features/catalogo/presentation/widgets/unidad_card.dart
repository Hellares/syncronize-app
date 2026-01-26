import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/chip_simple.dart';
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

    return GradientContainer(
      borderColor: AppColors.blueborder,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildIcon(),
        title: Text(
          unidad.displayConCodigo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unidad.descripcion != null) Text(unidad.descripcion!),
            const SizedBox(height: 8),
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
        : AppColors.blue1; // Maestra

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

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildChip(String label, Color color) {
    return ChipSimple(label: label, color: color, fontSize: 10,borderRadius: 4,);
  }
}
